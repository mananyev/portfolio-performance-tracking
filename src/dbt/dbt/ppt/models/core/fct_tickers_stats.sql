-- risk-return 
with
ticker_stats as (
    select *
    from {{ ref('stg_tickers_returns') }}
)
select
    ticker
    , avg(return) as mean_daily_return
    , stddev(return) as std_daily_return
    , power( exp(sum(log_return)), 252.0/COUNT(*) ) - 1 AS annualized_return
    , stddev(return) * sqrt(252) as annualized_volatility
from ticker_stats
group by ticker
