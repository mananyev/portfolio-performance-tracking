# Installation Guide

> [!NOTE]
> For the implementation of the data pipeline in Google Cloud Platform (GCP) with orchestration in Kestra.

## 1. Prerequisites

You must have a configured GCP project with a VM instance (I used a `e2-standard-4` instance with 20GB disk space because I had issues running the Kestra setup with backfill on a smaller, `e2-medium` instance). A service account with a credentials `.json` file (and access to BigQuery and Google Cloud Storage).

> [!TIP]
> You can follow [this video by Alexey from DataTalksClub](https://youtu.be/ae-CV2KfoN0?si=rVlCuFzk5AkfHLz_) to setup a VM with all the required credentials.

1.  Make sure you have Docker and `docker-compose` installed on your machine.

    > [!NOTE]
    > To install in Linux terminal, run:
    >
    > ```sudo apt-get install --upgrade docker docker-compose```
    > 
    > For Windows, download and install [Docker Desktop](https://www.docker.com/products/docker-desktop/).
    > 
    > Test docker with
    > 
    > ```docker run hello-world```

    > [!TIP]
    > If you are having a "permission denied error", follow [these steps](https://stackoverflow.com/a/48957722).

2.  Make sure you have Terraform installed

    > [!NOTE]
    > To install Terraform on Linux, run:
    > 
    > ```bash
    > wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    > echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    > sudo apt update && sudo apt install terraform
    > ```
    >
    > For Windows installation, [download](https://developer.hashicorp.com/terraform/install) a binary file.

3.  Clone the [repository](https://github.com/mananyev/portfolio-performance-tracking/tree/main), and navigate to the cloned repository folder (e.g. `cd ~/portfolio-performance-tracking/`).

    > [!IMPORTANT]
    > Make sure you are switched to the `main` branch.

4.  Create a `.env` file with environment variables: link to the GCP credentials file to be used in Kestra, and set parameters for a BigQuery dataset and a GCS bucket.
    
    > [!TIP]
    > You can find a [template](./.gc/.env_template) to set the environment variables in the `.gc/` folder. Simply copy that folder into your HOME directory, rename it as `.env`, and edit the `.env` file.
    
    Environment variables:

    1.  GCP credentials JSON

        1. `GCP_SERVICE_ACCOUNT=\path\to\credentials\file`
        2. by default, uses the file `gcp-zoomcamp-service.json` stored in the `~/.gc/` folder.

    2.  GCP project

        1. `TF_VAR_project=\your\project\name`
        2. *there is no default, you have to set it up yourself*

    3.  GCS variables:
        1.  (optional) region

            1. `TF_VAR_region=\your\preferred\region`
            2. uses `EU` by default

        2.  location

            1. `TF_VAR_location=\your\preferred\location`
            2. uses `europe-west3` (Frankfurt) by default

        3.  (optional) storage class

            1. `TF_VAR_gcs_storage_class=\your\preferred\storage\class`
            2. uses `STANDARD` by default

        4.  bucket name

            1. **Make sure you set it to a globally unique name!**
            2. `TF_VAR_gcs_bucket_name=\your\unique\bucket\name`
            3. *there is no default, you have to set it up yourself*
    
    4.  BigQuery dataset name
        
        1. `TF_VAR_bq_dataset_name=\your\preferred\dataset\name`
        2. uses `portfolio_tracking` by default

5.  After you have the `.env` file ready, *source* the [bash script](./.gc/set_environment.sh) in that `.gc/` folder to set the variables for Terraform and Kestra aligned:

    1. navigate to `.gc/` folder: `cd ~/.gc/`
    2. run `source set_environment.sh`

    > [!IMPORTANT]
    > It is important that:
    > 
    > 1. The file with the environment variables is called `.env` (not `.env_template`).
    > 2. The variables (expept for `GCP_SERVICE_ACCOUNT`) start with `TF_VAR_` prefixes: they are exported to a local environment for Terraform. The `set_environment.sh` script also uses this prefix to replace it with `KESTRA_` prefix for Kestra to use the same variables.
    > 3. You use the `source` command.


## 2. Create Pipeline
### 2.1 Using `setup.sh`

To initialize the project and start the initial backfill of the data, simply run

```sh setup.sh```

That's it! You can now navigate to your [Kestra UI](http://localhost:8080) and watch the execution.

> [!TIP]
> Make sure to forward port 8080 on your VM.

### 2.2 Alternatively, Follow These Steps

1. navigate to Kestra [docker folder](./src/kestra/docker/).
2. run `docker-compose up -d` to start Kestra (its UI should be available at [localhost:8080](http://localhost:8080) if you forward port 8080).

3.  You can now either go to [Kestra UI](http://localhost:8080) and load the flows or you can execute the following commands:

    1.  Create a `system` flow that pulls the flows from the same GitHub repo:

        ```bash
        curl -X POST http://localhost:8080/api/v1/flows \
        -H "Content-Type:application/x-yaml" \
        -d "id: sync_flows_from_git
        namespace: system
        tasks:
            - id: sync_flows
            type: io.kestra.plugin.git.SyncFlows
            url: https://github.com/mananyev/portfolio-performance-tracking
            branch: main
            targetNamespace: ppt-project
            gitDirectory: src/kestra/flows
            dryRun: false"
        ```

    2.  Execute this `system` flow to sync the flows:

        ```bash
        curl -X POST \
        'http://localhost:8080/api/v1/executions/system/sync_flows_from_git'
        ```

    3.  Set KV for the project:

        ```bash
        curl -v -X POST \
        -F 'branch=main' \
        'http://localhost:8080/api/v1/executions/ppt-project/set_postgres_kv'
        ```

    4.  Finally, run the back-fill:

        ```bash
        curl -v -X POST \
        -F 'whole_history=true' \
        -F 'reload_tickers_list=true' \
        -F 'reload_portfolio=true' \
        -F 'initialize=true' \
        'http://localhost:8080/api/v1/executions/ppt-project/all_tickers_names'
        ```

    5. Set up Looker Studio or another dashboarding tool.

That's it! You can now navigate to your [Kestra UI](http://localhost:8080) and watch the execution.


## 4. Setting Up Queries in Looker

1.  Configure data sources. To replicate the dashboard shown in the screenshot, you need to connect the following tables

    1. `fct_current_breakdown`
    2. `fct_components_returns`
    3. `fct_portfolio_dynamics`
    4.  Custom Query for risk-return profiles:
        ```SQL
        (
        select
            *
            , 'all comp' as tag
        from portfolio_tracking.fct_components_stats
        )
        union all
        (
        select
            cs.*
            , 'current comp' as tag
        from portfolio_tracking.fct_components_stats cs
            inner join portfolio_tracking.fct_current_breakdown using (ticker)
        where market_value is not null
        )
        union all
        (
        select
            *
            , 'historical' as tag
        from portfolio_tracking.fct_portfolio_stats
        )
        union all
        (
        select
            *
            , 'tickers' as tag
        from portfolio_tracking.fct_tickers_stats
        order by mean_daily_return
        limit 950
        );
        ```

2.  Create graphs:

    1. Current portfolio shares (using `fct_current_breakdown`)
    2. Current gain breakdown (using the same table)
    3. Individual net value of portfolio positions over time (using `fct_components_returns`)
    4. Cumulative net value over time (using `fct_portfolio_dynamics`)
    5. Risk-return profiles (using Custom Query)


## 5. Running Tests and Generating Documentation for dbt
### 5.1 Testing in Kestra

This project comes with a number of simple tests aiming to ensure the high quality of the data.
Both options for `dbt test` and `dbt docs generate` are implemented as an optional inputs for Kestra flow `postgres_dbt`.

To use these features, log into Kestra UI (at [localhost:8080](http://localhost:8080)), open the flows, open the `bigquery_dbt` flow, click 'Execute' button, and select the desired option.

> [!WARNING]
>  At the moment, there is no easy way to acces the generated documentation. Several options can be found on [dbt docs](https://docs.getdbt.com/docs/build/documentation) or in [Medium articles](https://medium.com/dbt-local-taiwan/host-dbt-documentation-site-with-github-pages-in-5-minutes-7b80e8b62feb) but I failed to implement them in this project.
