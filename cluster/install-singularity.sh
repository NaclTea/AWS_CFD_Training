#!/bin/bash
# Install Singularity on cluster nodes

wget https://github.com/sylabs/singularity/releases/download/v3.11.4/singularity-ce-3.11.4-1.el7.x86_64.rpm
sudo yum install -y singularity-ce-3.11.4-1.el7.x86_64.rpm

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
BUCKET_NAME="openfoam-cluster-bootstrap-${ACCOUNT_ID}"

aws s3 mb s3://${BUCKET_NAME} --region eu-west-2
aws s3 cp ~/hpc-openfoam/cluster/install-singularity.sh s3://${BUCKET_NAME}/