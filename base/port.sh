#!/bin/bash

host_port=$1
container_port=$2

if [ ${host_port} ]
then
	echo "-p ${host_port}:${container_port}"
fi
