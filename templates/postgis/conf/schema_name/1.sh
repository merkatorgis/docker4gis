#!/bin/bash

schema=$(basename $(pwd))

pg.sh -c "
    create schema ${schema}
    ;
"
