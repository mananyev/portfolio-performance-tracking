with
portfolio_dynamics as (
    select
        date
        , sum(cost) as total_cost
        , sum(market_value) as total_value
        , sum(market_value) - sum(cost) as net_value
    from {{ ref('stg_portfolio_returns') }}
    group by date
)
, with_lag as (
    select
        *
        , lag(total_value) over (order by date) as _lag
    from portfolio_dynamics
)
, final as (
    select
        *
        , total_value / _lag - 1 as portfolio_return
        , ln(1.0 * total_value / _lag) as log_return
    from with_lag
    where _lag is not null
)
select
    date
    , total_cost
    , total_value
    , net_value
    , portfolio_return
    , log_return
    , sum(exp(log_return) over (order by date)) - 1 as cumulative_return
from final
order by date
