#!/bin/bash

apk add --upgrade apk-tools

TESTING='http://dl-cdn.alpinelinux.org/alpine/edge/testing'

apk update --repository "$TESTING"
apk add --repository "$TESTING" postgis
