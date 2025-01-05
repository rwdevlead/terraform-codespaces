# Dockerfile
FROM hashicorp/terraform:latest

# Install additional packages including git
RUN apk add --no-cache git zsh curl bash

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
