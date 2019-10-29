#!/bin/bash

pg.sh -c "create schema auth"

schema.sh $(dirname "$0")
