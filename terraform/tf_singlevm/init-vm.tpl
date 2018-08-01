#!/usr/bin/env bash

set -x

exec > >(tee /var/log/user-data.log) 2>&1

if [ -z "${text_variable}" ]; then
    echo "No variable passed, printing default"
else
    echo ${text_variable}    
    echo "Now doing serious stuff.."
fi

set +x