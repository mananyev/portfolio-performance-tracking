with
portfolio_tickers as (
    select distinct ticker
    from {{ ref('stg_portfolio_positions') }}
)
, past_prices as (
	select *
	from {{ ref('stg_tickers_returns') }}
        inner join portfolio_tickers using (ticker)
)
, corr_prep as (
	select
		past_prices.ticker
		, past_prices.date
		, past_prices.close
		, past_prices.return
		, pp2.ticker as ticker2
		, pp2.close as close2
		, pp2.return as return2
	from past_prices
		left join past_prices pp2
			on pp2.date = past_prices.date
			and pp2.ticker != past_prices.ticker
	order by past_prices.date, past_prices.ticker
)
select
	ticker
	, ticker2
	, corr(return, return2) as corr
from corr_prep
where ticker is not null
	and ticker2 is not null
group by ticker, ticker2