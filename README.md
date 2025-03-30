# portfolio-performance-tracking

DataTalksClub data-engineering-zoomcamp capstone project


## Description

This project is used to create data infrastructure and a dashboard showing the performance of the selected portfolio.

Uses Yahoo! Finance data from `yfinance` Python API.

Branches:

* `main` for GCP with orchestration in Kestra.
* `local/Kestra` for local Postgres with orchestration in Kestra.


## Data Lineage

1.  Two input files:

    1. [`index_constituents_links.json`](./src/inputs/index_constituents_links.json) with links to Wikipedia pages that contain lists of stocks constituting the major indices of the selected regions/countries (like [this page for S\&P 500](http://en.wikipedia.org/wiki/List_of_S%26P_500_companies)).
    2.  [`portfolio.json`](./src/inputs/portfolio.json) with `tickers` keys and `positions` values:

        1. `tickers` are tickers that can be found in [Yahoo! Finance search](https://finance.yahoo.com/).
        2.  `positions` are dictionaries with following entries:

            1. `type`: `buy` or `sell` (no shorts),
            2. `timestamp`: when transaction happened,
            3. `volume`: number of shares,`        "
            4. `volume_type`: currently only supports `shares` (not monetary amount).

2. Tickers' price histories for the tickers from the indices and the portfolio are loaded with a `backfill` option to load the whole history of prices (as well as volumes, dividends, and stock splits).
3. TBD
