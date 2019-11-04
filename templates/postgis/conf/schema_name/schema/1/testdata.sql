set search_path to schema_name, public
;

select * from schema_name.fn_new_user
    ( 'a@b.c'
    , true
    )
;

set session request.jwt.claim.email = 'a@b.c'
;
select * from schema_name.fn_save_password
    ( 'a@b.c'
    , 'abc'
    )
;

insert into schema_name.tbl_something
    ( naam
    )
values
    ( 'test'
    )
;
