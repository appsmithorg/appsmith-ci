#!/usr/bin/env bash
set -o errexit

mkdir ~/.aws; touch ~/.aws/config

echo "[default]
aws_access_key_id = AKIAVWHAAGIQOE7O4O5N
aws_secret_access_key = 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" > ~/.aws/credentials

echo "[default]
[profile eksci]
role_arn= $AWS_ROLE_ARN
output = json
region=ap-south-1
source_profile = default" > ~/.aws/config

export region=ap-south-1
export cluster_name=uat-cluster

echo "Region: $region"
echo "Cluster name: $cluster_name"

cat ~/.aws/credentials

sts_output=$(aws sts assume-role --role-arn "arn:aws:iam::391311798816:role/eksadmin" --role-session-name ekscisession)
 
echo $sts_output

export AWS_ACCESS_KEY_ID=$(echo $sts_output | jq -r '.Credentials''.AccessKeyId');\
export AWS_SECRET_ACCESS_KEY=$(echo $sts_output | jq -r '.Credentials''.SecretAccessKey');\
export AWS_SESSION_TOKEN=$(echo $sts_output | jq -r '.Credentials''.SessionToken');

aws eks update-kubeconfig --region $region --name $cluster_name --profile eksci

### Get list of helm charts

deployed_charts=$(helm ls -A | grep ce | awk '{print $2}')

for i in $deployed_charts
  do 
    pr=$(echo $i | cut -c 3-);
    pr_status_output=$(gh pr view $pr --json state)
    pr_state=$(echo $pr_status_output | jq -r 'values[]');
    echo $pr_state
  done
