#!/bin/bash

apk add --no-cache \
	expat zlib boost uriparser minizip unixodbc

apk add --no-cache --virtual .build-deps \
	make cmake g++ \
	expat-dev zlib-dev boost-dev uriparser-dev minizip-dev unixodbc-dev
