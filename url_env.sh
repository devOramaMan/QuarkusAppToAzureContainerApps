source ../env.sh


export AZ_APP_URL=$(
    az containerapp show \
        --name "$AZ_CONTAINERAPP" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --query "properties.configuration.ingress.fqdn" \
        --output tsv \
)

echo "AZ_APP_URL=$AZ_APP_URL"