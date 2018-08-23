#!/usr/bin/env bash
set -x 

# The VM should already have these tools but in case theey are not 
# there we reinstall them
which unzip curl jq route &>/dev/null || {
    echo "Installing dependencies ..."
    sudo apt-get update
    sudo apt-get install -y unzip curl jq net-tools dnsutils
    sudo apt-get clean
}

#if no terraform binary we download one
which terraform &>/dev/null || {
    echo "Determining Terraform version to install ..."

    CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
    if [ -z "$TERRAFORM_VERSION" ]; then
        TERRAFORM_VERSION=$(curl -s "${CHECKPOINT_URL}"/terraform | jq .current_version | tr -d '"')
    fi
	
	pushd /tmp/
	
	#~ https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip
	
    if [ -f "/vagrant/pkg/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" ]; then
			echo "Found Terraform in /vagrant/pkg"
    else
			echo "Fetching Terraform version ${TERRAFORM_VERSION} ..."
			mkdir -p /vagrant/pkg/
			curl -s https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o /vagrant/pkg/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
		
			if [ $? -ne 0 ]; then
				echo "Download failed! Exiting."
				exit 1
			fi

		fi
    
    echo "Installing Terraform version ${TERRAFORM_VERSION} ..."
	pushd /tmp
    unzip /vagrant/pkg/terraform_${TERRAFORM_VERSION}_linux_amd64.zip 
    sudo chmod +x terraform
    sudo mv terraform /usr/local/bin/terraform

    # Enable Terraform autocompletion
    pushd /etc/bash_completion.d
    curl -sL https://raw.githubusercontent.com/Bash-it/bash-it/master/completion/available/terraform.completion.bash -o terraform
}



# Getting node IP
IFACE=`route -n | awk '$1 == "172.20.20.0" {print $8}'`
CIDR=`ip addr show ${IFACE} | awk '$2 ~ "172.20.20" {print $2}'`
IP=${CIDR%%/24}

# Check installation
/usr/local/bin/terraform --version

set +x 
