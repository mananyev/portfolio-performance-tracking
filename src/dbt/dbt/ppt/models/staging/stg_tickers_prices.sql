with
all_tickers_close_prices as (
	select
		ticker
        , date
		, close
        , volume
        , dividends
        , stock_splits
	from {{ source('staging', 'all_tickers_prices') }}
)
select *
from all_tickers_close_prices
