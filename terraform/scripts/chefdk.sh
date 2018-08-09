#!/usr/bin/env bash

set -x

which chef &>/dev/null || {
    echo "Installing Chef Development Kit ..."

	PKG_FILENAME="chefdk_2.5.3-1_amd64.deb"
	PKG_HASH="1ce5d16a3b64f8f8951c2b9704793e31b7e4f22085780f652298c33bebccb212"

	# https://packages.chef.io/files/stable/chefdk/2.5.3/debian/8/chefdk_2.5.3-1_amd64.deb

	if [ ! -f /vagrant/pkg/chefdk_2.5.3-1_amd64.deb ]; then
		# Package not present in archive, we download it

		curl -sL https://packages.chef.io/files/stable/chefdk/2.5.3/debian/8/${PKG_FILENAME} -o /vagrant/pkg/${PKG_FILENAME}

		if [ $? -ne 0 ]; then
			echo "Download failed! Exiting."
			exit 1
		fi

	fi

	# Check file is correct

	echo ${PKG_HASH} /vagrant/pkg/${PKG_FILENAME} | sha256sum -c - &>/dev/null

	if [ $? -ne 0 ]; then
		echo "Checksum failed! Exiting."
		exit 1
	fi

	dpkg -i /vagrant/pkg/${PKG_FILENAME}
    
}


chef --version

# Installing gem for kitchen-azurerm
chef gem install kitchen-azurerm
sudo su - vagrant -c "chef gem install kitchen-azurerm"

set +x
