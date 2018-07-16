#!/usr/bin/env bash
set -x

# Tools installed in this script shouldeventually end up being installed
# in the Vagrant box we start from
# Collecting them here will help better define the Box later

#if the tools aren't installed, we install them
which unzip curl jq route dig vim git &>/dev/null || {
    echo "Installing dependencies ..."
    sudo apt-get update
    sudo apt-get install -y unzip curl jq net-tools dnsutils vim git
    
    sudo apt-get clean
}


set +x
