select
    ticker
    , position
    , market_value - cost as individual_gain
    , market_value
    , cost
    , case
		when position = 0
		then null
		else market_value - cost
    end as current_gain
from {{ ref('stg_portfolio_returns') }}
where date = (
    select max(date)
    from {{ ref('stg_portfolio_returns') }}
)
