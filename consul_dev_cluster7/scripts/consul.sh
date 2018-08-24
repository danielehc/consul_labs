#!/usr/bin/env bash
set -x 

###################
#   PKG INSTALL   #
###################

# The VM should already have these tools but in case theey are not 
# there we reinstall them
which unzip curl jq route &>/dev/null || {
    echo "Installing dependencies ..."
    sudo apt-get update
    sudo apt-get install -y unzip curl jq net-tools dnsutils
    sudo apt-get clean
}

# Killall will be needed to restart consul nodes
which killall &>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y psmisc
}

###################
# CONSUL TUNING   #
###################

# Install consul-template 
CT_INSTALL=false

# Apply ACL
ACL_APPLY=false

# Setup Multi DC
MULTI_DC=true


###################
# CONSUL INSTALL  #
###################

#if no consul binary we download one
which consul &>/dev/null || {
    echo "Determining Consul version to install ..."

    CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
    if [ -z "$CONSUL_VERSION" ]; then
        CONSUL_VERSION=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')
    fi
	
	pushd /tmp/
	
    if [ -f "/vagrant/pkg/consul_${CONSUL_VERSION}_linux_amd64.zip" ]; then
			echo "Found Consul in /vagrant/pkg"
    else
			echo "Fetching Consul version ${CONSUL_VERSION} ..."
			mkdir -p /vagrant/pkg/
			curl -s https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o /vagrant/pkg/consul_${CONSUL_VERSION}_linux_amd64.zip
		
			if [ $? -ne 0 ]; then
				echo "Download failed! Exiting."
				exit 1
			fi

		fi
    
    echo "Installing Consul version ${CONSUL_VERSION} ..."
	pushd /tmp
    unzip /vagrant/pkg/consul_${CONSUL_VERSION}_linux_amd64.zip 
    sudo chmod +x consul
    sudo mv consul /usr/local/bin/consul

	# Install bash completion for Consul <3
	/usr/local/bin/consul -autocomplete-install
}

###################
# CONSUL TEMPLATE #
###################

if ( $CT_INSTALL ); then

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

fi

########################
# CONSUL CONFIGURATION #
########################

SERVER_COUNT=${SERVER_COUNT:-3}
echo $SERVER_COUNT

# Getting node IP
IFACE=`route -n | awk '$1 ~ "10.10" {print $8}'`
CIDR=`ip addr show ${IFACE} | awk '$2 ~ "10.10" {print $2}'`
IP=${CIDR%%/24}

DC_RANGE=`echo $IP | awk '{split($0, a, "."); print a[1]"."a[2]"."a[3]}'`
NET_RANGE=`echo $IP | awk '{split($0, a, "."); print a[1]"."a[2]}'`

# The configuration is made in such a way that Consul servers will have an IP such as
# 10.10.DC_NUM*10.SERVER_NUM+10
# So for example:
# Server one of DC1 will have IP: 10.10.10.11
# Server two of DC2 will have IP: 10.10.20.12
JOIN_STRING=""
for i in `seq 1 $SERVER_COUNT`; do
	JOIN_STRING="$JOIN_STRING -retry-join=$DC_RANGE.$((10 + i))"
done

# The configuration is made in such a way that every VM hostname
# will be DC_NAME-service so the script will extract the DC_NAME from the hostname
DC_NAME=`echo $HOSTNAME | awk '{split($0, a, "-"); print a[1]}'`


CLUSTER_STRING="-datacenter=$DC_NAME $JOIN_STRING" 

mkdir -p /etc/consul.d 
sudo chmod a+w /etc/consul.d

cp /vagrant/etc/consul.d/consul.default.json /etc/consul.d/


# Copy consul configuration using hostname to decide if the node is a server 
if [[ "${HOSTNAME}" =~ "consul" ]]; then
	echo "Configure node ${HOSTNAME} as Server"
	cp /vagrant/etc/consul.d/consul.server.json /etc/consul.d/

	if ( $MULTI_DC ); then
		# In case we are starting a server we need to set the bootstrap-expect parameter
		CLUSTER_STRING="$CLUSTER_STRING -bootstrap-expect=$SERVER_COUNT" 
		
		# For Multi Data Center configuration we need to add the retry-join-wan parameter
		# The following configuration tries to join to all the Server nodes in the 2 data centers
		JOIN_WAN_STRING=""
		for j in 10 20; do
			for i in `seq 1 $SERVER_COUNT`; do
				JOIN_WAN_STRING="$JOIN_WAN_STRING -retry-join-wan=${NET_RANGE}.${j}.$((10 + i))"
			done
		done

		CLUSTER_STRING="$CLUSTER_STRING $JOIN_WAN_STRING"
	fi

	if ( $ACL_APPLY ); then
		cp /vagrant/etc/consul.d/consul.acl.json /etc/consul.d/
	fi
else
	echo "Configure node ${HOSTNAME} as Client Agent"

	if ( $ACL_APPLY ); then
		cp /vagrant/etc/consul.d/consul.acl.agent.json /etc/consul.d/
	fi
fi

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
	/usr/local/bin/consul agent -bind=${IP} $CLUSTER_STRING -config-dir /etc/consul.d > /tmp/consul.log &
	sleep 1

	echo "Loading ACL tokens ..."

	if ( $ACL_APPLY ); then
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
	fi
}

echo "Reloading Consul configuration ..."
# Reload Consul configuration
killall -1 consul

# Check cluster state
/usr/local/bin/consul members

if ( $MULTI_DC ); then
	# Check Multi DC state
	/usr/local/bin/consul members -wan
fi

set +x 
