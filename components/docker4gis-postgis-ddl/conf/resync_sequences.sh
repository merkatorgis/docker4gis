#!/bin/bash

# Forward-only, idempotent resync of owned integer-id sequences across all user
# schemas. See /resync_sequences.sql for the rationale and the safety
# guarantees. Provided by the base postgis-ddl image and run automatically by
# onstart.sh (before and after the schema migrations); extension conf.sh
# scripts may also call it explicitly.
echo resync_sequences: &&
    pg.sh -f /resync_sequences.sql
