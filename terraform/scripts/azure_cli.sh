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
	grep /azure.env /etc/bash.bashrc || {
          echo source /vagrant/priv/azure.env | sudo tee -a /etc/bash.bashrc
        }

else

	echo "No Environment Variables file found for AZURE"
	echo "Please follow steps listed at https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure"

fi

set +x
