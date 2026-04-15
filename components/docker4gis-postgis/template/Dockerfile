# check=skip=SecretsUsedInArgOrEnv

FROM docker4gis/postgis:v0.0.44-17-3.5

ENV POSTFIX_DOMAIN=template.example.com

# To create a mail box {login}@${POSTFIX_DOMAIN}:
# RUN addmailbox.sh {login} 'Full Name'
RUN addmailbox.sh noreply 'Example.com Template Service'

# The following schemas are skipped on `dump` or `upgrade`; use `dump_schema`
# and `restore_schema` for those. For syntax, see
# https://www.postgresql.org/docs/current/app-psql.html#APP-PSQL-PATTERNS.
ENV EXCLUDE_SCHEMA=(tiger|tiger_data|topology)

# Optionally include dump files in this directory to kickstart an empty database
# instead of fully building it from the ddl scripts.
COPY conf/snapshot /snapshot

