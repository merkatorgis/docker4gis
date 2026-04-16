grant execute on function save_password
    ( citext
    , text
    )
to web_passwd
;

comment on function save_password is
$$Store a new password using the token emailed by change_password.
Any tokens existing for this user get invalidated.
$$;
