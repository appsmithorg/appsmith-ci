#!/usr/bin/env bash
set -o errexit

## Install relevant packages
sudo apt update -q && sudo apt install -y curl unzip less jq
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.23.6/bin/linux/amd64/kubectl && \
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
chmod 700 get_helm.sh; ./get_helm.sh

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

echo "Region: $region"
echo "Cluster name: $cluster_name"
echo "Pull Request Number: $PULL_REQUEST_NUMBER"

sts_output=$(aws sts assume-role --role-arn env.AWS_ROLE_ARN --role-session-name ekscisession)
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
