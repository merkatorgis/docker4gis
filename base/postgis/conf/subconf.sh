#!/bin/bash

conf=$1

pushd $(dirname "${conf}")
	"${conf}"
popd
