with
corrected_portfolio_positions as (
	select
		ticker
		, case
			-- BigQuery: dayofweek returns 1=Sunday, 7=Saturday
			when extract(dayofweek from timestamp) between 2 and 6
			then cast(timestamp as date)
			else date_trunc(date_add(cast(timestamp as date), interval 1 week), week)
		end as date
		, case
            when type = 'buy'
            then volume
            when type = 'sell'
            then -volume
        end as volume
	from {{ source('staging', 'portfolio_positions') }}
)
select *
from corrected_portfolio_positions
