#!/bin/bash

image=docker4gis/maven

echo; echo "Building ${image}"

docker image build -t "${image}" .
