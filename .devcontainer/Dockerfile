# Use Debian as the base image (or Ubuntu)
FROM debian:latest

# Install required dependencies
RUN apt-get update && apt-get install -y \
    curl bash unzip git zsh software-properties-common lsb-release gnupg2 ca-certificates

# Add HashiCorp's official GPG key and repo
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

# Update package lists and install Terraform & AWS CLI
RUN apt-get update && apt-get install -y terraform awscli

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"