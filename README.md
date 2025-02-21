# QuarkusAppToAzureContainerApps
Deploy a Quarkus application to Azure Container Apps ([resource](https://learn.microsoft.com/en-us/training/modules/deploy-java-quarkus-azure-container-app-postgres)).

## Prerequisite

<ul style="list-style-type: circle;">
  <li>An Azure subscription</li>
  <li>Local installations of Java JDK (17 or later)</li>
  <li>Maven (3.1 or later)</li>
  <li>Azure CLI (2.57 or later)</li>
  <li>Docker and Docker Desktop</li>
</ul>

## Generate Project with maven

```bash
mvn -U io.quarkus:quarkus-maven-plugin:3.7.3:create \
-DplatformVersion=3.7.3 \
-DprojectGroupId=com.example.demo \
-DprojectArtifactId=todo \
-DclassName="com.example.demo.TodoResource" \
-Dpath="/api/todos" \
-DjavaVersion=17 \
-Dextensions="resteasy-jackson, hibernate-orm-panache, jdbc-postgresql, docker"
```


```bash
cd todo
./mvnw quarkus:dev
```


```bash
curl --header "Content-Type: application/json" \
--request POST \
--data '{"description":"Take Quarkus MS Learn","details":"Take the MS Learn on deploying Quarkus to Azure Container Apps","done": "true"}' \
http://127.0.0.1:8080/api/todos
```
response:

```bash
{"id":1,"description":"Take Quarkus MS Learn","details":"Take the MS Learn on deploying Quarkus to Azure Container Apps","done":true,"createdAt":"2025-02-19T12:03:19.162117400Z"}
```

```bash
curl --header "Content-Type: application/json" \
--request POST \
--data '{"description":"Take Azure Container Apps MS Learn","details":"Take the ACA Learn module","done": "false"}' \
http://127.0.0.1:8080/api/todos
```

```bash
curl http://127.0.0.1:8080/api/todos
```
```json
[
  {"id":1,"description":"Take Quarkus MS Learn","details":"Take the MS Learn on deploying Quarkus to Azure Container Apps","done":true,"createdAt":"2025-02-19T12:03:19.162117Z"},
  {"id":2,"description":"Take Azure Container Apps MS Learn","details":"Take the ACA Learn module","done":false,"createdAt":"2025-02-19T12:05:02.580096Z"}
]
```
When I updated the test file, it seemed like the 'Quarkus runtime environment' detected the update and ran the test successfully. However, the instructions require running maven clean and maven test:

```bash
./mvnw clean test 
```

```bash
export AZ_PROJECT_<your initials>="azure-deploy-quarkus"
export AZ_RESOURCE_GROUP="rg${AZ_PROJECT_<your initials>}"
export AZ_LOCATION="eastus"
export AZ_CONTAINERAPP="ca${AZ_PROJECT_<your initials>}"
export AZ_CONTAINERAPP_ENV="cae${AZ_PROJECT_<your initials>}"
export AZ_POSTGRES_DB_NAME="postgres${AZ_PROJECT_<your initials>}"
export AZ_POSTGRES_USERNAME="<user-name>"
export AZ_POSTGRES_PASSWORD="<secure-password>"
export AZ_POSTGRES_SERVER_NAME="psql${AZ_PROJECT_<your initials>}"
```

```bash
az group create \
--name $AZ_RESOURCE_GROUP \
--location $AZ_LOCATION
```

```bash
az postgres flexible-server create \
--resource-group "$AZ_RESOURCE_GROUP" \
--location "$AZ_LOCATION" \
--name "$AZ_POSTGRES_SERVER_NAME" \
--database-name "$AZ_POSTGRES_DB_NAME" \
--admin-user "$AZ_POSTGRES_USERNAME" \
--admin-password "$AZ_POSTGRES_PASSWORD" \
--public-access "All" \
--tier "Burstable" \
--sku-name "Standard_B1ms" \
--storage-size 32 \
--version "16"
```

```bash
export POSTGRES_CONNECTION_STRING=$(
az postgres flexible-server show-connection-string \
--server-name "$AZ_POSTGRES_SERVER_NAME" \
--database-name "$AZ_POSTGRES_DB_NAME" \
--admin-user "$AZ_POSTGRES_USERNAME" \
--admin-password "$AZ_POSTGRES_PASSWORD" \
--query "connectionStrings.jdbc" \
--output tsv
)

export POSTGRES_CONNECTION_STRING_SSL="$POSTGRES_CONNECTION_STRING&ssl=true&sslmode=require"

echo "POSTGRES_CONNECTION_STRING_SSL=$POSTGRES_CONNECTION_STRING_SSL"

```

Update application.properties:
```bash
quarkus.hibernate-orm.database.generation=update
quarkus.datasource.jdbc.url=<the POSTGRES_CONNECTION_STRING_SSL value>
```

```bash
./mvnw clean quarkus:dev
```

```bash
curl --header "Content-Type: application/json" \
--request POST \
--data '{"description":"Take Quarkus MS Learn","details":"Take the MS Learn on deploying Quarkus to Azure Container Apps","done": "true"}' \
http://127.0.0.1:8080/api/todos
```

```json
{"id":1,"description":"Take Quarkus MS Learn","details":"Take the MS Learn on deploying Quarkus to Azure Container Apps","done":true,"createdAt":"2025-02-20T07:17:18.557979300Z"}
```

```bash
curl --header "Content-Type: application/json" \
--request POST \
--data '{"description":"Take Azure Container Apps MS Learn","details":"Take the ACA Learn module","done": "false"}' \
http://127.0.0.1:8080/api/todos
```

```bash
{"id":2,"description":"Take Azure Container Apps MS Learn","details":"Take the ACA Learn module","done":false,"createdAt":"2025-02-20T07:24:15.856728200Z"}
```

curl http://127.0.0.1:8080/api/todos

```json
[
  {"id":1,"description":"Take Quarkus MS Learn","details":"Take the MS Learn on deploying Quarkus to Azure Container Apps","done":true,"createdAt":"2025-02-20T07:17:18.557979Z"},
  {"id":2,"description":"Take Azure Container Apps MS Learn","details":"Take the ACA Learn module","done":false,"createdAt":"2025-02-20T07:24:15.856728Z"}
]
```
## Docker image

```bash
#maby not needed?
mv src/main/docker/Dockerfile.jvm ./Dockerfile
```

```bash
./mvnw package
```

build docker image with docker:
```bash
docker build -f src/main/docker/Dockerfile.jvm -t quarkus/todo-jvm .
```

To test docker img localy:
```bash
docker run -i --rm -p 8080:8080 quarkus/todo-jvm
```
And then the same as above to test image localy:
```bash
curl --header "Content-Type: application/json" \
--request POST \
--data '{"description":"Take Azure Container Apps MS Learn","details":"Take the ACA Learn module","done": "false"}' \
http://127.0.0.1:8080/api/todos
```

```bash
az containerapp up \
--name "$AZ_CONTAINERAPP" \
--environment "$AZ_CONTAINERAPP_ENV" \
--location "$AZ_LOCATION" \
--resource-group "$AZ_RESOURCE_GROUP" \
--ingress external \
--target-port 8080 \
--source .
```

```bash
Creating Containerapp caazure-deploy-quarkus in resource group rgazure-deploy-quarkus
Adding registry password as a secret with name "ca447790455dacrazurecrio-ca447790455dacr"

Container app created. Access your app at https://caazure-deploy-quarkus.lemonpond-b1c7e733.northeurope.azurecontainerapps.io/


Your container app caazure-deploy-quarkus has been created and deployed! Congrats!

Browse to your container app at: http://caazure-deploy-quarkus.lemonpond-b1c7e733.northeurope.azurecontainerapps.io 

Stream logs for your container with: az containerapp logs show -n caazure-deploy-quarkus -g rgazure-deploy-quarkus

See full output using: az containerapp show -n caazure-deploy-quarkus -g rgazure-deploy-quarkus
```

```bash
az resource list \
--location "$AZ_LOCATION" \
--resource-group "$AZ_RESOURCE_GROUP" \
--output table
```

## Run the deployed Quarkus application

```bash
export AZ_APP_URL=$(
az containerapp show \
--name "$AZ_CONTAINERAPP" \
--resource-group "$AZ_RESOURCE_GROUP" \
--query "properties.configuration.ingress.fqdn" \
--output tsv \
)
echo "AZ_APP_URL=$AZ_APP_URL"
echo $AZ_APP_URL
```



```bash
az containerapp show \
--name "$AZ_CONTAINERAPP" \
--resource-group "$AZ_RESOURCE_GROUP" \
--query "properties.configuration.ingress.fqdn" \
--output tsv

#results
caazure-deploy-quarkus.lemonpond-b1c7e733.northeurope.azurecontainerapps.io
```


```bash
curl --header "Content-Type: application/json" \
--request POST \
--data '{"description":"Configuration","details":"Congratulations, you have set up your Quarkus application correctly!","done": "true"}' \
https://${AZ_APP_URL}/api/todos
```
or
```bash
curl --header "Content-Type: application/json" \
--request POST \
--data '{"description":"Configuration","details":"Congratulations, you have set up your Quarkus application correctly!","done": "true"}' \
https://caazure-deploy-quarkus-next.bluebay-dd2fa345.northeurope.azurecontainerapps.io/api/todos
```

```json
{"id":151,"description":"Configuration","details":"Congratulations, you have set up your Quarkus application correctly!","done":true,"createdAt":"2025-02-21T12:02:18.843832915Z"}
```

```bash
curl https://$AZ_APP_URL/api/todos
curl https://caazure-deploy-quarkus-next.bluebay-dd2fa345.northeurope.azurecontainerapps.io/api/todos
```

```json
[
{"id":1,"description":"Take Quarkus MS Learn","details":"Take the MS Learn on deploying Quarkus to Azure Container Apps","done":true,"createdAt":"2025-02-21T11:35:31.998502Z"},
{"id":2,"description":"Take Azure Container Apps MS Learn","details":"Take the ACA Learn module","done":false,"createdAt":"2025-02-21T11:35:39.621552Z"},
{"id":51,"description":"Take Quarkus MS Learn","details":"Take the MS Learn on deploying Quarkus to Azure Container Apps","done":true,"createdAt":"2025-02-21T11:36:46.511545Z"},
{"id":101,"description":"Take Quarkus MS Learn","details":"Take the MS Learn on deploying Quarkus to Azure Container Apps","done":true,"createdAt":"2025-02-21T11:46:34.928328Z"},
{"id":102,"description":"Take Azure Container Apps MS Learn","details":"Take the ACA Learn module","done":false,"createdAt":"2025-02-21T11:46:35.320361Z"},
{"id":151,"description":"Configuration","details":"Congratulations, you have set up your Quarkus application correctly!","done":true,"createdAt":"2025-02-21T12:02:18.843833Z"}
]
```

```bash
#to update container with new build:
az containerapp up \
--name "$AZ_CONTAINERAPP" \
--environment "$AZ_CONTAINERAPP_ENV" \
--location "$AZ_LOCATION" \
--resource-group "$AZ_RESOURCE_GROUP" \
--ingress external \
--target-port 8080 \
--source .
```

## Access the PostgreSQL server by using the CLI
```bash
az postgres flexible-server execute \
--name "$AZ_POSTGRES_SERVER_NAME" \
--database-name "$AZ_POSTGRES_DB_NAME" \
--admin-user "$AZ_POSTGRES_USERNAME" \
--admin-password "$AZ_POSTGRES_PASSWORD" \
--querytext "select * from Todo" \
--output table
```

Preview version of extension is disabled by default for extension installation, enabled for modules without stable versions. 
Please run 'az config set extension.dynamic_install_allow_preview=true or false' to config it specifically.

## Remove the permissive firewall rule
```bash
az postgres flexible-server firewall-rule list \
--name "$AZ_POSTGRES_SERVER_NAME" \
--resource-group "$AZ_RESOURCE_GROUP" \
--output table

az postgres flexible-server firewall-rule delete \
--name "$AZ_POSTGRES_SERVER_NAME" \
--resource-group "$AZ_RESOURCE_GROUP" \
--rule-name AllowAll_2025-2-20_8-57-56 \
--yes
```
Shall timeout:
```bash
az postgres flexible-server execute \
--name "$AZ_POSTGRES_SERVER_NAME" \
--database-name "$AZ_POSTGRES_DB_NAME" \
--admin-user "$AZ_POSTGRES_USERNAME" \
--admin-password "$AZ_POSTGRES_PASSWORD" \
--querytext "select * from Todo" \
--output table
```

## Add a new firewall rule
```bash
az postgres flexible-server firewall-rule create \
--name "$AZ_POSTGRES_SERVER_NAME" \
--resource-group "$AZ_RESOURCE_GROUP" \
--rule-name "Allow_Azure-internal-IP-addresses" \
--start-ip-address "0.0.0.0" \
--end-ip-address "255.255.255.255"
#! NB Is obsolete
# --start-ip-address "0.0.0.0" \
# --end-ip-address "0.0.0.0"
#
```

```bash
az postgres flexible-server execute \
--name "$AZ_POSTGRES_SERVER_NAME" \
--database-name "$AZ_POSTGRES_DB_NAME" \
--admin-user "$AZ_POSTGRES_USERNAME" \
--admin-password "$AZ_POSTGRES_PASSWORD" \
--querytext "select * from Todo" \
--output table
```

Retest:
```bash
curl https://$AZ_APP_URL/api/todos
curl https://caazure-deploy-quarkus-next.bluebay-dd2fa345.northeurope.azurecontainerapps.io/api/todos
```

## clean up
```bash
az group delete \
--name $AZ_RESOURCE_GROUP \
--yes
```

