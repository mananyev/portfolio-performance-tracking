import yfinance as yf
import pandas as pd
from datetime import date


def ticker_search(args) -> pd.DataFrame:
    """Checks if ticker quotes exist in Ticker.
    Attempts to find correct ticker (based on name and ticker symbol).
    Returns an empty dataframe if not found.
    
    """

    name, ticker = args.company, args.ticker
    name = name.split('(')[0].strip()

    merge_cols = [
        'exchange',
        'shortname',
        'quoteType',
        'symbol',
        'index',
        'typeDisp',
        'longname',
        'exchDisp',
        'sector',
        'sectorDisp',
        'industry',
        'industryDisp',
        'isYahooFinance',
    ]

    quotes_name = yf.Search(name).quotes
    if quotes_name:
        q_df_name = pd.DataFrame(quotes_name)
        missing_cols = list(set(merge_cols+['score',]) - set(q_df_name.columns.tolist()))
        q_df_name[missing_cols] = ''
    else:
        q_df_name = pd.DataFrame(columns=merge_cols+['score',])
    quotes_ticker = yf.Search(ticker).quotes
    if quotes_ticker:
        q_df_ticker = pd.DataFrame(quotes_ticker)
        missing_cols = list(set(merge_cols+['score',]) - set(q_df_ticker.columns.tolist()))
        q_df_ticker[missing_cols] = ''
    else:
        q_df_ticker = pd.DataFrame(columns=merge_cols+['score',])

    df = pd.merge(
        left=q_df_ticker,
        right=q_df_name,
        on=merge_cols,
        how='left',
    ).sort_values(by=['score_y', 'score_x'], ascending=False)
    return_cols = ['symbol', 'longname', 'exchange', 'sector', 'industry']
    if not df.empty:
        df = df.iloc[0]
    else:
        df = pd.Series(index=return_cols)

    return df[return_cols]


def pull_history(tickers: list, start: str=None, end: str=None) -> pd.DataFrame:
    """Pulls the history of prices and volumesfrom yfinance for a given:
    
        - `tickers`, with data between
        - `_start` (string 'YYYY-MM-DD'), and
        - `_end` (string 'YYYY-MM-DD') dates.
    
    """

    args = {}
    if start == None and end == None:
        args['period'] = 'max'
    else:
        try:
            s_year, s_month, s_day = start.split('-')
            e_year, e_month, e_day = end.split('-')
            _start = date(int(s_year), int(s_month), int(s_day))
            _end = date(int(e_year), int(e_month), int(e_day))
            args['start'] = _start
            args['end'] = _end
        except:
            print('`_start` or `_end` (or both) arguments are not strings of format "YYYY-MM-DD".')
            raise

    out = pd.DataFrame()
    out = yf.Tickers(tickers).history(**args)
    # the output is multi-column data frame - we need date and ticker in index
    out = out.unstack().unstack(level=0)
    # do not want empty histories, and want only date in index
    out = out.dropna(how='all').reset_index().set_index('Date')
    if not out.empty:
        out = out.loc[out.index.date < date.today()]

    return out
    

def prepare_dataframe(data: pd.DataFrame) -> pd.DataFrame:
    """Minor adjustments to the data frame."""

    dat = data.reset_index()
    out = pd.DataFrame(
        index=dat.index,
        columns=[
            'ticker',
            'date',
            'open',
            'high',
            'low',
            'close',
            'volume',
            'dividends',
            'stock_splits',
        ]
    )
    if not data.empty:
        out['ticker'] = dat['Ticker']
        out['date'] = dat['Date'].dt.date
        out['open'] = dat['Open']
        out['high'] = dat['High']
        out['low'] = dat['Low']
        out['close'] = dat['Close']
        out['volume'] = dat['Volume'].astype('int')
        out['dividends'] = dat['Dividends']
        out['stock_splits'] = dat['Stock Splits']    

    return out
