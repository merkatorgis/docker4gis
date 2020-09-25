#!/bin/bash

GLIBC_VERSION=${GLIBC_VERSION:-2.27-r0}

wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub

wget "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk"
wget "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk"
wget "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk"

apk add "glibc-${GLIBC_VERSION}.apk" "glibc-bin-${GLIBC_VERSION}.apk" "glibc-i18n-${GLIBC_VERSION}.apk"

rm -f /etc/apk/keys/sgerrand.rsa.pub "glibc-${GLIBC_VERSION}.apk" "glibc-bin-${GLIBC_VERSION}.apk" "glibc-i18n-${GLIBC_VERSION}.apk"

echo 'example:'
echo '    /usr/glibc-compat/bin/localedef -i nl_NL -f CP1252 nl_NL.cp1252'
echo '    export LANG=nl_NL.cp1252'
