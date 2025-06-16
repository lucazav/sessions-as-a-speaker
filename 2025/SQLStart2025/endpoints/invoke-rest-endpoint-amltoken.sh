ENDPOINT_NAME=edp-bct-prediction
RESOURCE_GROUP=RG-DataPlatform-Dev
WORKSPACE_NAME=aml-dataplatform-dev


SCORING_URI=$(az ml online-endpoint show --name $ENDPOINT_NAME --query scoring_uri -o tsv)
echo "SCORING_URI: $SCORING_URI"

ACCESS_TOKEN=$(az ml online-endpoint get-credentials --name $ENDPOINT_NAME -g $RESOURCE_GROUP -w $WORKSPACE_NAME --query accessToken -o tsv)
EXPIRY_TIME_UTC=$(az ml online-endpoint get-credentials -n $ENDPOINT_NAME -g $RESOURCE_GROUP -w $WORKSPACE_NAME -o tsv --query expiryTimeUtc)
REFRESH_AFTER_TIME_UTC=$(az ml online-endpoint get-credentials -n $ENDPOINT_NAME -g $RESOURCE_GROUP -w $WORKSPACE_NAME -o tsv --query refreshAfterTimeUtc)

# echo "ACCESS_TOKEN: $ACCESS_TOKEN"
# echo "EXPIRY_TIME_UTC: $EXPIRY_TIME_UTC"
# echo "REFRESH_AFTER_TIME_UTC: $REFRESH_AFTER_TIME_UTC"

OUTPUT=$(curl --location \
     --request POST $SCORING_URI \
     --header "Authorization: Bearer $ACCESS_TOKEN" \
     --header "Content-Type: application/json" \
     --data @./data/test_data.json)
echo "OUTPUT: $OUTPUT"