#!/bin/bash

pfxpath="$1"
crtname="${2:-$(basename ${pfxpath%.*})}"

if [ ! -f "$pfxpath" ];
then
  echo "Cannot find PFX using path '$pfxpath'"
  exit 1
fi

domaincacrtpath=`mktemp`
domaincrtpath=`mktemp`
fullcrtpath=`mktemp`
keypath=`mktemp`

read -s -p "PFX password: " pfxpass

echo "Creating .CRT file"
openssl pkcs12 -in $pfxpath -out $domaincacrtpath -nodes -nokeys -cacerts -passin "pass:$pfxpass"
openssl pkcs12 -in $pfxpath -out $domaincrtpath -nokeys -clcerts -passin "pass:$pfxpass"
cat $domaincrtpath $domaincacrtpath > $fullcrtpath
rm $domaincrtpath $domaincacrtpath

echo "Creating .KEY file"
openssl pkcs12 -in $pfxpath -nocerts -passin "pass:$pfxpass" -passout pass:Password123 \
| openssl rsa -out $keypath -passin pass:Password123

mv $fullcrtpath ./${crtname}.crt
mv $keypath ./${crtname}.key

ls -l ${crtname}.crt ${crtname}.key
