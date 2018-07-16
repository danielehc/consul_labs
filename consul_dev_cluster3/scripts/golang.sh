#!/usr/bin/env bash

set -x

if [ -z "$GOLANG_VERSION" ]; then
	GOLANG_VERSION="1.10.3"
fi

PKG_FILE="go$GOLANG_VERSION.linux-amd64.tar.gz"
INSTALL_PATH="/usr/local/go"

if [ -d "$INSTALL_PATH" ]; then
		echo "Installation directories already exist. Exiting."
		exit 1
fi

echo "Downloading $PKG_FILE ..."

if [ -f "/vagrant/pkg/$PKG_FILE" ]; then
	echo "Found Golang in /vagrant/pkg"
	cp /vagrant/pkg/$PKG_FILE /tmp/go.tar.gz
else
	curl -s https://storage.googleapis.com/golang/$PKG_FILE -o /tmp/go.tar.gz
	
	if [ $? -ne 0 ]; then
			echo "Download failed! Exiting."
			exit 1
	fi
	
	# Copying the archive in the /vagrant folder to reuse it for future provisionings or other VMs
	sudo cp /tmp/go.tar.gz /vagrant/pkg/$PKG_FILE
fi

echo "Installing Golang $GOLANG_VERSION ..."

sudo tar -C "/tmp" -xzf /tmp/go.tar.gz
sudo mv "/tmp/go" "$INSTALL_PATH"

touch "/etc/bash.bashrc"
{
		echo '# GoLang'
		echo "export GOROOT=$INSTALL_PATH"
		echo 'export PATH=$PATH:$GOROOT/bin'
		#~ echo 'export GOPATH=/vagrant'
		#~ echo 'export PATH=$PATH:$GOPATH/bin'
} >> "/etc/bash.bashrc"

export GOROOT=$INSTALL_PATH
export PATH=$PATH:$GOROOT/bin
#~ export GOPATH=/vagrant
#~ export PATH=$PATH:$GOPATH/bin

rm -f /tmp/go.tar.gz

# Instaling required packaged for the app
go get -u github.com/hashicorp/consul/api
go get -u github.com/go-redis/redis

# Running the app
go run /vagrant/src/hello.go
go run /vagrant/src/modern_app.go


set +x
