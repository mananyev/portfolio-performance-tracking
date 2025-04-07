-- risk-return 
with
ticker_stats as (
    select
        *
    from {{ ref('stg_tickers_returns') }}
)
select
    ticker
    , avg(return) as mean
    , stddev(return) as std
from ticker_stats
group by ticker
