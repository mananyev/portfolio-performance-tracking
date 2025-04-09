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

<!-- You can benefit from using `make` and run everything in a single command.

> If you do not have `make` installed you can run the following command in Linux terminal:
>
> ```sudo apt-get install --upgrade make```
>
> If you are using Windows, you can follow [this guide](https://gist.github.com/evanwill/0207876c3243bbb6863e65ec5dc3f058) to install `make` and other useful tools to your Git Bash.

To initialize the project and start the initial backfill of the data, simply run

```make``` -->

To initialize the project and start the initial backfill of the data, simply run

```sh setup.sh```

That's it! You can now navigate to your [Kestra UI](http://localhost:8080) and watch the execution.


## 3. Manual Steps

1. navigate to Kestra [docker folder](./src/kestra/docker/).
2. run `docker-compose up -d` to start Kestra (its UI should be available at [localhost:8080](http://localhost:8080)).

   1. you can access the Postgres data base via PGAdmin (available at [localhost:8088](http://localhost:8088)) or via any other database tool.

3. You can now either go to [Kestra UI](http://localhost:8080) and load the flows or you can execute the following commands:
   
   1. Create a `system` flow that pulls the flows from the same GitHub repo:

      ```
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

      ```
      curl -X POST \
      http://localhost:8080/api/v1/executions/system/sync_flows_from_git
      ```
   
   3. Set KV for the project:

      ```
      curl -v -X POST \
      -F 'branch=local/kestra' 'http://localhost:8080/api/v1/executions/ppt-project/set_postgres_kv'
      ```

   4. Finally, run the back-fill:

      ```
      curl -v -X POST \
      -F 'whole_history=true' -F 'reload_tickers_list=true' -F 'reload_portfolio=true' -F 'initialize=true' \
      'http://localhost:8080/api/v1/executions/ppt-project/all_tickers_names'
      ```

That's it! You can now navigate to your [Kestra UI](http://localhost:8080) and watch the execution.
