FROM docker4gis/cron:v0.0.9

RUN cron.sh '* * * * *' /tmp/conf/example.sh

# To create a mail box {login}@${POSTFIX_DOMAIN}:
# RUN addmailbox.sh {login} 'Full Name'
