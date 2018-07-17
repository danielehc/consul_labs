#!/usr/bin/env bash
set -x 

# The VM should already have these tools but in case theey are not 
# there we reinstall them
which unzip curl jq route &>/dev/null || {
    echo "Installing dependencies ..."
    sudo apt-get update
    sudo apt-get install -y unzip curl jq net-tools dnsutils
    sudo apt-get clean
}

#if no consul binary we download one
which consul &>/dev/null || {
    echo "Determining Consul version to install ..."

    CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
    if [ -z "$CONSUL_DEMO_VERSION" ]; then
        CONSUL_DEMO_VERSION=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')
    fi
	
	pushd /tmp/
	
    if [ -f "/vagrant/pkg/consul_${CONSUL_DEMO_VERSION}_linux_amd64.zip" ]; then
		echo "Found Consul in /vagrant/pkg"
		cp /vagrant/pkg/consul_${CONSUL_DEMO_VERSION}_linux_amd64.zip /tmp/consul.zip
    else
		echo "Fetching Consul version ${CONSUL_DEMO_VERSION} ..."
		
		curl -s https://releases.hashicorp.com/consul/${CONSUL_DEMO_VERSION}/consul_${CONSUL_DEMO_VERSION}_linux_amd64.zip -o consul.zip
		
		if [ $? -ne 0 ]; then
			echo "Download failed! Exiting."
			exit 1
		fi
		
		# Copying the archive in the /vagrant folder to reuse it for future provisionings or other VMs
		mkdir -p /vagrant/pkg/
		sudo cp consul.zip /vagrant/pkg/consul_${CONSUL_DEMO_VERSION}_linux_amd64.zip
   fi
    
    echo "Installing Consul version ${CONSUL_DEMO_VERSION} ..."
    unzip consul.zip
    sudo chmod +x consul
    sudo mv consul /usr/local/bin/consul

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

mkdir -p /etc/consul.d 
#if not running we start consul
if [[ "${HOSTNAME}" =~ "consul" ]]; then
	echo server

	/usr/local/bin/consul members 2>/dev/null || {
		echo "Starting Consul cluster ..."
		/usr/local/bin/consul agent -server -ui -client=0.0.0.0 -bind=${IP} -data-dir=/tmp/consul -config-dir=/etc/consul.d -enable-script-checks  -join=172.20.20.11 -join=172.20.20.12 -join=172.20.20.13 -bootstrap-expect=3 > ${HOME}/${HOSTNAME}.log &
		sleep 1
	}
else
	echo agent
	/usr/local/bin/consul members &>/dev/null || {
		/usr/local/bin/consul agent -client=0.0.0.0 -bind=${IP} -data-dir=/tmp/consul -config-dir=/etc/consul.d -enable-script-checks -join=172.20.20.11 -join=172.20.20.12 -join=172.20.20.13 > ${HOME}/${HOSTNAME}.log &
		sleep 1
	}
fi

# Check cluster state
/usr/local/bin/consul members

set +x 
