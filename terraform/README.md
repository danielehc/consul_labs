# Terraform & Azure

The folder contains a testbed to spin-up an environment using Azure cloud services.

The idea is to replicate the last consul_lab in the repository in Azure (and hopefully add some more things to the table).



## Prerequisites

* **Environment Variables for Azure**

  In order to enable Terraform to connect with Azure the following variables will need to be set in your environment:

  - ARM_SUBSCRIPTION_ID
  - ARM_CLIENT_ID
  - ARM_CLIENT_SECRET
  - ARM_TENANT_ID

  The `scripts/azure_cli.sh` provision script expects to find a file called `azure.env` where these variables are set:

  ```bash
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
  ```

  So before using the environment you should:

  * Create an ssh key like `ssh-keygen -t rsa` and check the pub key

  * Create a folder called `priv` 

  * Add a file called `azure.env` to it with the following content:

    ```bash
    
    #project prefix
    export TF_VAR_prefix=daniele

    #ssh pubkey
    export TF_VAR_SSH_KEY_DATA=ssh_pub_key

    #Azure creds
    export ARM_SUBSCRIPTION_ID=your_subscription_id
    export ARM_CLIENT_ID=your_appId
    export ARM_CLIENT_SECRET=your_password
    export ARM_TENANT_ID=your_tenant_id
    
    #Terraform variables
    export TF_VAR_ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}
    export TF_VAR_ARM_CLIENT_ID=${ARM_CLIENT_ID}
    export TF_VAR_ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET}
    export TF_VAR_ARM_TENANT_ID=${ARM_TENANT_ID}
    ```

    run `az login` and then follow the steps listed in https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure

## Getting started

Once cloned the repository you can use the following steps to spin up the environment:

* Follow prerequisites above ;)

* `vagrant up`

* `vagrant ssh`

  This will make you login into the machine where now the environment is ready to use Terraform.

  ```bash
  $ cd /vagrant/[project_folder]
  $ terraform fmt
  $ terraform init
  $ terraform plan -out terraform.plan
  $ terraform apply terraform plan
  ```

   

## Resources

The following links were used during the testbed preparation:

* https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure
* https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-create-complete-vm
