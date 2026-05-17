#!/bin/bash
set -e # Fail on any error

# Install Singularity CE on Amazon Linux 2
SINGULARITY_VERSION="3.11.4"

wget https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}-1.el7.x86_64.rpm
sudo yum install -y singularity-ce-${SINGULARITY_VERSION}-1.el7.x86_64.rpm
rm -f singularity-ce-${SINGULARITY_VERSION}-1.el7.x86_64.rpm

# Verify installation
singularity --version