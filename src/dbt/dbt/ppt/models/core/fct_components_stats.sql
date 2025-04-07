with
portfolio_tickers as (
    select distinct ticker
    from {{ ref('stg_portfolio_positions') }}
)
select *
from {{ ref('fct_tickers_stats') }}
    inner join portfolio_tickers using (ticker)
