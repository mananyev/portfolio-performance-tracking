with
past_prices as (
	select
		ticker
		, date
		, close
		, lag(close, 1) over (
			partition by ticker
			order by date
		) as _lag
	from {{ ref('stg_tickers_prices') }}
)
, returns as (
	select
		ticker
		, date
        , close
		, (close/_lag - 1) as return
		, ln(1.0 * close / _lag) as log_return
	from past_prices
)
select *
from returns
where return is not null