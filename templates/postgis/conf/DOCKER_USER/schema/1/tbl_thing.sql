create table tbl_thing
    ( id serial primary key
    , web_user name not null default current_user references web.tbl_user(role)
    , what text not null
    , constraint tbl_thing_web_user_naam_key unique (web_user, what)
    )
;

alter table tbl_thing
enable row level security
;
grant select, insert on tbl_thing
to web_user
;
grant usage, select on sequence tbl_thing_id_seq
to web_user
;
