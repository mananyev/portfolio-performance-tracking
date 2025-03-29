import yfinance as yf
import pandas as pd
from datetime import date


def fuzzy_search(
            ticker: str,
            split: str='.',
            n: int=0,
            tried: list=[],
            test: bool=False
        ) -> str:
    """Checks if ticker exists in Ticker.
    If not, searches for the correct ticker code.
    Returns None if ticker not found!
    
    """
    
    quotes = yf.Search(ticker).quotes
    if quotes:
        types = [quotes[i]['quoteType'] for i in range(len(quotes))]
        if 'EQUITY' in types:
            idx = types.index('EQUITY')
            if test:
                print(f'quotes, equity, n={n}')
            ticker = quotes[idx]['symbol']
        else:
            if split in tried:
                return ticker.split(split)[0]
            else:
                tried = tried + [split,]
                ticker_ = ticker.split(split)
                if len(ticker_) > 1:
                    if test:
                        print(f"quotes, no equity, enter with sep: {split}, n={n}")
                    ticker = fuzzy_search('-'.join(ticker_), '-', n+1, tried)
                else:
                    if test:
                        print(f"quotes, no equity, splitted by: {split}, n={n}")
                    ticker = fuzzy_search(ticker, '-', n+1, tried)
    else:
        if split in tried:
            return None
        else:
            tried = tried + [split,]
            ticker_ = str(ticker).split(split)
            if len(ticker_) > 1:
                if test:
                    print(f"no quotes, enter with sep: {split}, n={n}")
                ticker = fuzzy_search('-'.join(ticker_), '-', n+1, tried)
            else:
                if test:
                    print(f'no quotes, splitted by: {split}, n={n}')
                ticker = fuzzy_search(ticker, '-', n+1, tried)
        
    if test:
        print(f"current n (level): {n}, current ticker={ticker}")
    
    return ticker


def pull_history(ticker: str, start: str=None, end: str=None) -> pd.DataFrame:
    """Pulls the history of prices and volumesfrom yfinance for a given:
    
        - `ticker`, with data between
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
    out = yf.Ticker(ticker).history(**args)

    return out
    

def prepare_dataframe(data: pd.DataFrame, ticker: str) -> pd.DataFrame:
    """Minor adjustments to the data frame."""

    assert not data.empty, print("Empty data frame!")

    dat = data.reset_index()
    out = pd.DataFrame(index=dat.index)
    out['ticker'] = ticker
    out['date'] = dat['Date'].dt.date
    out['open'] = dat['Open']
    out['high'] = dat['High']
    out['low'] = dat['Low']
    out['close'] = dat['Close']
    out['volume'] = dat['Volume']
    out['dividends'] = dat['Dividends']
    out['stock_splits'] = dat['Stock Splits']    

    return out
