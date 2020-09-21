# do replace latest with a proper tag
FROM docker4gis/postgis:latest

ENV POSTFIX_DOMAIN=template.example.com

# To create a mail box {login}@${POSTFIX_DOMAIN}:
RUN addmailbox.sh noreply 'Example.com Template Service'
