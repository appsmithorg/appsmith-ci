#!/bin/bash
# Configure the AWS & kubectl environment

set -o errexit
set -o nounset

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

export AWS_REGION=ap-south-1
export AWS_DEFAULT_OUTPUT=json

export cluster_name=uat-cluster

sts_output=$(aws sts assume-role --role-arn "$AWS_ROLE_ARN" --role-session-name dp-session-script)

export AWS_ACCESS_KEY_ID="$(echo "$sts_output" | jq -r '.Credentials.AccessKeyId')"
export AWS_SECRET_ACCESS_KEY="$(echo "$sts_output" | jq -r '.Credentials.SecretAccessKey')"
export AWS_SESSION_TOKEN="$(echo "$sts_output" | jq -r '.Credentials.SessionToken')"

export KUBECONFIG="$PWD/kubeconfig"
aws eks update-kubeconfig --name "$cluster_name" --role-arn "$AWS_ROLE_ARN"

### Get list of helm charts
deployed_charts="$(helm ls -A --filter 'ce[0-9]+' --output json | jq -r '.[].namespace')"

for i in $deployed_charts
  do 
    pr=$(echo $i | cut -c 3-);
    pr_status="$(gh pr view "$pr" --json state --jq .state)"
    echo $pr_state
    if [[ $pr_state == "MERGED" ]]
    then
      echo "helm uninstall $i -n $i"
      kubectl delete ns $NAMESPACE || echo "true"
      echo mongosh "mongodb+srv://$DB_USERNAME:$DB_PASSWORD@$DB_URL/$i?retryWrites=true&minPoolSize=1&maxPoolSize=10&maxIdleTimeMS=900000&authSource=admin" --eval 'db.dropDatabase()'
    fi
  done
