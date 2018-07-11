#!/bin/bash

set -x 

echo "Installing dependencies ..."

sudo apt-get update
sudo apt-get install -y unzip curl jq dnsutils

echo "Determining Consul version to install ..."

CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
if [ -z "$CONSUL_DEMO_VERSION" ]; then
    CONSUL_DEMO_VERSION=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')
fi

echo "Fetching Consul version ${CONSUL_DEMO_VERSION} ..."
cd /tmp/
curl -s https://releases.hashicorp.com/consul/${CONSUL_DEMO_VERSION}/consul_${CONSUL_DEMO_VERSION}_linux_amd64.zip -o consul.zip

echo "Installing Consul version ${CONSUL_DEMO_VERSION} ..."
unzip consul.zip
sudo chmod +x consul
sudo mv consul /usr/bin/consul

# https://www.consul.io/intro/getting-started/services.html
sudo mkdir /etc/consul.d
sudo chmod a+w /etc/consul.d

echo "Recovering some space ..."
sudo apt-get clean
sudo rm -rf /tmp/consul.zip

echo "Starting Consul cluster ..."

/usr/bin/consul agent -server -ui -client=0.0.0.0 -bind=${IP} -data-dir=/tmp/consul -join=172.20.20.10 -join=172.20.20.11 -bootstrap-expect=2 > ${HOME}/${HOSTNAME}.log &

sleep 1

/usr/bin/consul members

set +x 
