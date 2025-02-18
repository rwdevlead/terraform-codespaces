# Dockerfile
FROM hashicorp/terraform:latest


# Install dependencies for AWS CLI and Azure CLI
RUN apk add --no-cache git zsh curl bash unzip aws-cli python3 py3-pip

# Allow pip to install packages by disabling the externally managed environment restriction
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# Install Azure CLI via pip
RUN pip install --no-cache-dir azure-cli

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
