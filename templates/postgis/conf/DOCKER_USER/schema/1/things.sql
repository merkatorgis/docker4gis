create table things
    ( id   serial primary key
    , role name not null default current_user references web.users(role)
    , what text not null
    , constraint things_role_what_key unique (role, what)
    );

alter table things
enable row level security
;

grant all on things
to web_user
;

grant usage, select on sequence things_id_seq
to web_user
;

create policy things_web_user on things to web_user
using
    (role = current_user)
with check
    (role = current_user)
;

comment on table things is
$$Just a bunch of things.
i.e. things you can see, following the policy, based on the role of the
user you are logged in as.
$$;

comment on column things.id is
$$This row's serial number.
$$;

comment on column things.role is
$$The web.users.role that owns this row.
$$;

comment on column things.what is
$$A description for the thing at hand.
$$;
