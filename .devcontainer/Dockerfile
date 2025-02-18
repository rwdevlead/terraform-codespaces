# Use Ubuntu as the base image
FROM ubuntu:latest

# Install required dependencies
RUN apt-get update && apt-get install -y \
    curl bash unzip git zsh software-properties-common \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update && apt-get install -y terraform awscli \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
