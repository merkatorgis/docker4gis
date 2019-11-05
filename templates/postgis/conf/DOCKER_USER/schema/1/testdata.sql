select fn_new_user
    ( 'a@b.c'
    , true
    )
;

set session request.jwt.claim.email = 'a@b.c'
;
select 'curl https://localhost.merkator.com:7443/postgrest/tbl_thing -H "Authorization: Bearer '
    || (select * from fn_save_password
        ( 'a@b.c'
        , 'abc'
        ))
    || '"'
;

insert into tbl_thing
    ( web_user
    , what
    )
values
    ( 'web_user1'
    , 'test'
    )
;

insert into tbl_thing
    ( web_user
    , what
    )
values
    ( 'web_user1'
    , 'test2'
    )
;



select fn_new_user
    ( 'aa@bb.cc'
    , true
    )
;

set session request.jwt.claim.email = 'aa@bb.cc'
;
select 'curl https://localhost.merkator.com:7443/postgrest/tbl_thing -H "Authorization: Bearer '
    || (select * from fn_save_password
        ( 'aa@bb.cc'
        , 'aabbcc'
        ))
    || '"'
;

insert into tbl_thing
    ( web_user
    , what
    )
values
    ( 'web_user2'
    , 'test'
    )
;

insert into tbl_thing
    ( web_user
    , what
    )
values
    ( 'web_user2'
    , 'test2'
    )
;
