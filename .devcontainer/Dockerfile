FROM almalinux:9

# Install EPEL repository and base dependencies
RUN dnf install -y epel-release && \
    dnf install -y \
    unzip \
    git \
    python3-pip \
    && dnf clean all

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Install Microsoft repository and Azure CLI
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm && \
    dnf install -y azure-cli && \
    dnf clean all

# Create workspace directory
WORKDIR /workspace
