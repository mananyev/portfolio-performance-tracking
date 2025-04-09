# Installation Guide

> For the local implementation of the data pipeline with orchestration in Kestra.

## 1. Prerequisites

1. Make sure you have Docker and `docker-compose` installed on your machine.

   > To install in Linux terminal, run:
   >
   > ```sudo apt-get install --upgrade docker docker-compose```
   > 
   > If you are using Windows, you need to install [Docker Desktop](https://www.docker.com/products/docker-desktop/).

2. Clone the [repository](https://github.com/mananyev/portfolio-performance-tracking/tree/local/kestra), and 
3. switch to the `local/kestra` branch.

> **Important:** make sure you are switched to the `local/kestra` branch.


## 2. Using `setup.sh`

To initialize the project and start the initial backfill of the data, simply run

```sh setup.sh```

That's it! You can now navigate to your [Kestra UI](http://localhost:8080) and watch the execution.
Grafana is available at [localhost:3000](http://localhost:3000).


## 3. Manual Steps

1. navigate to Kestra [docker folder](./src/kestra/docker/).
2. run `docker-compose up -d` to start Kestra (its UI should be available at [localhost:8080](http://localhost:8080)).

   1. you can access the Postgres data base via PGAdmin (available at [localhost:8088](http://localhost:8088)) or via any other database tool.

3. You can now either go to [Kestra UI](http://localhost:8080) and load the flows or you can execute the following commands:
   
   1. Create a `system` flow that pulls the flows from the same GitHub repo:

      ```bash
      curl -X POST http://localhost:8080/api/v1/flows \
      -H "Content-Type:application/x-yaml" \
      -d "id: sync_flows_from_git
      namespace: system
      tasks:
        - id: sync_flows
          type: io.kestra.plugin.git.SyncFlows
          url: https://github.com/mananyev/portfolio-performance-tracking
          branch: local/kestra
          targetNamespace: ppt-project
          gitDirectory: src/kestra/flows
          dryRun: false"
      ```
   
   2. Execute the `system` flow:

      ```bash
      curl -X POST \
      http://localhost:8080/api/v1/executions/system/sync_flows_from_git
      ```
   
   3. Set KV for the project:

      ```bash
      curl -v -X POST \
      -F 'branch=local/kestra' 'http://localhost:8080/api/v1/executions/ppt-project/set_postgres_kv'
      ```

   4. Finally, run the back-fill:

      ```bash
      curl -v -X POST \
      -F 'whole_history=true' -F 'reload_tickers_list=true' -F 'reload_portfolio=true' -F 'initialize=true' \
      'http://localhost:8080/api/v1/executions/ppt-project/all_tickers_names'
      ```
   
   5. Set Up Grafana:

      ```bash
      docker-compose -f ./src/grafana/docker-compose.yaml up -d
      ```

That's it! You can now navigate to your [Kestra UI](http://localhost:8080) and watch the execution.
Grafana is available at [localhost:3000](http://localhost:3000).


## 4. Setting Up a Grafana dashboard

1. Configure data source:
   
   1. host URL: `host.docker.internal:5432`
   2. database name: `postgres-ppt` (or the one you set in the docker-compose files)
   3. Username: `kestra` (or the one you set in the docker-compose files)
   4. Password: `k3str4` (or the one you set in the docker-compose files)
   5. TLS/SSL Mode: `disable` (otherwise `host.docker.internal` will not work)

2. Create queries and panels:
   
   1. Portfolio composition:
      
      1. query:
         
         <details>
         <summary>details</summary>

         ```sql
         select ticker, position
         from ppt.stg_portfolio_returns
         where date = (select max(date) from ppt.stg_portfolio_returns);
         ```
         </details>

      2. Select the graph to be a pie chart.
   
   2. Risk-return:
      
      1. Query A
         
         <details>
         <summary>details</summary>

         ```sql
         select
            ticker
            , 100 * mean as "mean return, %"
            , std as "standard deviation"
         from ppt.fct_tickers_stats;
         ```
         </details>

      2. Query B
         
         <details>
         <summary>details</summary>

         ```sql
         select
            'portfolio' as ticker
            , 100 * mean as "mean return, %"
            , std as "standard deviation"
         from ppt.fct_portfolio_stats;
         ```
         </details>

      3. Query C
         
         <details>
         <summary>details</summary>

         ```sql
         select
            ticker
            , 100 * mean as "mean return, %"
            , std as "standard deviation"
         from ppt.fct_components_stats;
         ```
         </details>

      4. override options:
      
         1. Override 1:
            
            1. Fields returned by query - Query B
            2. Point size: 7
            3. Point shape: square
            4. Color scheme: single color - red
         
         2. Override 2:
            
            1. Fields returned by query - Query C
            2. Point size: 10
            3. Color scheme: single color - yellow

   3. Net gain

      1. query: 

         <details>
         <summary>details</summary>

         ```sql
         select
            date
            , net_value
         from fct_portfolio_dynamics;
         ```
         </details>

   4. Net gain

      1. query: 

         <details>
         <summary>details</summary>

         ```sql
         select
            date
            , cumulative_return * 100
         from ppt.fct_portfolio_dynamics;
         ```
         </details>
