#!/bin/bash

# save a statement to run on db start, after all other config is done
echo "pushd $(pwd); $*; popd" >>/last
