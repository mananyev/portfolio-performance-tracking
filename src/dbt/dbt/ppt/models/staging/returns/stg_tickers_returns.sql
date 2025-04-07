with
past_prices as (
	select
		ticker
		, date
		, close
		, lag(close, 1) over (
			partition by ticker
			order by date
		)
	from {{ ref('stg_tickers_prices') }}
)
, returns as (
	select
		ticker
		, date
        , close
		, (close/lag - 1) as return
	from past_prices
)
select *
from returns
where return is not null