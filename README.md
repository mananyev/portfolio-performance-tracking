# Stock Market Overview and Custom Portfolio Performance Tracking

> DataTalksClub data-engineering-zoomcamp capstone project.

Retail investors, in particular, informed traders, usually look up a lot of information on the Internet.
This information typically includes financial and economic news, published reports, and a number of indicators.
Gathering the required information might be time consuming and costly, and might not always be available at hand.
This project provides a short stock market overview with a number of indicators, and allows tracking the performance of the custom portfolio.[^1]
The data can further be used to train ML models to develop trading strategies and optimize portfolio selection.

[^1]: Portfolio performance is, for example, available at [Yahoo! Finace website](https://finance.yahoo.com/about/plans/select-plan/portfolioAnalytics) only for users with a paid subscription (starting from $7.95/month for a Bronze tier).


## Description

This project is used to create data infrastructure and a dashboard showing the outlook of the stock market and the performance of the selected portfolio.

Yahoo! Finance data from `yfinance` Python API is used.

### Branches

* `main` for GCP/GCS/BigQuery with orchestration in Kestra.
* `local/kestra` for local Postgres with orchestration in Kestra.

### Installation Guide

TBA


## Tools

For the local setup, the following tools have been used

1. Orchestration is done using [Kestra](https://kestra.io/).
2. Data is loaded via [Python](https://www.python.org/) scripts using popular libraries such as: `requests`, `beautifulsoup`, `pandas`. Financial data is retreived using `yfinance` library.
3. Data is stored in a local [PostgreSQL Relational Database](https://www.postgresql.org/).
4. Analytical transformations are managed with [`dbt Labs`](https://www.getdbt.com/).
5. Local dashboard was made using [Grafana](https://grafana.com/).


## Data Lineage

1.  Two input files (stored in the GitHub repository for this project):

    1. [`index_constituents_links.json`](./src/inputs/index_constituents_links.json) with links to Wikipedia pages that contain lists of stocks constituting the major indices of the selected regions/countries (like [this page for S\&P 500](http://en.wikipedia.org/wiki/List_of_S%26P_500_companies)).
    2.  [`portfolio.json`](./src/inputs/portfolio.json) with `tickers` keys and `positions` values:

        1. `tickers` are tickers that can be found in [Yahoo! Finance search](https://finance.yahoo.com/).
        2.  `positions` are dictionaries with following entries:

            1. `type`: `buy` or `sell`,
            2. `timestamp`: when transaction happened,
            3. `volume`: number of shares,`        "
            4. `volume_type`: currently only supports `shares` (not monetary amount).

2. Stock information (company name and suggested ticker) is extracted from the links to Wikipedia pages.
3. Corrected ticker information (ticker symbol, sector, industry, exchange) is searched through `yfinance` API.
4. Tickers' price (as well as volumes, dividends, and stock splits) histories for the stocks from the indices and from the portfolio are loaded (`backfill` option allows loading the whole history of prices).
5. Data is transformed using `dbt` and loaded to Postgres.
6. Market overview and portfolio performance are visualized in a Grafana dashboard.


## Challenges

The project solves a number of technical challenges:

1.  The absence of the comprehensive list of all traded stock tickers

    1. It is difficult, if not impossible, to find the stocks traded in a certain market, to be able to perform analysis and provide market insights.
    2.  In this project, I use a subsample of traded stocks from a particular set of markets that constitute major stock indices for those markets (one index per market). The markets (and indices) are:

        1. US: S&P 500
        2. China: CSI 300
        3. Germany: DAX
        4. India: NIFTY 50
        5. UK: FTSE 100
        6. Europe: Euro STOXX 50
        7. Latin America: S&P Latin America 40

    3. The list of stocks constituting those indices is expanded with the stocks from the custom portfolio, if they were originally missing.

2.  Ticker symbols found on the Internet do not always match the financial data available via API.

    1. For example, `4imprint Group plc`, traded as `FOUR` at LSE [has ticker symbol `FOUR.L` on the Yahoo! Finace website](https://finance.yahoo.com/quote/FOUR.L/), while ticker symbol `FOUR` on the same web-portal [corresponds](https://finance.yahoo.com/quote/FOUR/) to `Shift4 Payments, Inc`..
    2. In this project I employ search and matching by ticker symbol and company name to extract the right data from the API.

3.  Batch processing has to be implemented differently, depending on whether the backfill or a regular update is needed:

    1. The data on stock prices for the constituents of the seven selected indices exceeds 7 million rows (full history of prices for the total of 1063 ticker symbols).
    2.  Some stocks originate from the 60s: that's more than 20 thousand daily batches. Even restricting the data to start from 2010 would result in approximately 5 thousand daily batches.

        1. In order to be able to use this data to train ML models, I prefer having full history of prices.
        2. In order to get historical prices and volumes of those stocks, I use region-level batches, leveraging Kestra loops and subflows, as well as KV Store and internal storage.
        3. Regular updates are done with daily batches.


## Limitations

### Stocks Selection and Portfolio Data

Current pipeline implementation is limited to the stocks constituting major indices of the selected countries/regions.
Portfolio file is only stored in GitHub repo and can only be changed after some code tweaking (or replacing the file in the repo).

### `yfinance` Rate Limitation

This project uses `yfinance` API, an unofficial API scraping data from the Yahoo! Finance page.
The request rate is known to be limited.
The code uses high rate of requests when getting the stock data (ticker symbol, sector, industry, etc.) for a given index: the higher the number of stocks in the index, the higher the chances that you might hit the rate limit.

In order to avoid hitting rate limitation when getting more stocks data (e.g. by adding more indices and their constituents links), consider adding smaller indices into the JSON file with links to index constituents.
