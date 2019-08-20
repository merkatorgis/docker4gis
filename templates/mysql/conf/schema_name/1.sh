#!/bin/bash

schema=$(basename $(pwd))

mysql.sh "${schema}" -e "
    select 1 
    ;
"
