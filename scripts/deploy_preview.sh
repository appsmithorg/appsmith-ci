#!/bin/bash
# Params are in environment variables as PARAM_{SLUG}, e.g. PARAM_USER_ID

# Configure the AWS & kubectl environment

mkdir ~/.aws; touch ~/.aws/config

echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" > ~/.aws/credentials

echo "[default]
[profile eksadmin]
role_arn= $AWS_ROLE_ARN
output = json
region=ap-south-1
source_profile = default" > ~/.aws/config

export region=ap-south-1
export cluster_name=uat-cluster

echo "Region: $region"
echo "Cluster name: $cluster_name"

sts_output=$(aws sts assume-role --role-arn env.AWS_ROLE_ARN --role-session-name eksadminsession)
export AWS_ACCESS_KEY_ID=$(echo $sts_output | jq -r '.Credentials''.AccessKeyId');\
export AWS_SECRET_ACCESS_KEY=$(echo $sts_output | jq -r '.Credentials''.SecretAccessKey');\
export AWS_SESSION_TOKEN=$(echo $sts_output | jq -r '.Credentials''.SessionToken');

aws eks update-kubeconfig --region $region --name $cluster_name --profile eksadmin

echo "Set the default namespace"
kubectl config set-context --current --namespace=default

echo "Getting the pods"
kubectl get pods

echo "Delete previously created namespace"
kubectl delete ns $IMAGE_HASH || echo "true"

echo "Use kubernetes secret to Pull Image"
kubectl create ns $IMAGE_HASH
kubectl create secret docker-registry $IMAGE_HASH \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=$DOCKER_HUB_USERNAME \
  --docker-password=$DOCKER_HUB_ACCESS_TOKEN -n $IMAGE_HASH

echo "Add appsmith-ce to helm repo"
AWS_REGION=ap-south-1 helm repo add appsmith http://helm.appsmith.com

echo "Deploy appsmith helm chart"
helm install appsmith/appsmith --generate-name -n $IMAGE_HASH \
  --create-namespace --set image.repository=$DOCKER_HUB_ORGANIZATION/appsmith-ce --set image.tag=$IMAGE_HASH \
  --set image.pullSecrets=$IMAGE_HASH --set redis.enabled=false --set mongodb.enabled=false --set ingress.enabled=true \
  --set "ingress.annotations.service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert=$AWS_RELEASE_CERT" \
  --set "ingress.hosts[0].host=$IMAGE_HASH.appsmith.com, ingress.hosts[0].paths[0].path=/, ingress.hosts[0].paths[0].pathType=Prefix" \
  --set ingress.className="nginx" --version 2.0.1
