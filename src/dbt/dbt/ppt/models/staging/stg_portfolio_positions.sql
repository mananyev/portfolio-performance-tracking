with
corrected_portfolio_positions as (
	select
		ticker
		, case
			when extract('dow' from timestamp) between 1 and 5
			then timestamp
			else date_trunc('week', timestamp + interval '1 week')
		end::date as date
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
