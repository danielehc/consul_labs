#!/usr/bin/env bash
set -x 

# The VM should already have these tools but in case theey are not 
# there we reinstall them
which unzip curl jq route dh_bash-completion &>/dev/null || {
    echo "Installing dependencies ..."
    sudo apt-get update
    sudo apt-get install -y unzip curl jq net-tools dnsutils bash-completion
    sudo apt-get clean
}

#if no packer binary we download one
which packer &>/dev/null || {
    echo "Determining Packer version to install ..."

    CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
    if [ -z "$PACKER_VERSION" ]; then
        PACKER_VERSION=$(curl -s "${CHECKPOINT_URL}"/packer | jq .current_version | tr -d '"')
    fi
	
	pushd /tmp/
	
    if [ -f "/vagrant/pkg/packer_${PACKER_VERSION}_linux_amd64.zip" ]; then
			echo "Found Packer in /vagrant/pkg"
    else
			echo "Fetching Packer version ${PACKER_VERSION} ..."
			mkdir -p /vagrant/pkg/
			curl -s https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip -o /vagrant/pkg/packer_${PACKER_VERSION}_linux_amd64.zip
		
			if [ $? -ne 0 ]; then
				echo "Download failed! Exiting."
				exit 1
			fi

		fi
    
    echo "Installing Packer version ${PACKER_VERSION} ..."
	pushd /tmp
    unzip /vagrant/pkg/packer_${PACKER_VERSION}_linux_amd64.zip 
    sudo chmod +x packer
    sudo mv packer /usr/local/bin/packer
}

# Check installation
/usr/local/bin/packer --version

set +x 
