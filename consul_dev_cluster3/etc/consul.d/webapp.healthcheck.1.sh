#!/usr/bin/env bash

SERVICE_URL="http://localhost:8080"

which lynx &> /dev/null || {
	apt-get update
	apt-get install -y lynx
	apt-get clean
}
	
#set initial values
STATE_1="notanumber1"
STATE_2="notanumber2"

#get some output of the service
STATE_1=`lynx --dump $SERVICE_URL`
STATE_2=`lynx --dump $SERVICE_URL`

#the test
if [ "$STATE_1" -eq 0 ] || [ "$STATE_2" -eq 0 ] ; then
	echo "Service KO"
	exit 2
elif [ "$STATE_2" -gt "$STATE_1" ]; then
	echo "Service OK"
	exit 0
else
	echo "Service KO"
	exit 2
fi