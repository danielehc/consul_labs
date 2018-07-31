# Create a VM
variable "resourcename" {
  default = "danieleResourceGroup"
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
resource "azurerm_resource_group" "danieleterraformgroup" {
  name     = "danieleResourceGroup"
  location = "eastus"

  tags {
    environment = "Daniele Terraform Demo"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "danieleterraformnetwork" {
  name                = "danieleVnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = "${azurerm_resource_group.danieleterraformgroup.name}"

  tags {
    environment = "Terraform Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "danieleterraformsubnet" {
  name                 = "danieleSubnet"
  resource_group_name  = "${azurerm_resource_group.danieleterraformgroup.name}"
  virtual_network_name = "${azurerm_virtual_network.danieleterraformnetwork.name}"
  address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "danieleterraformpublicip" {
  name                         = "danielePublicIP"
  location                     = "eastus"
  resource_group_name          = "${azurerm_resource_group.danieleterraformgroup.name}"
  public_ip_address_allocation = "dynamic"

  tags {
    environment = "Terraform Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "danieleterraformnsg" {
  name                = "danieleNetworkSecurityGroup"
  location            = "eastus"
  resource_group_name = "${azurerm_resource_group.danieleterraformgroup.name}"

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
    environment = "Terraform Demo"
  }
}

# Create network interface
resource "azurerm_network_interface" "danieleterraformnic" {
  name                      = "danieleNIC"
  location                  = "eastus"
  resource_group_name       = "${azurerm_resource_group.danieleterraformgroup.name}"
  network_security_group_id = "${azurerm_network_security_group.danieleterraformnsg.id}"

  ip_configuration {
    name                          = "danieleNicConfiguration"
    subnet_id                     = "${azurerm_subnet.danieleterraformsubnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.danieleterraformpublicip.id}"
  }

  tags {
    environment = "Terraform Demo"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.danieleterraformgroup.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "danielestorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.danieleterraformgroup.name}"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "Terraform Demo"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "danieleterraformvm" {
  name                  = "danieleVM"
  location              = "eastus"
  resource_group_name   = "${azurerm_resource_group.danieleterraformgroup.name}"
  network_interface_ids = ["${azurerm_network_interface.danieleterraformnic.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "danieleOsDisk"
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
    computer_name  = "danielevm"
    admin_username = "azureuser"
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
    storage_uri = "${azurerm_storage_account.danielestorageaccount.primary_blob_endpoint}"
  }

  tags {
    environment = "Terraform Demo"
  }
}

# here we will add a consul cluster


# here we will do a redis
# we can do VM or see if there is Redis as a service
# register service in consul


# here we will do a VM
# will add our binary
# will run the binary

