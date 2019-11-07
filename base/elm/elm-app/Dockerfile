FROM node:11.3.0

# https://github.com/avh4/binwrap/issues/8#issuecomment-359075561
# (https://github.com/halfzebra/create-elm-app/issues/298#issuecomment-422897851)
RUN npm config set -g user root
RUN npm install create-elm-app -g
RUN npm update caniuse-lite browserslist

ONBUILD ADD . /app
ONBUILD RUN rm -rf /app/elm-stuff

WORKDIR /app
ENTRYPOINT [ "elm-app" ]
CMD [ "build" ]
