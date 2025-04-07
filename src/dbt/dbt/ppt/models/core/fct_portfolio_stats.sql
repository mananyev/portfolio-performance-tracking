with
portfolio_mean_std as (
    select *
    from {{ ref('stg_portfolio_components_mean_std') }}
)
, portfolio_correlations as (
    select *
    from {{ ref('stg_portfolio_components_corr') }}
)
, expanded as (
    select
        portfolio_mean_std.ticker
        , portfolio_mean_std.mean
        , portfolio_mean_std.std
        , portfolio_correlations.ticker2
        , portfolio_correlations.corr
        , pms2.mean as mean2
        , pms2.std as std2
        , portfolio_mean_std.std * portfolio_mean_std.std as sigma2_1
        , portfolio_mean_std.std * portfolio_correlations.corr * pms2.std as cov
    from portfolio_mean_std
        left join portfolio_correlations using (ticker)
        left join portfolio_mean_std pms2
            on portfolio_correlations.ticker2 = pms2.ticker
)
-- to documentation:
-- divided by two because of double number of lines in `expanded`
-- due to correlation matrix table, e.g.:
-- corr(AAPL, NVDA) = corr(NVDA, AAPL)
select
    0.5 * sum(mean) as portfolio_mean_return
    , 0.5 * sum(sigma2_1 + cov) as portfolio_standard_deviation
from expanded