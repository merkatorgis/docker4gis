#!/bin/bash

USER=$1

su -c 'echo n | mail' "$USER"
