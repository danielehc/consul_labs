#!/usr/bin/env bash
set -x 

# WIP Parametrize all the sensitive informaation in the files

# DATACENTER=${ENV_DATACENTER:-"dc1"}
# ENCRYPT=${ENV_ENCRYPT:-"91vHV0vyBY196vjy7MayHA=="}
# ACL_MASTER_TOKEN=${ENV_ACL_MASTER_TOKEN:-"745d360a-d408-4a0d-9c3f-99d1a32a82c8"}
# ACL_TOKEN=${ENV_ACL_TOKEN:-"097ba0c4-b237-7b5c-4318-162e8db53127"}
# ACL_AGENT_TOKEN=${ENV_ACL_AGENT_TOKEN:-"a05fe9cc-6d55-958a-a19f-65bee0a7aa13"}



# The VM should already have these tools but in case theey are not 
# there we reinstall them
which unzip curl jq route &>/dev/null || {
    echo "Installing dependencies ..."
    sudo apt-get update
    sudo apt-get install -y unzip curl jq net-tools dnsutils
    sudo apt-get clean
}

###################
# CONSUL INSTALL  #
###################

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
    else
			echo "Fetching Consul version ${CONSUL_DEMO_VERSION} ..."
			mkdir -p /vagrant/pkg/
			curl -s https://releases.hashicorp.com/consul/${CONSUL_DEMO_VERSION}/consul_${CONSUL_DEMO_VERSION}_linux_amd64.zip -o /vagrant/pkg/consul_${CONSUL_DEMO_VERSION}_linux_amd64.zip
		
			if [ $? -ne 0 ]; then
				echo "Download failed! Exiting."
				exit 1
			fi

		fi
    
    echo "Installing Consul version ${CONSUL_DEMO_VERSION} ..."
	pushd /tmp
    unzip /vagrant/pkg/consul_${CONSUL_DEMO_VERSION}_linux_amd64.zip 
    sudo chmod +x consul
    sudo mv consul /usr/local/bin/consul
}

###################
# CONSUL TEMPLATE #
###################


# If no consul-template binary we download one
which consul-template &> /dev/null || {

	echo "Determining Consul-template version to install ..."

	CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
	if [ -z "$CONSUL_TEMPLATE_VERSION" ]; then
			CONSUL_TEMPLATE_VERSION=$(lynx --dump https://releases.hashicorp.com/consul-template/index.json | jq -r '.versions | to_entries[] | .value.version' | sort --version-sort | tail -1)
	fi
	
	echo $CONSUL_TEMPLATE_VERSION
	
	if [ -f "/vagrant/pkg/consul-template${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" ]; then
		echo "Found Consul-template in /vagrant/pkg"
  	else
		echo "Fetching Consul-template version ${CONSUL_TEMPLATE_VERSION} ..."
		mkdir -p /vagrant/pkg/
				
		# Downloading the archive in the /vagrant folder to reuse it for future provisionings or other VMs
		curl -s https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip -o /vagrant/pkg/consul-template${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip
		
		if [ $? -ne 0 ]; then
			echo "Download failed! Exiting."
			exit 1
		fi

	fi
	
	echo "Installing Consul-template version ${CONSUL_TEMPLATE_VERSION} ..."
	pushd /tmp
    unzip /vagrant/pkg/consul-template${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip
	sudo chmod +x consul-template
	sudo mv consul-template /usr/local/bin/consul-template
	
} 

########################
# CONSUL CONFIGURATION #
########################

# Getting node IP
IFACE=`route -n | awk '$1 == "172.20.20.0" {print $8}'`
CIDR=`ip addr show ${IFACE} | awk '$2 ~ "172.20.20" {print $2}'`
IP=${CIDR%%/24}

mkdir -p /etc/consul.d 
sudo chmod a+w /etc/consul.d

# Copying SSL related files
mkdir -p /etc/consul.d/ssl
cp /vagrant/etc/consul.d/ssl/ca.cert /etc/consul.d/ssl
cp /vagrant/etc/consul.d/ssl/consul.cert /etc/consul.d/ssl
cp /vagrant/etc/consul.d/ssl/consul.key /etc/consul.d/ssl

chmod 0700 /etc/consul.d/ssl
chmod 0600 /etc/consul.d/ssl/*

# Common Consul configuration 
cp /vagrant/etc/consul.d/consul.default.json /etc/consul.d/

# WIP parametrize the files
# echo $(eval echo $(cat /vagrant/etc/consul.d/consul.default.json))


# Copy consul configuration using hostname to decide if the node is a server 
if [[ "${HOSTNAME}" =~ "consul" ]]; then
	echo "Configure node ${HOSTNAME} as Server"
	cp /vagrant/etc/consul.d/consul.server.json /etc/consul.d/
	cp /vagrant/etc/consul.d/consul.acl.json /etc/consul.d/
else
	echo "Configure node ${HOSTNAME} as Client Agent"
	cp /vagrant/etc/consul.d/consul.acl.agent.json /etc/consul.d/
fi

which killall &>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y psmisc
}


#################
# CONSUL LAUNCH #
#################

echo "Stopping Consul ..."
# Stop Consul
killall consul

# This avoid TIME_WAIT connections to prevent Consul from restarting
sleep 10


/usr/local/bin/consul members &>/dev/null || {
	# Start Consul
	echo "Starting Consul ..."
	/usr/local/bin/consul agent -bind=${IP} -config-dir /etc/consul.d > /tmp/consul.log &
	sleep 1

	echo "Loading ACL tokens ..."

	# Generate ACL Token
	curl -s \
    --request PUT \
    --header "X-Consul-Token: 745d360a-d408-4a0d-9c3f-99d1a32a82c8" \
    --data \
	'{
	"ID": "097ba0c4-b237-7b5c-4318-162e8db53127",
	"Name": "ACL Token",
	"Type": "client",
	"Rules": "node \"\" { policy = \"write\" } service \"\" { policy = \"write\" }"
	}' http://${IP}:8500/v1/acl/create


	# Generate Agent Token
	curl -s \
		--request PUT \
		--header "X-Consul-Token: 745d360a-d408-4a0d-9c3f-99d1a32a82c8" \
		--data \
	'{
	"ID": "a05fe9cc-6d55-958a-a19f-65bee0a7aa13",
	"Name": "Agent Token",
	"Type": "client",
	"Rules": "node \"\" { policy = \"write\" } service \"\" { policy = \"read\" }"
	}' http://${IP}:8500/v1/acl/create

}

echo "Reloading Consul configuration ..."
# Reload Consul configuration
killall -1 consul

# Check cluster state
/usr/local/bin/consul members

set +x 
