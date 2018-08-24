#!/usr/bin/env bash

# Ping Redis
redis-cli ping

#the test
if [ "$?" -eq 0 ]; then
	echo "Service OK"
	exit 0
else
	echo "Service KO"
	exit 2
fi
