FROM node:22.12.0-bookworm

# Update System Packages.
# Install Prerequisites.
RUN apt update && apt upgrade -y && \
    apt install -y ca-certificates curl apt-transport-https lsb-release gnupg

# Import the Microsoft GPG key.
# Add the Azure CLI repository.
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    tee /usr/share/keyrings/microsoft.gpg > /dev/null && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/azure-cli.list

# Update the package list.
# Install the Azure CLI.
# Verify Installation.
RUN apt update && \
    apt install -y azure-cli && \
    az --version

# Use the Azure CLI to add the Azure DevOps extension.
# Verify the DevOps extension is installed.
RUN az extension add --name azure-devops && \
    az devops --help

WORKDIR /devops
COPY conf/* .
ENTRYPOINT [ "/devops/entrypoint" ]

ENV API_VERSION=7.1
