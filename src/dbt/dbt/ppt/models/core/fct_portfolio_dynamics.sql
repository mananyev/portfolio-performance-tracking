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
select *
from portfolio_dynamics
order by date