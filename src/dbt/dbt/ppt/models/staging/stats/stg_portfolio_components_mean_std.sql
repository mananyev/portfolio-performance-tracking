-- risk-return with correlations
/*
with
portfolio_stats as (
	select
		stddev(nvda.close) as sigma_nvda
		, stddev(aapl.close) as sigma_appl
		, stddev(tsla.close) as sigma_tsla
		, corr(nvda.close, aapl.close) as corr_nvda_aapl
		, corr(nvda.close, tsla.close) as corr_nvda_tsla
		, corr(tsla.close, aapl.close) as corr_tsla_aapl
	from (
			select date, close
			from ppt.all_tickers_prices
			where ticker = 'NVDA'
		) nvda
		full outer join (
			select date, close
			from ppt.all_tickers_prices
			where ticker = 'AAPL'
		) aapl using (date)
		full outer join (
			select date, close
			from ppt.all_tickers_prices
			where ticker = 'TSLA'
		) tsla using (date)
)
select *
from portfolio_stats;

-- standard deviations only
with
portfolio_stats as (
	select
		ticker
		, stddev(close) as sigma
	from ppt.all_tickers_prices
		inner join (select distinct ticker from ppt.portfolio_positions) pp using (ticker)
	group by ticker
)
select
	portfolio_stats.ticker as main_ticker
	, portfolio_stats.sigma as main_sigma
from portfolio_stats;
*/

with
portfolio_components as (
    select
        ticker
        , date
        , return*share as return_component
    from {{ ref('stg_portfolio_returns') }}
)
select
    ticker
    , avg(return_component) as mean
    , stddev(return_component) as std
from portfolio_components
group by ticker