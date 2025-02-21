source ../env.sh

export POSTGRES_CONNECTION_STRING=$(
    az postgres flexible-server show-connection-string \
    --server-name "$AZ_POSTGRES_SERVER_NAME" \
    --database-name "$AZ_POSTGRES_DB_NAME" \
    --admin-user "$AZ_POSTGRES_USERNAME" \
    --admin-password "$AZ_POSTGRES_PASSWORD" \
    --query "connectionStrings.jdbc" \
    --output tsv
)


echo "POSTGRES_CONNECTION_STRING_SSL=$POSTGRES_CONNECTION_STRING_SSL"
