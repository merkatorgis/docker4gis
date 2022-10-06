FROM node:16.17.1
# https://github.com/avh4/binwrap/issues/8#issuecomment-359075561
# (https://github.com/halfzebra/create-elm-app/issues/298#issuecomment-422897851)
# alternatively: RUN yarn global add create-elm-app@5.22.0
RUN npm config set -g user root
RUN npm install create-elm-app@5.22.0 -g
WORKDIR /elm
ONBUILD COPY . .
ONBUILD RUN npm update caniuse-lite browserslist
ONBUILD RUN rm -rf elm-stuff || true
ONBUILD RUN npm install
ONBUILD RUN elm-app build
