with
portfolio_dynamics as (
    select *
    from {{ ref('fct_portfolio_dynamics') }}
)
select
    'portfolio' as ticker
    , avg(portfolio_return) as mean_daily_return
    , stddev(portfolio_return) as std_daily_return
    , power( exp(sum(log_return)), 252.0/count(1) ) - 1 AS annualized_return
    , stddev(portfolio_return) * sqrt(252) as annualized_volatility
from portfolio_dynamics
