FROM docker4gis/postgis:11

ENV POSTFIX_DOMAIN=template.example.com

# To create a mail box {login}@${POSTFIX_DOMAIN}:
RUN addmailbox.sh noreply 'Example.com Template Service'
