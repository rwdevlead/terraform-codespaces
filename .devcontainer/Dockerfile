FROM alpine:3.19

# Install base packages and AWS CLI dependencies
RUN apk add --no-cache \
    curl \
    python3 \
    py3-pip \
    git \
    unzip \
    bash

# Install AWS CLI
RUN pip3 install --no-cache-dir awscli

# Install Azure CLI
RUN pip3 install --no-cache-dir azure-cli --break-system-packages

# Install latest version of Terraform
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r '.tag_name' | sed 's/v//') && \
    wget -O terraform.zip "https://releases.hashicorp.com/terraform/${LATEST_VERSION}/terraform_${LATEST_VERSION}_linux_amd64.zip" && \
    unzip terraform.zip -d /usr/local/bin && \
    rm terraform.zip
    
WORKDIR /workspace
