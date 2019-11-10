create role web_authenticator noinherit login
password 'postgrest'
;

create role web_anon nologin
;
grant web_anon to web_authenticator
;

create role web_passwd nologin
;
grant web_passwd to web_authenticator
;

create role web_user nologin
;
grant web_user to web_authenticator
;
grant usage on schema web to web_user
;

create role web_admin nologin
;
grant web_user to web_admin
;
