select new_user
    ( 'a@b.c'
    , true
    );

set session request.jwt.claim.email = 'a@b.c';
select save_password
    ( 'a@b.c'
    , 'abc'
    );

insert into things
    ( role
    , what
    )
values
    ( 'web_user1'
    , 'test1'
    );

insert into things
    ( role
    , what
    )
values
    ( 'web_user1'
    , 'test2'
    );



select new_user
    ( 'aa@bb.cc'
    , true
    );

set session request.jwt.claim.email = 'aa@bb.cc';
select save_password
    ( 'aa@bb.cc'
    , 'aabbcc'
    );

insert into things
    ( role
    , what
    )
values
    ( 'web_user2'
    , 'test3'
    );

insert into things
    ( role
    , what
    )
values
    ( 'web_user2'
    , 'test4'
    );
