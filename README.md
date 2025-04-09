# Custom Portfolio Performance Tracking

> DataTalksClub data-engineering-zoomcamp capstone project.


## 1. Introduction

Retail investors, in particular, informed traders, usually look up a lot of information on the Internet.
This information typically includes financial and economic news, published reports, and a number of indicators.
Gathering the required information might be time consuming and costly, and might not always be available at hand.
Furthermore, it is important to assess the quality of the investment decisions one makes and how they affect the portfolio (and investor's wealth).
Standard brokers (for example, Trade Republic) offer limited scope for analysis of a custom portfolio.[^1]
Financial portals like Yahoo! Finance, offer analysis tools and performance tracking for users with paid subscription.[^2]

This project provides a data pipeline that creates a simple overview of the custom portfolio, calculates its risk-return profile (and compares it to the profile of its individual components and of the other assets in the market), tracks its performance over time, and allows building various types of analysis on top.
The final dashboard is shown on the screenshot below.

![Dashboard in Grafana](./assets/screenshots/grafana_dashboard.png)

> P.S. I am also going to use this data pipeline in the future to train ML models that will help developing trading strategies and optimizing portfolio selection, although these steps are momentarily beyond the scope of the project.

[^1]: Trade Republic shows the statistics and the dynamics for returns/gains of the performance portfolio you currently have, not for the portfolio you want to check/compare.

[^2]: Risk Analysis and Portfolio Performance are, for example, available at [Yahoo! Finace website](https://finance.yahoo.com/about/plans/select-plan/portfolioAnalytics) only for users with a paid subscription (starting from $7.95/month for a Bronze tier).


## 2. Project Description
### 2.1 Branches

* `main` -- for GCP/GCS/BigQuery with orchestration in Kestra.
* **`local/kestra`** (*current*) -- for local Postgres with orchestration in Kestra.

### 2.2 Installation Guide

For local installation you need:

- some kind of a terminal,
- Docker.

If you are running this on a Linux machine, you probably already have both of these requirements satisfied.
For Windows, install both, if needed.

Please, read the complete [installation guide here](./installation.md).

### 2.3 Tools

For the local setup, the following tools have been used

1. Orchestration is done using [Kestra](https://kestra.io/).
2. Data is loaded via [Python](https://www.python.org/) scripts using popular libraries such as: `requests`, `beautifulsoup`, `pandas`. Financial data is retreived using `yfinance` library.
3. Data is stored in a local [PostgreSQL Relational Database](https://www.postgresql.org/).
4. Analytical transformations are managed with [dbt Labs](https://www.getdbt.com/).
5. Local dashboard was made using [Grafana](https://grafana.com/).

![Pipeline](./assets/screenshots/pipeline_local_kestra.png)

### 2.4 Data Lineage

1.  Two input files (stored in the GitHub repository for this project):

    1. [`index_constituents_links.json`](./src/inputs/index_constituents_links.json) with links to Wikipedia pages that contain lists of stocks constituting the major indices of the selected regions/countries (like [this page for S\&P 500](http://en.wikipedia.org/wiki/List_of_S%26P_500_companies)).
    2.  [`portfolio.json`](./src/inputs/portfolio.json) with `tickers` keys and `positions` values:

        1. `tickers` are tickers that can be found in [Yahoo! Finance search](https://finance.yahoo.com/).
        2.  `positions` are dictionaries with following entries:

            1. `type`: `buy` or `sell`,
            2. `timestamp`: when transaction happened,
            3. `volume`: number of shares,
            4. `volume_type`: currently only supports `shares` (not monetary amount).

2. Stock information (company name and suggested ticker) is extracted from the links to Wikipedia pages.
3. Corrected ticker information (ticker symbol, sector, industry, exchange) is searched through `yfinance` API.
4. Tickers' price (as well as volumes, dividends, and stock splits) histories for the stocks from the indices and from the portfolio are loaded on a daily basis and stored in Postgres.
   
   1. `whole_history` option allows backfilling the whole history of prices at once.

5. Data is transformed using `dbt` and loaded back to Postgres.

   1. Includes the calculation of the risk-return profile for the whole portfolio, its individual components, and other tickers.

6. Risk-return profile and portfolio's composition and performance are visualized in a Grafana dashboard.


## 3. Challenges

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

    1. The data on stock prices for the constituents of the seven selected indices exceeds 7 million rows (full history of prices for more than a thousand ticker symbols).
    2.  Some stocks originate from the 60s: that's more than 20 thousand daily batches. Even restricting the data to start from 2010 would result in approximately 5 thousand daily batches.

        1. In order to be able to use this data to train ML models, I prefer having full history of prices.
        2. In order to get historical prices and volumes of those stocks, I use region-level batches, leveraging Kestra loops and subflows, as well as KV Store and internal storage.
        3. Regular updates are done with daily batches.

4. Portfolio risk-return analysis (mean daily return of the portfolio and its variance, calculated from its components) calculation using SQL.
   ![image](./assets/screenshots/risk_return.png)


## 4. Limitations

### 4.1 Stocks Selection and Portfolio Data

Current pipeline implementation is limited to the stocks constituting major indices of the selected countries/regions.
Portfolio file is only stored in GitHub repo and can only be changed after some code tweaking (or replacing the file in the repo).

### 4.2 Portfolio Limitations

Current implementation for portfolio performance only allows for buy and sell positions and only for volume given in shares (not in monetary terms).
Technically, short positions are allowed with the "sell" position type.

### 4.3 `yfinance` Rate Limitation

This project uses `yfinance` API, an unofficial API scraping data from the Yahoo! Finance page.
The request rate is known to be limited.
The code uses high rate of requests when getting the stock data (ticker symbol, sector, industry, etc.) for a given index: the higher the number of stocks in the index, the higher the chances that you might hit the rate limit.

In order to avoid hitting rate limitation when getting more stocks data (e.g. by adding more indices and their constituents links), consider adding smaller indices into the JSON file with links to index constituents.

### 4.4 Analysis Limitation

Currently, only the following graphs are included into the dashboard:

* (current) portfolio composition,
* net gain and cumulative returns dynamics,
* risk-return profile of the portfolio, its components, and all the tickers in the database.

### 4.5 Resource Requirements Limitation

I tried running this project locally on a standard `e2-medium` VM (2 vCPU, 1 core, 4 GB memory) with a 10 GB drive, and the initial backfill execution (most important one) failed due to memory issues.

Running the same local setup on a `e2-standard-4` VM (4 vCPUs, 16 GB Memory) with extra disk space (20 GB total) went well until it failed because of the failure to connect to `host.docker.internal` (problem not solved yet).

Running from the scratch on a local Windows machine goes with no issues.


## 5. Future Steps

The main purpose for this data pipeline is to be used for training ML models to optimize portfolio selection.
The data base with returns and individual ticker statistics is created with this project, alongside with a dashboard showing key metrics.
Major improvement steps, as I envision them, include:

1. An easy way to load a custom portfolio

   1. assuming an ML model producing an output with tickers (components), their transaction date, and traded volume (similar to the [example portfolio](./src/inputs/portfolio.json)), this pipeline needs to read the file from a local/cloud storage.

2. A benchmark functionality:

   1. Country/region indices, custom portfolios, or backtesting portfolios suggested by an ML model.
