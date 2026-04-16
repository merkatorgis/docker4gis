#!/bin/bash

[ -n "$DEBUG" ] && set -x

environment=$1

# 0. Skip if already created.
existing_service_endpoint=$(az devops service-endpoint list \
    --output=tsv \
    --query "[?name=='$environment'].name")
if [ -n "$existing_service_endpoint" ]; then
    log "Service Connection $environment exists; skip creating Environment"
    exit 0
fi

set -e

# 1. Create service connections before environments, to prevent an exception
# about not having the privilege to create the service connection.

log Create SSH Service Connection "$environment"

subdomain=$environment
if [ "$environment" = TEST ]; then
    subdomain=tst
elif [ "$environment" = PRODUCTION ]; then
    subdomain=www
fi

echo "{
    \"data\": {
        \"Host\": \"$subdomain.$SYSTEM_TEAMPROJECT.com\",
        \"Port\": \"22\",
        \"PrivateKey\": null
    },
    \"name\": \"$environment\",
    \"type\": \"ssh\",
    \"authorization\": {
        \"parameters\": {
            \"username\": \"username\",
            \"password\": null
        },
        \"scheme\": \"UsernamePassword\"
    }
}" >./ssh_service_endpoint.json

response=$(az devops service-endpoint create \
    --service-endpoint-configuration ./ssh_service_endpoint.json)

bare_environment=$environment
for suffix in '' _SINGLE; do
    environment=$bare_environment$suffix

    # 2. Create the Environment.

    log Create pipeline Environment "$environment"

    environment_object=$(
        /devops/rest.sh project POST pipelines/environments '' "{
            \"name\": \"$environment\"
        }"
    )
    environment_id=$(node --print "($environment_object).id")

    if [ -z "$team_id" ]; then
        log Query id of "$SYSTEM_TEAMPROJECT Team" group
        team_id=$(az devops team list --query=[0].id --output tsv)
    fi

    # 3. Create the Approval check.

    log Create environment "$environment" Approval check

    response=$(/devops/rest.sh project POST pipelines/checks/configurations '' "{
        \"type\": {
            \"id\": \"8C6F20A7-A545-4486-9777-F762FAFE0D4D\",
            \"name\": \"Approval\"
        },
        \"resource\": {
            \"type\": \"environment\",
            \"id\": \"$environment_id\"
        },
        \"timeout\": 1,
        \"settings\": {
            \"approvers\": [
                {
                    \"id\": \"$team_id\"
                }
            ]
        }
    }")
done

# We use `response=$(...)` to prevent the resonse from being echoed to the
# console.
response=${response:-}
