#!/bin/bash
# Generates cluster config from template and deploys AWS ParallelCluster

# VARIABLES
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
BUCKET_NAME="openfoam-cluster-bootstrap-${ACCOUNT_ID}"

# DISCOVER SUBNETS
SUBNET_B=$(aws ec2 describe-subnets --query 'Subnets[?AvailabilityZone==`eu-west-2b`&&DefaultForAz==`true`].SubnetId' --output text)
SUBNET_C=$(aws ec2 describe-subnets --query 'Subnets[?AvailabilityZone==`eu-west-2c`&&DefaultForAz==`true`].SubnetId' --output text)
SUBNET_A=$(aws ec2 describe-subnets --query 'Subnets[?AvailabilityZone==`eu-west-2a`&&DefaultForAz==`true`].SubnetId' --output text)

# GENERATE CONFIG FROM TEMPLATE
sed "s/ACCOUNT_ID_PLACEHOLDER/${ACCOUNT_ID}/g;
     s/HEAD_NODE_SUBNET_PLACEHOLDER/${SUBNET_B}/g;
     s/SUBNET_AZ_B_PLACEHOLDER/${SUBNET_B}/g;
     s/SUBNET_AZ_C_PLACEHOLDER/${SUBNET_C}/g;
     s/SUBNET_AZ_A_PLACEHOLDER/${SUBNET_A}/g" \
    cluster/cluster-config-template.yaml > cluster/cluster-config.yaml

echo "Generated cluster-config.yaml"

# UPLOAD BOOTSTRAP SCRIPT
aws s3 mb s3://${BUCKET_NAME} --region eu-west-2 2>/dev/null || true
aws s3 cp cluster/install-singularity.sh s3://${BUCKET_NAME}/

# DEPLOY cluster
pcluster create-cluster \
    --cluster-name openfoam-cluster \
    --cluster-configuration cluster/cluster-config.yaml