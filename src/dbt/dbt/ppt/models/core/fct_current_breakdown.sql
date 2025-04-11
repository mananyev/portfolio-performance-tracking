select
    ticker
    , position
    , market_value - cost as individual_gain
    , market_value
    , cost
from {{ ref('stg_portfolio_returns') }}
where date = (
    select max(date)
    from {{ ref('stg_portfolio_returns') }}
)