#!/bin/bash
# Configure the AWS & kubectl environment

mkdir ~/.aws; touch ~/.aws/config

echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" > ~/.aws/credentials

echo "[default]
[profile eksci]
role_arn= $AWS_ROLE_ARN
output = json
region=ap-south-1
source_profile = default" > ~/.aws/config

export region=ap-south-1
export cluster_name=uat-cluster

sts_output=$(aws sts assume-role --role-arn env.AWS_ROLE_ARN --role-session-name dpcleanupsession)
export AWS_ACCESS_KEY_ID="$(echo "$sts_output" | jq -r '.Credentials.AccessKeyId')"
export AWS_SECRET_ACCESS_KEY="$(echo "$sts_output" | jq -r '.Credentials.SecretAccessKey')"
export AWS_SESSION_TOKEN="$(echo "$sts_output" | jq -r '.Credentials.SessionToken')"

aws eks update-kubeconfig --region $region --name uat-cluster --profile eksci

echo "Set the default namespace"
kubectl config set-context --current --namespace=default

echo "Getting the pods"
kubectl get pods -A

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
      echo kubectl delete ns $i || echo "true"
      echo mongosh "mongodb+srv://$DB_USERNAME:$DB_PASSWORD@$DB_URL/$i?retryWrites=true&minPoolSize=1&maxPoolSize=10&maxIdleTimeMS=900000&authSource=admin" --eval 'db.dropDatabase()'
    fi
  done
