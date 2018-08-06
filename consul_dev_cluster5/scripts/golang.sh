#!/usr/bin/env bash

set -x

if [ -z "$GOLANG_VERSION" ]; then
	GOLANG_VERSION="1.10.3"
fi

PKG_FILE="go${GOLANG_VERSION}.linux-amd64.tar.gz"
INSTALL_PATH="/usr/local/go"

if [ ! -d "$INSTALL_PATH" ]; then

	echo "Downloading $PKG_FILE ..."

	if [ -f "/vagrant/pkg/$PKG_FILE" ]; then
		echo "Found Golang in /vagrant/pkg"
	else
		mkdir -p /vagrant/pkg
		curl -s https://storage.googleapis.com/golang/$PKG_FILE -o /vagrant/pkg/$PKG_FILE
		
		if [ $? -ne 0 ]; then
				echo "Download failed! Exiting."
				exit 1
		fi
		
	fi

	echo "Installing Golang $GOLANG_VERSION ..."

	sudo tar -C "/tmp" -xzf /vagrant/pkg/$PKG_FILE
	sudo mv "/tmp/go" "$INSTALL_PATH"

	touch "/etc/bash.bashrc"
	{
			echo '# GoLang'
			echo "export GOROOT=$INSTALL_PATH"
			echo 'export PATH=$PATH:$GOROOT/bin'
	} >> "/etc/bash.bashrc"

fi

export GOROOT=$INSTALL_PATH
export PATH=$PATH:$GOROOT/bin

# Healtcheck uses lynx command to check webervice
which lynx &>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y lynx
}

# choose a random port
let RANDOM_PORT=1024+RANDOM

# Registering the service
if [ ! -d "/etc/consul.d" ]; then
	# Creates folder
	sudo mkdir -p /etc/consul.d
	sudo chmod a+w /etc/consul.d	
fi

#Copy Files
cp /vagrant/etc/consul.d/webapp* /etc/consul.d/
sed -i "s/@@PORT@@/${RANDOM_PORT}/g" /etc/consul.d/*

which killall &>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y psmisc
}

# Make Consul re-load /etc/consul.d content
killall -1 consul

# Instaling required packaged for the app
go get -u github.com/hashicorp/consul/api
go get -u github.com/go-redis/redis

# Rebuild the application
killall modern_app_web &>/dev/null
pushd /usr/local/bin
go build /vagrant/src/modern_app_web.go

# Output is redirected to a file to avoid application crash due to absence of a stdout
# Logging is done on stdout due to “architectural decisions based on 12app interpretation”	
/usr/local/bin/modern_app_web -port=${RANDOM_PORT} > app.log &
sleep 1
	
set +x
