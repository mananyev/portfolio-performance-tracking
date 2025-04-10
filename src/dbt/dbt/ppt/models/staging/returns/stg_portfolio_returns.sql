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
		, (past_prices.close/past_prices._lag - 1) as return
		, (
            sum(case
                when portfolio_positions.date::date = past_prices.date 
                then past_prices.close * portfolio_positions.volume
                else 0
            end)
            over (
                partition by past_prices.ticker
                order by past_prices.date
            )
        ) as cost
		, portfolio_positions.volume
	from past_prices
		inner join portfolio_positions
			on portfolio_positions.ticker = past_prices.ticker
			and portfolio_positions.date <= past_prices.date
)
, portfolio_dynamics as (
	select
		sum(volume) as position
		, ticker
		, date
		, close
		, return
		, cost
	from returns
	where return is not null
	group by ticker
		, date
		, close
		, return
		, cost
)
select
	date
    , ticker
    , position
    , close
    , return
	, 1.0 * position / sum(position) over (partition by date) as share
    , cost
from portfolio_dynamics
order by date, ticker
