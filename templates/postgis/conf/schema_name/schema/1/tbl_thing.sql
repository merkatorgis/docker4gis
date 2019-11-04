create table schema_name.tbl_thing
    ( id serial primary key
    , web_user name not null default current_user references web.tbl_user(role)
    , naam text not null
    )
;

alter table schema_name.tbl_thing
enable row level security
;
grant select, insert on schema_name.tbl_thing
to web_user
;
grant usage, select on sequence schema_name.tbl_thing_id_seq
to web_user
;
