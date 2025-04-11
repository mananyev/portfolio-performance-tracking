select
    ticker
    , position
    , (position*close - cost) as individual_gain
from {{ ref('stg_portfolio_returns') }}
where date = (
    select max(date)
    from {{ ref('stg_portfolio_returns') }}
)