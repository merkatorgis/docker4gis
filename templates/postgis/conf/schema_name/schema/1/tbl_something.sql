create table schema_name.tbl_something
    ( id serial primary key
    , name text not null unique
    )
;

grant select on schema_name.tbl_something to web_anon
;
