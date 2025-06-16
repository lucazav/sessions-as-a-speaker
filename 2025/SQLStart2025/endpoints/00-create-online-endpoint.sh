# Install the ML extension to the Azure CLI if missing
# by following the "Installation" section of the documentation 
# (https://docs.microsoft.com/en-us/azure/machine-learning/how-to-configure-cli).

az login --use-device-code

az account set -s "b66dba38-3b29-4e2a-bb04-c397ac385602"
az configure --defaults group="RG-DataPlatform-Dev" workspace="aml-dataplatform-dev"


# Register the model from the local path
az ml model create -f cloud/register-model.yml

# Create custom environment
az ml environment create -f cloud/environment.yml
# az ml environment create -f cloud/environment.yml --version 2

# Create manged online endpoint
az ml online-endpoint create -f cloud/endpoint.yml

# Create online deployment
az ml online-deployment create -f cloud/deployment.yml --all-traffic

# Invoke endpoint
./invoke-rest-endpoint-amltoken.sh
