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

# Import the Docker GPG key.
# Add the Docker repository.
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | \
    gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list

# Update the package list.
# Install the Docker CLI.
# Verify Installation.
RUN apt-get update && \
    apt-get install -y docker-ce-cli && \
    docker --version

# Remove downloaded packages.
RUN apt-get clean

WORKDIR /devops
COPY conf/* .
ENTRYPOINT [ "/devops/entrypoint" ]
CMD [ "components" ]

ENV DOCKER4GIS_DEVOPS=true
ENV API_VERSION=7.1
