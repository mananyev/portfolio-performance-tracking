with
portfolio_dynamics as (
	select
        date
        , sum(cost) as total_cost
        , sum(close * position) as total_value
        , sum(close * position) - sum(cost) as net_value
        , sum(share * return) as portfolio_return
    from {{ ref('stg_portfolio_returns') }}
    group by date
)
, final as (
    select *, sum(ln(potfolio_return + 1)) over (order by date) as cumulative_log_return
    from ppt.fct_portfolio_dynamics 
)
select
    date
    , total_cost
    , total_value
    , net_value
    , portfolio_return
    , exp(cumulative_log_return) - 1 as cumulative_return
from portfolio_dynamics
order by date