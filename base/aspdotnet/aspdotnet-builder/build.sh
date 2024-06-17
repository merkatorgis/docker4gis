#!/bin/bash

IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}

docker image build \
    -t "$IMAGE" .
