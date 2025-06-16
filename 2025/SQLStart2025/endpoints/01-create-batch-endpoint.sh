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

# Create batch endpoint
az ml batch-endpoint create -f cloud/batch-endpoint.yml

# Create batch deployment
az ml batch-deployment create -f cloud/batch-deployment.yml --set-default

# Invoke batch endpoint
# jq is a lightweight and flexible command-line JSON processor and could be not installed in your system
# (in that case, download it from here: https://jqlang.org/download/)
JOB_NAME=$(az ml batch-endpoint invoke --name edp-bct-batch-prediction --input ./data/testing_data_from_knime.xlsx --input-type uri_file | jq -r '.name')

# Check the job status nd properties
az ml job show --name $JOB_NAME

# Download the predictions (IT DOESN'T WORK!!!)
az ml job download --name $JOB_NAME --download-path ./data

# scored.csv will be not considered by the score script, as the output file name is created during the scoring phase.
# Anyway, you must specify a non-existing output file name, otherwise it will not work
az ml batch-endpoint invoke --name edp-bct-batch-prediction --input ./data/testing_data_from_knime.xlsx --input-type uri_file --output-path azureml://datastores/ds_adlsghelfidatadev_mldata/paths/Predictions/scored.csv

