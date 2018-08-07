apt-get autoremove -y
apt-get clean

/usr/sbin/waagent -force -deprovision+user
export HISTSIZE=0
sync