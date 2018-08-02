#!/usr/bin/env bash

set -x

exec > >(tee /var/log/user-data.log) 2>&1

# The VM should already have these tools but in case theey are not 
# there we reinstall them
which unzip curl jq route &>/dev/null || {
    export DEBIAN_FRONTEND=noninteractive
    echo "Installing dependencies ..."
    sudo apt-get update
    sudo apt-get install -y unzip curl jq net-tools dnsutils
    sudo apt-get clean
}

AZURE_INSTANCE_METADATA_URL="http://169.254.169.254/metadata/instance?api-version=2017-08-01"

function lookup_path_in_instance_metadata {
    curl --silent --show-error --header Metadata:true --location "$AZURE_INSTANCE_METADATA_URL" | jq -r "$1"
}

function get_instance_ip_address {
    lookup_path_in_instance_metadata ".network.interface[0].ipv4.ipAddress[0].privateIpAddress"
}

if [  "${consul_datacenter}" ]; then
    echo "Consul Datacenter: ${consul_datacenter}"
fi

#if no consul binary we download one
which consul &>/dev/null || {
    echo "Determining Consul version to install ..."

    CONSUL_VERSION=${consul_version}

	pushd /tmp/
	
    echo "Fetching Consul version $${CONSUL_VERSION} ..."
	mkdir -p /vagrant/pkg/
	curl -s https://releases.hashicorp.com/consul/$${CONSUL_VERSION}/consul_$${CONSUL_VERSION}_linux_amd64.zip -o /tmp/consul_$${CONSUL_VERSION}_linux_amd64.zip
	
	if [ $? -ne 0 ]; then
		echo "Download failed! Exiting."
		exit 1
	fi

	echo "Installing Consul version $${CONSUL_VERSION} ..."
	pushd /tmp
    unzip /tmp/consul_$${CONSUL_VERSION}_linux_amd64.zip 
    sudo chmod +x consul
    sudo mv consul /usr/local/bin/consul

    sudo mkdir -p /etc/consul.d
    sudo chmod a+w /etc/consul.d

}

# echo "/usr/local/bin/consul --version"
/usr/local/bin/consul --version

# Write base client Consul config
sudo tee /etc/consul.d/consul-default.json <<EOF
{
"advertise_addr": "`get_instance_ip_address`",
"data_dir": "/opt/consul/data",
"client_addr": "0.0.0.0",
"log_level": "INFO",
"ui": true
}
EOF

if [ "${consul_mode}" == "server" ]; then 
  # Write base server Consul config
  echo "Seems we are in a server - Consul mode is: ${consul_mode}"
  sudo tee /etc/consul.d/consul-server.json <<EOF
  {
    "server": true,
    "bootstrap_expect": ${cluster_size}
  }
EOF

fi

/usr/local/bin/consul agent -config-dir /etc/consul.d > /var/log/consul.log &

set +x