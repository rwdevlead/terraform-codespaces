FROM btkrausen/terraform-tools:latest

# Install HashiCorp GPG key and repository
RUN rpm --import https://rpm.releases.hashicorp.com/gpg && \
    dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

WORKDIR /workspace