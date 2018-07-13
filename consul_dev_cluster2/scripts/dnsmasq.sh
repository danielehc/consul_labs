#!/usr/bin/env bash

set -x

which dnsmasq  2>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y dnsmasq
}

if [ ! -f "/etc/dnsmasq.d/10-consul" ]; then
	
	# Creates folder
	sudo mkdir -p /etc/dnsmasq.d
	sudo chmod a+w /etc/dnsmasq.d	
	
	#Copy Files
	cp /vagrant/etc/dnsmasq_consul.conf /etc/dnsmasq.d/10-consul
	mv /etc/resolv.conf /etc/resolv.conf.orig
	cat /vagrant/etc/dnsmasq_resolv.conf /etc/resolv.conf.orig > /etc/resolv.conf

	service dnsmasq restart

fi

set +x
