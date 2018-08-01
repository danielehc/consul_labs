# Create a VM

variable "prefix" {
  default = "daniele"
}

variable "datacenter" {
  default = "eastus"
}

variable "consul_version" {
  default     = "1.2.2"
  description = "The Consul version to install on agents"
}

variable "ARM_SUBSCRIPTION_ID" {
  description = "The Azure subscription ID"
}

variable "ARM_CLIENT_ID" {
  description = "The Azure client ID"
}

variable "ARM_CLIENT_SECRET" {
  description = "The Azure secret access key"
}

variable "ARM_TENANT_ID" {
  description = "The Azure tenant ID"
}

variable "SSH_KEY_DATA" {
  description = "The public key for SSH connection"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "${var.ARM_SUBSCRIPTION_ID}"
  client_id       = "${var.ARM_CLIENT_ID}"
  client_secret   = "${var.ARM_CLIENT_SECRET}"
  tenant_id       = "${var.ARM_TENANT_ID}"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "terraformgroup" {
  name     = "${var.prefix}ResourceGroup"
  location = "${var.datacenter}"

  tags {
    environment = "${var.prefix} Terraform Demo"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "terraformnetwork" {
  name                = "${var.prefix}VNet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.datacenter}"
  resource_group_name = "${azurerm_resource_group.terraformgroup.name}"

  tags {
    environment = "${var.prefix} Terraform Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "terraformsubnet" {
  name                 = "${var.prefix}Subnet"
  resource_group_name  = "${azurerm_resource_group.terraformgroup.name}"
  virtual_network_name = "${azurerm_virtual_network.terraformnetwork.name}"
  address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "terraformpublicip" {
  name                         = "${var.prefix}PublicIP"
  location                     = "${var.datacenter}"
  resource_group_name          = "${azurerm_resource_group.terraformgroup.name}"
  public_ip_address_allocation = "dynamic"

  tags {
    environment = "${var.prefix} Terraform Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "terraformnsg" {
  name                = "${var.prefix}NetworkSecurityGroup"
  location            = "${var.datacenter}"
  resource_group_name = "${azurerm_resource_group.terraformgroup.name}"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "${var.prefix} Terraform Demo"
  }
}

# Create network interface
resource "azurerm_network_interface" "terraformnic" {
  name                      = "${var.prefix}NIC"
  location                  = "${var.datacenter}"
  resource_group_name       = "${azurerm_resource_group.terraformgroup.name}"
  network_security_group_id = "${azurerm_network_security_group.terraformnsg.id}"

  ip_configuration {
    name                          = "${var.prefix}NicConfiguration"
    subnet_id                     = "${azurerm_subnet.terraformsubnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.terraformpublicip.id}"
  }

  tags {
    environment = "${var.prefix} Terraform Demo"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.terraformgroup.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.terraformgroup.name}"
  location                 = "${var.datacenter}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "${var.prefix} Terraform Demo"
  }
}

# here we add consul
data "template_file" "init" {
  template = "${file("./init-vm.tpl")}"

  vars = {
    consul_version    = "${var.consul_version}"
    consul_datacenter = "${var.prefix}-${var.datacenter}"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "terraformvm" {
  name                  = "${var.prefix}VM"
  location              = "${var.datacenter}"
  resource_group_name   = "${azurerm_resource_group.terraformgroup.name}"
  network_interface_ids = ["${azurerm_network_interface.terraformnic.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "${var.prefix}OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.prefix}vm"
    admin_username = "azureuser"
    custom_data    = "${base64encode(data.template_file.init.rendered)}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "${var.SSH_KEY_DATA}"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.storageaccount.primary_blob_endpoint}"
  }

  tags {
    environment = "${var.prefix} Terraform Demo"
    datacenter  = "${var.prefix}-${var.datacenter}"
  }
}

# here we will do a redis
# we can do VM or see if there is Redis as a service
# register service in consul

# here we will do a VM
# will add our binary
# will run the binary

data "azurerm_public_ip" "terraformpublicip" {
  name                = "${azurerm_public_ip.terraformpublicip.name}"
  resource_group_name = "${var.prefix}ResourceGroup"
}

output "machine_public_ip" {
  value = "${format("ssh azureuser@%s", azurerm_public_ip.terraformpublicip.ip_address)}"
}
