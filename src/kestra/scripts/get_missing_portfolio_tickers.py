import pandas as pd
import json
# import os


with open("portfolio.json", 'r') as file:
    positions_data = json.load(file)

for k, v in positions_data.items():
    print(f"Starting region: {k}...")
    print(f"Position: {v}")

if __name__ == '__main__':
    print("Missing tickers:")
    # all_tickers[all_tickers.index.notnull()].to_csv("all_tickers.csv", index=True)
