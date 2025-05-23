# # Linux terminal commands to install apts
# # Docker
# echo "Downloading Docker."
# echo ""
# sudo apt-get install --upgrade docker docker-compose
# # If you are running into "permission denied error":
# # follow this advice: https://stackoverflow.com/a/48957722
# sudo groupadd docker
# sudo usermod -aG docker $USER
# newgrp docker
# # test
# docker run hello-world
# sleep 10

# # Terraform
# echo "Downloading Terraform."
# echo ""
# wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
# sudo apt update && sudo apt install terraform

# # Setting up infrastructure
echo "Setting up infrastructure with Terraform"
echo ""
terraform -chdir=./src/terraform init
terraform -chdir=./src/terraform plan
terraform -chdir=./src/terraform apply -auto-approve
sleep 10

echo "Setting up Kestra. This might take a while (if running for the first time)."
echo ""
docker-compose -f ./src/kestra/docker/docker-compose.yml up -d --remove-orphans
echo 'Sleeping for 1 minute to make sure Kestra is launched'
sleep 60

# # Running Kestra flows
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
      branch: main
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
-F 'branch=main' \
'http://localhost:8080/api/v1/executions/ppt-project/set_gcp_kv'
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
