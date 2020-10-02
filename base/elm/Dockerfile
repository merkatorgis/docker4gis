FROM docker4gis/serve:237
RUN rm -rf /wwwroot
# https://github.com/avh4/binwrap/issues/8#issuecomment-359075561
# (https://github.com/halfzebra/create-elm-app/issues/298#issuecomment-422897851)
# alternatively: RUN yarn global add create-elm-app@3.2.2
RUN npm config set -g user root
RUN npm install create-elm-app@3.2.2 -g
RUN npm update caniuse-lite browserslist
WORKDIR /elm
ONBUILD COPY . .
ONBUILD RUN if [ -d elm-stuff ]; then rm -rf elm-stuff; fi
ONBUILD RUN npm install
ONBUILD RUN elm-app build
