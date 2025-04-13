# # Linux terminal commands to install apts
# # Docker
# sudo apt-get install --upgrade docker docker-compose
# # If you are running into "permission denied error":
# # follow this advice: https://stackoverflow.com/a/48957722
# sudo groupadd docker
# sudo usermod -aG docker $USER
# newgrp docker
# # test
# docker run hello-world

echo "Create docker network"
docker network create ppt_project_net

echo "Setting up Kestra. This might take a while (if running for the first time)."
echo ""
docker-compose -f ./src/kestra/docker/docker-compose.yml up -d --remove-orphans
echo "Sleeping for 30 seconds to make sure Kestra is launched"
sleep 30

echo "Setting up Postgres. This might take a while (if running for the first time)."
echo ""
docker-compose -f ./src/kestra/docker/postgres/docker-compose.yml up -d --remove-orphans
sleep 10

echo "Creating a system flow to synchronize namespace flows."
echo ""
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
sleep 10

echo "Sync flows to the namespace."
echo ""
curl -X POST \
'http://localhost:8080/api/v1/executions/system/sync_flows_from_git'
sleep 10

echo "Setting KV."
echo ""
curl -v -X POST \
-F 'branch=local/kestra' \
'http://localhost:8080/api/v1/executions/ppt-project/set_postgres_kv'
sleep 10

echo "Running the backfill."
echo ""
curl -v -X POST \
-F 'whole_history=true' \
-F 'reload_tickers_list=true' \
-F 'reload_portfolio=true' \
-F 'initialize=true' \
'http://localhost:8080/api/v1/executions/ppt-project/all_tickers_names'
sleep 10

echo "Setting up Grafana. This might take a while (if running for the first time)."
echo ""
docker-compose -f ./src/grafana/docker-compose.yaml up -d --remove-orphans
