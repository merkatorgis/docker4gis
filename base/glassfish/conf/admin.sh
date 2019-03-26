#!/bin/bash


ADMIN_USER=admin
ADMIN_PASSWORD=adminadmin

echo 'AS_ADMIN_PASSWORD=' > /opt/passwordfile
echo "AS_ADMIN_NEWPASSWORD=${ADMIN_PASSWORD}" >> /opt/passwordfile
asadmin --user "${ADMIN_USER}" --passwordfile /opt/passwordfile \
    change-admin-password

echo "AS_ADMIN_PASSWORD=${ADMIN_PASSWORD}" > /opt/passwordfile
asadmin --user "${ADMIN_USER}" --passwordfile /opt/passwordfile \
    enable-secure-admin

asadmin --user "${ADMIN_USER}" --passwordfile /opt/passwordfile \
    create-jvm-options -Dcom.sun.net.ssl.enableECC=false

# cleanup
rm /opt/passwordfile "${0}"
