#!/usr/bin/env bash

set -x

which az &>/dev/null || {
    echo "Installing Azure CLI ..."
    # Instructions from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest

		AZ_REPO=$(lsb_release -cs)
		echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
				sudo tee /etc/apt/sources.list.d/azure-cli.list

		curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

		sudo apt-get install -y apt-transport-https
		sudo apt-get update && sudo apt-get install -y azure-cli
}

az --version

# Once Azure CLI is installed we should follow steps enable Terraform 
# to use your Azure AD service principal
# Steps are explained at https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure
# To avoid repeat the steps everytime you can export variables using a file

if [ -f "/vagrant/priv/azure.env" ]; then

	echo "Exporting Environment Variables for AZURE"
	touch "/etc/bash.bashrc"
	{
			cat /vagrant/priv/azure.env
	} >> "/etc/bash.bashrc"

else

	echo "No Environment Variables file found forAZURE"
	echo "Please follow steps listed at https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure"

fi

# To be able to connect to the Azure VMs we will need to setup a SSH key pair
# The public key will be used to configure the VMs
# To avoid changing the values all the time at startup we check if we have such pair stored
# in the /vagrant/priv folder, if not we create it and save the configuration
# for next provision.

if [ ! -f "/vagrant/priv/id_rsa" ] || [ ! -f "/vagrant/priv/id_rsa.pub" ]; then
	ssh-keygen -b 2048 -t rsa -f /vagrant/priv/id_rsa -q -N ""
fi

cp /vagrant/priv/id_rsa* /home/vagrant/.ssh/

PUB_KEY=`cat /vagrant/priv/id_rsa.pub | awk '{print $1" "$2}'`

touch "/etc/bash.bashrc"
{
		echo "export TF_VAR_SSH_KEY_DATA='${PUB_KEY}'"
} >> "/etc/bash.bashrc"


set +x
