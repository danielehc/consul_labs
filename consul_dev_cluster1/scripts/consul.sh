#!/usr/bin/env bash
set -x 

#dnsutils
#if the tools aren't installed, we install them
which unzip curl jq route &>/dev/null || {
    echo "Installing dependencies ..."
    sudo apt-get update
    sudo apt-get install -y unzip curl jq net-tools
    
    sudo apt-get clean
}

#if no consul binary we download one
which consul &>/dev/null || {
    echo "Determining Consul version to install ..."

    CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
    if [ -z "$CONSUL_DEMO_VERSION" ]; then
        CONSUL_DEMO_VERSION=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')
    fi

    echo "Fetching Consul version ${CONSUL_DEMO_VERSION} ..."
    pushd /tmp/
    curl -s https://releases.hashicorp.com/consul/${CONSUL_DEMO_VERSION}/consul_${CONSUL_DEMO_VERSION}_linux_amd64.zip -o consul.zip

    echo "Installing Consul version ${CONSUL_DEMO_VERSION} ..."
    unzip consul.zip
    sudo chmod +x consul
    sudo mv consul /usr/bin/consul

    # https://www.consul.io/intro/getting-started/services.html
    sudo mkdir /etc/consul.d
    sudo chmod a+w /etc/consul.d

    echo "Recovering some space ..."
    sudo rm -rf /tmp/consul.zip
}

# Getting node IP
IFACE=`route -n | awk '$1 == "172.20.20.0" {print $8}'`
CIDR=`ip addr show ${IFACE} | awk '$2 ~ "172.20.20" {print $2}'`
IP=${CIDR%%/24}

#if not running we start consul
if [[ "${HOSTNAME}" =~ "consul" ]]; then
	echo server

	/usr/bin/consul members 2>/dev/null || {
		echo "Starting Consul cluster ..."
		/usr/bin/consul agent -server -ui -client=0.0.0.0 -bind=${IP} -data-dir=/tmp/consul -join=172.20.20.11 -join=172.20.20.12 -join=172.20.20.13 -bootstrap-expect=3 > ${HOME}/${HOSTNAME}.log &
		sleep 1
	}
else
	echo agent
	/usr/local/bin/consul members 2>/dev/null || {
		/usr/bin/consul agent -bind=${IP} -data-dir=/tmp/consul -join=172.20.20.11 -join=172.20.20.12 -join=172.20.20.13 > ${HOME}/${HOSTNAME}.log &
		sleep 1
	}
fi

# Check cluster state
/usr/bin/consul members

set +x 
