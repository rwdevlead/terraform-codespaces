FROM rockylinux:9-minimal

# Install required packages
RUN microdnf install -y \
    python3-pip \
    unzip \
    git \
    curl \
    jq \
    && microdnf clean all

# Install AWS CLI
RUN pip3 install --no-cache-dir awscli

# Install Azure CLI
RUN pip3 install --no-cache-dir azure-cli

# Install latest version of Terraform
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r '.tag_name' | sed 's/v//') && \
    curl -O "https://releases.hashicorp.com/terraform/${LATEST_VERSION}/terraform_${LATEST_VERSION}_linux_amd64.zip" && \
    unzip terraform_${LATEST_VERSION}_linux_amd64.zip -d /usr/local/bin && \
    rm terraform_${LATEST_VERSION}_linux_amd64.zip

WORKDIR /workspace
