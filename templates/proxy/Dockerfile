FROM docker4gis/proxy:487

# These default values are overwritten by run time environment values, if set:
ENV API="http://$DOCKER_USER-api:8080/"
# Where to ask for authorisation
ENV AUTH_PATH="http://$DOCKER_USER-api:8080/rpc/auth_path"
ENV APP="http://$DOCKER_USER-app/"
ENV HOMEDEST="/$DOCKER_USER/app/"
