create table things
    ( id serial primary key
    , web_user name not null default current_user references web.users(role)
    , what text not null
    , constraint things_web_user_naam_key unique (web_user, what)
    )
;

alter table things
enable row level security
;
grant all on things
to web_user
;
grant usage, select on sequence things_id_seq
to web_user
;
