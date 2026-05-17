#!/bin/bash
# setup-aws.sh
# Prerequisites for deploying an AWS ParallelCluster from WSL (Ubuntu).
# Run this script section by section.



# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# Might need to fix network settings for WSL:
# ping 8.8.8.8
# curl -I https://google.com
# sudo rm /etc/resolv.conf
# echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
# sudo chattr +i /etc/resolv.conf
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Continue installing AWS CLI
unzip awscliv2.zip
sudo ./aws/install
aws --version

# Install Python 3.10 for pcluster compatibility (Amazon Liunux 2 ships with 3.7)
sudo apt update && sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.10 python3.10-venv python3.10-distutils
python3.10 --version

# Create venv
mkdir -p ~/AWS_CFD && cd ~/AWS_CFD
python3.10 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip

# Install pcluster
pip install aws-parallelcluster
pcluster version

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Configure AWS connection
# If you don't have an AWS account, create one at https://aws.amazon.com.
# Once in the console, create an IAM user with programmatic access rather than using your root account:

# Go to IAM → Users → Create user
# Name it parallelcluster-admin
# Attach policy: AdministratorAccess
# Go to Security credentials → Create access key (choose "CLI" use case)
# Download the .csv — you need the Access Key ID and Secret Access Key

# Request quota increase on AWS
aws service-quotas request-service-quota-increase \
  --region eu-west-2 \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 132
#Webpage:
# https://console.aws.amazon.com/servicequotas/home/services/ec2/quotas/
# Search for: Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances
# Request quota increase → set value to 132 → Submit

# Create a new CLI access key for the parallelcluster-admin IAM. Take note of
# the acccess key ID and secret key. Enter them in the aws configure menu.
aws configure
aws sts get-caller-identity # Verify it works

# Setup SSH
aws ec2 create-key-pair --key-name cfd-cluster-key \
  --query 'KeyMaterial' --output text > ~/.ssh/cfd-cluster-key.pem # Create an SSH key.
chmod 400 cfd-cluster-key.pem # Change permissions for the key.