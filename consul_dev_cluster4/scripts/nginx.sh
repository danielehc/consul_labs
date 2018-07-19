#!/usr/bin/env bash

set -x

which nxinx 2>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y nginx
  
  update-rc.d nginx defaults
}

which killall &>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y psmisc
}

/etc/init.d/nginx status &>/dev/null && /etc/init.d/nginx force-reload &>/dev/null || /etc/init.d/nginx start &>/dev/null

killall -1 consul-template &>/dev/null
consul-template -template "/vagrant/etc/nginx/webapp_fe.ctmpl:/etc/nginx/sites-available/default:service nginx reload" &>consul-template.log &

# If service is not present in the /etc/consul.d folder creates a service file
if [ ! -d "/etc/consul.d" ]; then
	
	# Creates folder
	sudo mkdir -p /etc/consul.d
	sudo chmod a+w /etc/consul.d	

fi

#Copy Files
cp /vagrant/etc/consul.d/nginx* /etc/consul.d/

#reload consul
killall -1 consul

set +x