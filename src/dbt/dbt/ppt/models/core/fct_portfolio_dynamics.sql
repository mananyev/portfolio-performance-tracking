with
all_tickers_prices as (
    select *
    from {{ ref('stg_tickers_prices') }}
)
, corrected_portfolio_positions as (
    select *
    from {{ ref('stg_portfolio_positions') }}
)
, portfolio_dynamics as (
	select
		all_tickers_prices.date
		, all_tickers_prices.ticker
		, all_tickers_prices.close
		, corrected_portfolio_positions.volume
		, (
            sum(case
                when corrected_portfolio_positions.date::date = all_tickers_prices.date 
                then all_tickers_prices.close * corrected_portfolio_positions.volume
                else 0
            end)
            over (
                partition by all_tickers_prices.ticker
                order by all_tickers_prices.date
            )
        ) as cost
	from all_tickers_prices
		inner join corrected_portfolio_positions
			on corrected_portfolio_positions.ticker = all_tickers_prices.ticker
			and corrected_portfolio_positions.date <= all_tickers_prices.date
)
select
	date
	, sum(cost) as total_cost
	, sum(close * volume) as total_value
	, sum(close * volume) - sum(cost) as net_value
from portfolio_dynamics
group by date
order by date