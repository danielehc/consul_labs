# Terraform & Azure

The folder contains a testbed to spin-up an environment using Azure cloud services.

The idea is to replicate the last consul_lab in the repository in Azure (and hopefully add some more things to the table).



## Prerequisites

### Environment Variables for Azure

In order to enable Terraform to connect with Azure the following variables will need to be set in your environment:

- ARM_SUBSCRIPTION_ID
- ARM_CLIENT_ID
- ARM_CLIENT_SECRET
- ARM_TENANT_ID

run `az login` and then follow the steps listed in https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure to find out the value for the variables for your Azure subscription.



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


### SSH

The `script/azure_cli.sh` script will create a ssh key in `/vagrant/priv/id_rsa` and will setup the environment to use it.

:information_source: This requires no extra steps from your side.



### Prefix

To avoid conflicts with resources in case you are sharing the subscription with other users a good practice is to add a prefix to customize resource names. 

To do so a variable called `prefix` (and the equivalent TF variable `TF_VAR_prefix`) should be set in the environment .

If the variable is not set a default value of `daniele` will be used as visible in `main.tf`:

```json
variable "prefix" {
  default = "daniele"
}
```



### Custom Azure image

Some of the configurations (e.g. `tf_singlevm`) use a custom image generated using Packer (see in the [packer](https://github.com/danielehc/consul_labs/tree/master/terraform/packer) for more info on how to generate it).

:warning:  These configurations will not work in case the custom VM image is not created so before using them follow instructions in the [packer](https://github.com/danielehc/consul_labs/tree/master/terraform/packer) folder to generate it.



### Variables

  Before using the environment you should:

  * Create a folder called `priv` 

  * Add a file called `azure.env` to it with the following content:

    ```bash
    
    #project prefix
    export prefix=daniele
    export TF_VAR_prefix=${prefix}
    
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
    
    # Chef Azure Variables
    export AZURE_CLIENT_ID=${ARM_CLIENT_ID}
    export AZURE_CLIENT_SECRET=${ARM_CLIENT_SECRET}
    export AZURE_TENANT_ID=${ARM_TENANT_ID}
    
    # Custom Azure Image ID
    export TF_VAR_custom_image_id="/subscriptions/${TF_VAR_ARM_SUBSCRIPTION_ID}/resourceGroups/${TF_VAR_prefix}ResourceGroupForVM/providers/Microsoft.Compute/images/xenial64"
    ```

    


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
