create table thing
    ( id serial primary key
    , role name not null default current_user references web.user(role)
    , what text not null
    , constraint role_what_key unique (role, what)
    )
;

alter table thing
enable row level security
;
grant all on thing
to web_user
;
grant usage, select on sequence thing_id_seq
to web_user
;

comment on table thing is
$$Just a thing

That is, a thing you can see, following the policy, based
on the role of the user you are logged in as.
$$;

comment on column thing.id is
$$The primary key
$$;

comment on column thing.role is
$$The web.user.role that owns this row
$$;

comment on column thing.what is
$$A description for the thing at hand
$$;
