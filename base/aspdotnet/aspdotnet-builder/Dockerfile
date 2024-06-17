# https://code.visualstudio.com/docs/containers/quickstart-aspnet-core

# Learn about building .NET container images:
# https://hub.docker.com/_/microsoft-dotnet-aspnet/
# https://github.com/dotnet/dotnet-docker/blob/main/samples/aspnetapp/Dockerfile.chiseled-composite
FROM mcr.microsoft.com/dotnet/sdk:8.0.203-jammy
WORKDIR /source

# Expected directory structure:
# ./<solution name>.sln
# ./<project_1 name>/<project_1 name>.csproj
# [./<project_... name>/<project_... name>.csproj]
# [./<project_n name>/<project_n name>.csproj]

# copy csproj and restore as distinct docker image layers
ONBUILD COPY */*.csproj .
ONBUILD RUN for csproj in *.csproj; do \
    dir=$(basename "$csproj" .csproj); \
    mkdir "$dir"; \
    mv "$csproj" "$dir"; \
    dotnet restore "$dir"; \
    done

# copy everything else and build app
ONBUILD COPY . .
ONBUILD RUN dotnet publish --no-restore --property:PublishDir=/app
