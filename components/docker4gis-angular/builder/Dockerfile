FROM node:22.12.0-bookworm

# The source directory is given as a build argument.
ONBUILD ARG SRC
ONBUILD ENV SRC=$SRC

WORKDIR /src

# Install dependencies.
ONBUILD COPY $SRC/package.json $SRC/package-lock.json ./
ONBUILD RUN npm ci

# Build the application.
ONBUILD COPY $SRC .
ONBUILD RUN npm run build

# Write the build output to the destination directory.
COPY write_build.sh .
ENV BUILD_DESTINATION=/build
ONBUILD RUN ./write_build.sh
