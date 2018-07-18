#!/usr/bin/env bash

SERVICE_URL="http://localhost:8080"

which lynx &> /dev/null && {
		
		STATE_1=`lynx --dump $SERVICE_URL`
		STATE_2=`lynx --dump $SERVICE_URL`
		
		if [ "$STATE_2" -gt "$STATE_1" ]; then
		
			echo "Service OK"
			exit 0
			
		else
			echo "Service KO"
			exit 2
		fi
}

echo "No lynx command found, no way to check"

exit 1


