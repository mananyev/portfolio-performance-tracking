select *
from ref('fct_tickers_stats')
inner join (select distinct ticker from portfolio_positions) pp using (ticker)
