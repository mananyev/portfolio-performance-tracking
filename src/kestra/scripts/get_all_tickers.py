import pandas as pd
import requests
import bs4 as bs
import json
import io
import os
from modules import fuzzy_search
from kestra import Kestra


test_run = (os.getenv('test_run') == 'true')


with open("data.json", 'r') as file:
    companies_list_pages = json.load(file)

potential_ticker_columns = [
    'Symbol',
    'Ticker',
    'Ticker symbol',
]


all_tickers = pd.DataFrame()

for k, v in companies_list_pages.items():
    print(f"Starting region: {k}...")
    if k == 'Latin_Amerika':
        html = requests.get(v)
        soup = bs.BeautifulSoup(html.text, 'lxml')
        table = soup.find('table', {'class': 'wikitable sortable'})
        df = pd.read_html(io.StringIO(str(table)))[0]
    elif k == 'Europe':
        n = 1
        df = pd.DataFrame()
        html = requests.get(v+str(n))
        soup = bs.BeautifulSoup(html.text, 'lxml')
        table = soup.find('table', {'aria-label': 'Constituents of STOXX600'})
        temp_df = pd.read_html(io.StringIO(str(table)))[0]
        while not temp_df.empty:
            n += 1
            try:
                html = requests.get(v+str(n))
                soup = bs.BeautifulSoup(html.text, 'lxml')
                table = soup.find(
                    'table',
                    {'aria-label': 'Constituents of STOXX600'}
                )
                temp_df = pd.read_html(io.StringIO(str(table)))[0]
                if temp_df.isnull().all().all():
                    break
                else:
                    df = pd.concat([df, temp_df], axis=0, ignore_index=True)
            except:
                raise
    else:
        html = requests.get(v)
        soup = bs.BeautifulSoup(html.text, 'lxml')
        table = soup.find('table', {'id': 'constituents'})
        df = pd.read_html(io.StringIO(str(table)))[0]
    
    cols = [c for c in df.columns if c in potential_ticker_columns]
    
    if test_run:
        df = df.iloc[:5]
    
    output = df[cols].map(lambda x: x.split(":")).copy()
    tickers = df[cols].map(
        lambda x:
        x.split(":")[0].strip().replace(" ", '')
        if len(x.split(":")) == 1
        else x.split(":")[1].strip().replace(" ", '')
    )
    output['ticker'] = tickers.map(fuzzy_search)
    output['exchange'] = df[cols].map(
        lambda x: x.split(":")[0] if len(x.split(":")) > 1 else None
    )
    output['region'] = k

    all_tickers = pd.concat(
        [
            all_tickers,
            output[['ticker', 'region', 'exchange']].set_index('ticker')
        ],
        axis=0,
        # ignore_index=True
    )
    print("done.")

    if test_run:
        break

Kestra.outputs({'all_tickers': sorted(all_tickers.index.tolist())})
all_tickers[all_tickers.index.notnull()].to_csv("all_tickers.csv", index=True)
