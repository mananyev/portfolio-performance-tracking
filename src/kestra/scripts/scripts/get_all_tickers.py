import pandas as pd
import requests
import bs4 as bs
import json
import io
from modules import ticker_search
from kestra import Kestra
import time


sleep = 10

with open("data.json", 'r') as file:
    companies_list_pages = json.load(file)

potential_ticker_columns = [
    'Symbol',
    'Ticker',
    'Ticker symbol',
]
potential_name_columns = [
    'security',
    'company',
    'company name',
    'name',
]

print(f"Starting region: {companies_list_pages['region']}...")
if companies_list_pages['region'] == 'Latin_Amerika':
    html = requests.get(companies_list_pages['link'])
    soup = bs.BeautifulSoup(html.text, 'lxml')
    table = soup.find('table', {'class': 'wikitable sortable'})
    df = pd.read_html(io.StringIO(str(table)))[0]
else:
    html = requests.get(companies_list_pages['link'])
    soup = bs.BeautifulSoup(html.text, 'lxml')
    table = soup.find('table', {'id': 'constituents'})
    df = pd.read_html(io.StringIO(str(table)))[0]

cols = [c for c in df.columns if c in potential_ticker_columns]
name_cols = [c for c in df.columns if c.lower() in potential_name_columns]

output = df[cols].map(lambda x: x.split(":")).copy()
tickers = df[cols].map(
    lambda x:
    x.split(":")[0].strip().replace(" ", '')
    if len(x.split(":")) == 1
    else x.split(":")[1].strip().replace(" ", '')
)
if companies_list_pages['region'] == 'UK':
    tickers = tickers + '.L'
names = df[name_cols]
temp = pd.concat([tickers, names], axis=1)
temp.columns = ['ticker', 'company']
search = temp.apply(ticker_search, axis=1, result_type='expand')
output['ticker'] = search.symbol
output['exchange'] = search.exchange
output['region'] = companies_list_pages['region']
output['company'] = search.longname
output['sector'] = search.sector
output['industry'] = search.industry

all_tickers = output.loc[
    output['ticker'].notnull(),
    [
        'ticker',
        'company',
        'region',
        'sector',
        'industry',
        'exchange',
    ]
].set_index('ticker')
print("done.")

print(f"Sleep {sleep} seconds")
time.sleep(sleep)

all_tickers = all_tickers[all_tickers.index.notnull()]
Kestra.outputs({'all_tickers': sorted(all_tickers.index.tolist())})
all_tickers.to_csv("all_tickers.csv", index=True)
