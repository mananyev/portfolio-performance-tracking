with
portfolio_positions as (
    select *
    from {{ ref('stg_portfolio_positions') }}
)
, portfolio_tickers as (
    select distinct ticker
    from portfolio_positions
)
, past_prices as (
	select
		ticker
		, date
		, close
		, lag(close, 1) over (
			partition by ticker
			order by date
		) as _lag
	from {{ ref('stg_tickers_prices') }}
        inner join portfolio_tickers using (ticker)
)
, returns as (
	select
		past_prices.ticker
		, past_prices.date
        , past_prices.close
		, past_prices.close/past_prices._lag - 1 as return
		-- rolling sum here because we want to "drag" costs into the future
		, (
            sum(case
                when portfolio_positions.date = past_prices.date 
                then past_prices.close * portfolio_positions.volume
                else 0
            end)
            over (
                partition by past_prices.ticker, portfolio_positions.volume
                order by past_prices.date
            )
		) as cost
		, case
			when portfolio_positions.date = past_prices.date 
			then past_prices.close * portfolio_positions.volume
			else 0
		end as cash_flow
		, portfolio_positions.volume
	from past_prices
		inner join portfolio_positions
			on portfolio_positions.ticker = past_prices.ticker
			and portfolio_positions.date <= past_prices.date
)
select
	date
	, ticker
	, close
	, return
	, sum(volume) as position
	, sum(cost) as cost
	, sum(cash_flow) as cash_flow
	, close * sum(volume) as market_value
from returns
where return is not null
group by date
	, ticker
	, close
	, return
