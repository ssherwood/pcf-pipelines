#!/bin/bash

set -eu

export OPSMAN_DOMAIN_OR_IP_ADDRESS="opsman.$PCF_ERT_DOMAIN"

source pcf-pipelines/functions/generate_cert.sh

function isPopulated() {
    local true=0
    local false=1
    local envVar="${1}"

    if [[ "${envVar}" == "" ]]; then
        return ${false}
    elif [[ "${envVar}" == null ]]; then
        return ${false}
    else
        return ${true}
    fi
}

# TODO this is clearly hard coded to GCP

product_properties=$(
  jq -n \
    --arg azs "$DEPLOYMENT_NW_AZS" \
    --arg gcp_project_id "$GCP_PROJECT_ID" \
    --arg gcp_vpc_name "$GCP_VPC_NAME" \
    --arg gcp_master_account "$GCP_MASTER_ACCOUNT" \
    --arg gcp_worker_account "$GCP_WORKER_ACCOUNT" \
    '
    {
        ".properties.cloud_provider": { "value": "GCP" },
        ".properties.cloud_provider.gcp.project_id": { "value": $gcp_project_id },
        ".properties.cloud_provider.gcp.network": { "value": $gcp_vpc_name },
        ".properties.cloud_provider.gcp.master_service_account": { "value": $gcp_master_account },
        ".properties.cloud_provider.gcp.worker_service_account": { "value": $gcp_worker_account },
    }
    '
)

product_network=$(
  jq -n \
    --arg network_name "$NETWORK_NAME" \
    --arg other_azs "$DEPLOYMENT_NW_AZS" \
    --arg singleton_az "$SINGLETON_JOB_AZ" \
    '
    {
      "network": {
        "name": $network_name
      },
      "service_network": {
        "name": $network_name
      },
      "other_availability_zones": ($other_azs | split(",") | map({name: .})),
      "singleton_availability_zone": {
        "name": $singleton_az
      }
    }
    '
)

product_resources=$(
  jq -n \
    '
    { }
    '
)

echo $product_properties
echo $product_network
echo $product_resources
echo $product_properties >> configuration/product_properties
echo $product_network >> configuration/product_network
echo $product_resources >> configuration/product_resources