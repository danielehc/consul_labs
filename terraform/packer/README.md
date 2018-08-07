

# pre-req

chefdk-2.5.3-1.dmg

gem install kitchen-azurerm

# process

packer build xenial64.json

kitchen test

kitchen destroy

packer build -force xenial64.json

kitchen test

kitchen destroy
