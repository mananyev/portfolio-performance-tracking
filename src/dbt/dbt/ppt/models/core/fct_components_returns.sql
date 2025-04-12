select
    date
    , ticker
    , close
    , return
	, market_value - cost as net_value
	, case
		when position = 0
		then null
		else market_value - cost
	end as current_value
from {{ ref('stg_portfolio_returns') }}
