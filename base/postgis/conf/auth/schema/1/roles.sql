create role authenticator noinherit login password 'postgrest';
create role web_anon nologin;
grant web_anon to authenticator;
