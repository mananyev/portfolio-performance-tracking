import os
import ast
from modules import pull_history, prepare_dataframe
from kestra import Kestra

if __name__ == "__main__":
    # read environment arguments
    ticker, region, exchange = ast.literal_eval(os.getenv('ticker'))

    whole_history = (os.getenv('backfill_all') == 'true')
    fill_since = os.getenv("backfill_since").split('T')[0]
    fill_to = os.getenv("backfill_at").split('T')[0]

    if whole_history:
        start, end = None, None
    else:
        start = fill_since
        end = fill_to

    data = pull_history(ticker, start, end)
    df_final = prepare_dataframe(data, ticker)
    df_final.to_csv("price_history.csv", index=False)

    Kestra.outputs({'ticker': ticker})
