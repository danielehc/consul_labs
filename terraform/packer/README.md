# Custom Azure Image with Packer

## Pre-requisites

### Packer and Kitchen

To generate custom images for Azure we used Packer (https://www.packer.io/) for the image generation and Kitchen (https://kitchen.ci/) to test the image generated against prerequisites needed  to run the necessary softwares.

The `vagrant up` process  makes sure to install both the tools but, in case you want to  execute the creation and testing on your own machine make sure you:

* [Have Packer installed](https://www.packer.io/intro/getting-started/install.html) 

* [Have ChefDK 2.5.3 installed](https://downloads.chef.io/chefdk/stable/2.5.3)

* Install `kitchen-azurerm` gem with the following command:

  ```bash
  chef gem install kitchen-azurerm
  ```



### Azure Resource Group

The created VM will be stored in a new Azure Resource Group.

The resource group can be generated using the template present in the `tf_resourcegroup` folder:

```bash
cd tf_resourcegroup
terraform fmt
terraform init
terraform plan -out terraform plan
terraform apply terraform.plan
```



:information_source:  The template uses the same `prefix` variable used by the environment, in case you are not running it from inside the Vagrant VM make sure you have the variable defined in your environment.



## Process

```bash
# Generates the VM image
packer build xenial64.json

# Tests the image against the defined checks
kitchen test
kitchen destroy

# Re-builds the image
packer build -force xenial64.json

# Tests the image against the defined checks
kitchen test
kitchen destroy
```









## Resources

* https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer