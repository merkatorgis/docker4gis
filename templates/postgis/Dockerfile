FROM docker4gis/postgis

ENV POSTFIX_DOMAIN=template.example.com

# To create a mail box login@${POSTFIX_DOMAIN}:
# RUN addmailbox.sh {login} 'Full Name', eg:
# RUN addmailbox.sh noreply 'Example.com Template Service'
RUN addmailbox.sh noreply 'Merkator DXF-service'
