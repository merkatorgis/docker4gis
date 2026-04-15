FROM docker4gis/postfix:v0.0.7

ENV DESTINATION=example.com
# And/or set ${DOCKER_USER}_POSTFIX_DESTINATION at run time

# To create a mail box login@destination:
# RUN addmailbox.sh {login} 'Full Name'

# To process incoming mail by a script:
# COPY conf/script_name.sh /
# RUN api.sh {login} /script_name.sh param1 param2

# /onstart, if present, is sourced by /entrypoint on container start.
# COPY conf/onstart /
