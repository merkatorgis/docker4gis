-- Forward-only resync of owned integer-id sequences across all user schemas.
--
-- Reference/library tables are seeded by DDL migrations with explicit ids, so
-- their identity sequences are never advanced by nextval() and end up behind
-- max(id). The next insert that relies on the sequence default then collides on
-- the primary key.
--
-- The base postgis-ddl image runs this on every deploy from onstart.sh, both
-- before and after the schema migrations (before: so each migration's seed
-- inserts cleanly over lag left by an earlier deploy; after: to catch lag
-- introduced by this deploy's seeds). For each sequence owned by an integer id
-- column it compares the next value nextval() would produce against the
-- column's max(id), and ONLY advances a sequence that is lagging (next <= max).
-- It NEVER moves a sequence backwards, so it is:
--   * safe on a live database (an "ahead" sequence is left untouched), and
--   * idempotent (re-running changes nothing once everything is aligned).
--
-- All schemas are covered except PostgreSQL's own (pg_*) and information_schema;
-- the forward-only logic is safe everywhere, so no schema list is needed.
DO $$
DECLARE
    r        record;
    v_max    bigint;
    v_last   bigint;
    v_called boolean;
    v_next   bigint;
    v_fixed  int := 0;
BEGIN
    FOR r IN
        SELECT nt.nspname AS tbl_schema, t.relname AS tbl_name, a.attname AS col_name,
               ns.nspname AS seq_schema, s.relname AS seq_name
        FROM pg_class s
        JOIN pg_namespace ns ON ns.oid = s.relnamespace
        JOIN pg_depend d
            ON d.objid = s.oid
           AND d.classid = 'pg_class'::regclass
           AND d.refclassid = 'pg_class'::regclass
           AND d.deptype IN ('a', 'i')                  -- auto / internal (owned-by)
        JOIN pg_class t      ON t.oid = d.refobjid AND t.relkind IN ('r', 'p')
        JOIN pg_namespace nt ON nt.oid = t.relnamespace
        JOIN pg_attribute a  ON a.attrelid = t.oid AND a.attnum = d.refobjsubid
        JOIN pg_type ty      ON ty.oid = a.atttypid
        WHERE s.relkind = 'S'
          AND nt.nspname NOT LIKE 'pg\_%'                -- skip PostgreSQL schemas
          AND nt.nspname <> 'information_schema'
          AND ty.typname IN ('int2', 'int4', 'int8')     -- only integer id columns
        ORDER BY 1, 2
    LOOP
        EXECUTE format('SELECT max(%I) FROM %I.%I', r.col_name, r.tbl_schema, r.tbl_name)
            INTO v_max;
        CONTINUE WHEN v_max IS NULL;                      -- empty table, nothing to do

        EXECUTE format('SELECT last_value, is_called FROM %I.%I', r.seq_schema, r.seq_name)
            INTO v_last, v_called;
        v_next := CASE WHEN v_called THEN v_last + 1 ELSE v_last END;

        IF v_next <= v_max THEN                           -- lagging: would collide
            PERFORM setval(format('%I.%I', r.seq_schema, r.seq_name)::regclass, v_max, true);
            RAISE NOTICE 'resynced %.%: next % -> %  (max id %)',
                r.seq_schema, r.seq_name, v_next, v_max + 1, v_max;
            v_fixed := v_fixed + 1;
        END IF;
    END LOOP;

    RAISE NOTICE 'resync_sequences: % sequence(s) advanced', v_fixed;
END $$;
