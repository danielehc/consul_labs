#!/usr/bin/env bash

set -x

exec > >(tee /var/log/user-data.log) 2>&1

if [ -z "${consul_datacenter}" ]; then
    echo "No consul_datacenter passed, printing default"
else
    echo "Consul Datacenter: ${consul_datacenter}"
    echo "Now doing serious stuff.."
fi


# The VM should already have these tools but in case theey are not 
# there we reinstall them
which unzip curl jq route &>/dev/null || {
    export DEBIAN_FRONTEND=noninteractive
    echo "Installing dependencies ..."
    sudo apt-get update
    sudo apt-get install -y unzip curl jq net-tools dnsutils
    sudo apt-get clean
}

#if no consul binary we download one
which consul &>/dev/null || {
    echo "Determining Consul version to install ..."

    CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
    if [ -z "${consul_version}" ]; then
        CONSUL_VERSION=$(curl -s "$${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')
    else
        CONSUL_VERSION=${consul_version}
    fi

	
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

    # https://www.consul.io/intro/getting-started/services.html
    sudo mkdir /etc/consul.d
    sudo chmod a+w /etc/consul.d

    echo "/usr/local/bin/consul --version: $(/usr/local/bin/consul --version)"

#     # Write base client Consul config
#     sudo tee /etc/consul.d/consul-default.json <<EOF
#     {
#     "advertise_addr": "$${local_ipv4}",
#     "data_dir": "/opt/consul/data",
#     "client_addr": "0.0.0.0",
#     "log_level": "INFO",
#     "ui": true,
#     "retry_join": ["provider=azure tag_name=consul_datacenter tag_value=${consul_datacenter} subscription_id=${auto_join_subscription_id} tenant_id=${auto_join_tenant_id} client_id=${auto_join_client_id} secret_access_key=${auto_join_secret_access_key}"]
#     }
# EOF


}




set +x