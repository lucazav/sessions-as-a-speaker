# Install the ML extension to the Azure CLI if missing
# by following the "Installation" section of the documentation 
# (https://docs.microsoft.com/en-us/azure/machine-learning/how-to-configure-cli).

az login --use-device-code

az account set -s "bcbf34a7-1936-4783-8840-8f324c37f354"
az configure --defaults group="rg-azureml-tutorial" workspace="ws-tutorial"


# Register the model from the local path
az ml model create -f cloud/register-model.yml

# Create custom environment
az ml environment create -f cloud/environment.yml

# Create manged online endpoint
az ml online-endpoint create -f cloud/endpoint.yml

# Create online deployment
az ml online-deployment create -f cloud/deployment.yml --all-traffic
