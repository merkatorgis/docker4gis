create role authenticator noinherit login password 'postgrest';

create role web_anon nologin;
grant web_anon to authenticator;

create role change_password nologin;
grant change_password to authenticator;

create role users nologin;

create role administrators nologin;
grant users to administrators;
