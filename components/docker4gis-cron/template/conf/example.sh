#!/bin/bash

# Cron jobs are run by the runner plugin, which logs to a job-specific log file
# (a new file each day), including the start and end time of each script,
# prepended by the process id of the runner. It makes sense to include that
# "parent" id ($PPID) in the job's output, so that the log file shows which
# output came from which job instance.
echo "$PPID $(pg.sh -Atc 'select 1' 2>&1)"
