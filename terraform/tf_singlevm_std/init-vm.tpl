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

    rm -rf /tmp/consul_$${CONSUL_VERSION}_linux_amd64.zip 

    sudo mkdir -p /etc/consul.d
    sudo chmod a+w /etc/consul.d

}

# echo "/usr/local/bin/consul --version"
/usr/local/bin/consul --version

# Write base client Consul config
sudo tee /etc/consul.d/consul-default.json <<EOF
{
"bind_addr": "`get_instance_ip_address`",
"data_dir": "/opt/consul/data",
"client_addr": "0.0.0.0",
"log_level": "INFO",
"ui": true,
"enable_script_checks": true
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

# Install Redis

which redis-server 2>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y redis-server redis-tools
  sed -i 's/bind.*/bind 0.0.0.0/' /etc/redis/redis.conf
  update-rc.d redis-server defaults
}

/etc/init.d/redis-server status 2>/dev/null && /etc/init.d/redis-server force-reload 2>/dev/null || /etc/init.d/redis-server start 2>/dev/null

# If service is not present in the /etc/consul.d folder creates a service file
if [ ! -d "/etc/consul.d" ]; then
	
	# Creates folder
	sudo mkdir -p /etc/consul.d
	sudo chmod a+w /etc/consul.d	

fi

# Write redis service Consul config
sudo tee /etc/consul.d/redis.service.json <<EOF
  {
    "service": {
      "name": "redis",
      "tags": [
        "redis-server"
      ],
      "port": 6379
    }
  }
EOF

# Write redis service healthcheck Consul config
sudo tee /etc/consul.d/redis.healthcheck.json <<EOF
  {
  "check": {
    "id": "redis-ping",
    "name": "Ping Redis",
    "args": ["redis-cli", "ping"],
    "interval": "10s",
    "timeout": "1s",
    "service_id": "redis"
    }
}
EOF

which killall &>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y psmisc
}

#reload consul
killall -1 consul


# # Download my application
# # Run

if [ "${webapp_release}" == "latest" ]; then
    sudo curl -sL `curl -s https://api.github.com/repos/danielehc/consul_labs/releases/latest | jq .assets[0].browser_download_url | sed 's/"//g'` -o /usr/local/bin/modern_app_web
else
    sudo curl -sL `curl -s https://api.github.com/repos/danielehc/consul_labs/releases/tags/${webapp_release} | jq .assets[0].browser_download_url | sed 's/"//g'` -o /usr/local/bin/modern_app_web
fi

if [ $? -ne 0 ]; then
    echo "Download failed! Exiting."
    exit 1
fi

chmod +x /usr/local/bin/modern_app_web

/usr/local/bin/modern_app_web > /var/log/webapp.log &

sleep 1

# Write webapp service Consul config
sudo tee /etc/consul.d/webapp.service.json <<EOF
  {
    "service": {
      "name": "webapp",
      "tags": [
        "go-webapp"
      ],
      "port": 8080
    }
  }
EOF

sudo tee /etc/consul.d/webapp.healthcheck.json <<EOF
{
  "check": {
    "id": "webapp-check",
    "name": "Check Webapp",
    "args": ["/etc/consul.d/webapp.healthcheck.1.sh"],
    "interval": "10s",
    "timeout": "9s",
    "service_id": "webapp"
  }
}
EOF

sudo tee /etc/consul.d/webapp.healthcheck.1.sh <<EOF
#!/usr/bin/env bash

SERVICE_URL="http://localhost:8080"

which lynx &> /dev/null || {
	apt-get update
	apt-get install -y lynx
	apt-get clean
}
	
#set initial values
STATE_1="notanumber1"
STATE_2="notanumber2"

#get some output of the service
STATE_1=\`lynx --dump \$SERVICE_URL 2>/dev/null\`
STATE_2=\`lynx --dump \$SERVICE_URL 2>/dev/null\`

#the test
if [ "\$STATE_1" -eq 0 ] || [ "\$STATE_2" -eq 0 ] ; then
	echo "Service KO"
	exit 2
elif [ "\$STATE_2" -gt "\$STATE_1" ]; then
	echo "Service OK"
	exit 0
else
	echo "Service KO"
	exit 2
fi
EOF

chmod +x /etc/consul.d/webapp.healthcheck.1.sh

which killall &>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y psmisc
}

#reload consul
killall -1 consul

set +x