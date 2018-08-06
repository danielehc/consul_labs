#!/usr/bin/env bash

ACL_MASTER_TOKEN="745d360a-d408-4a0d-9c3f-99d1a32a82c8"

# set -x

ACL_TOKEN=`curl -s \
    --request PUT \
    --header "X-Consul-Token: ${ACL_MASTER_TOKEN}" \
    --data \
'{
  "Name": "ACL Token",
  "Type": "client",
  "Rules": "node \"\" { policy = \"write\" } service \"\" { policy = \"write\" }"
}' http://172.20.20.11:8500/v1/acl/create | jq .ID | sed 's/"//g'`

AGENT_TOKEN=`curl -s \
    --request PUT \
    --header "X-Consul-Token: ${ACL_MASTER_TOKEN}" \
    --data \
'{
  "Name": "Agent Token",
  "Type": "client",
  "Rules": "node \"\" { policy = \"write\" } service \"\" { policy = \"read\" }"
}' http://172.20.20.11:8500/v1/acl/create | jq .ID | sed 's/"//g'`


echo "ACL: $ACL_TOKEN"
echo "AGENT: $AGENT_TOKEN"

if [[ "$1" != "all" ]]; then
    echo -e "##############################\n\n\n"
    echo -e ",\n \"acl_token\":\"${ACL_TOKEN}\",\n\"acl_agent_token\":\"${AGENT_TOKEN}\"\n"
    echo -e "\n\n\n##############################"
    exit 0
fi

tee ./etc/consul.d/tmp.consul.acl.agent.json <<EOF
{
    "acl_datacenter":"dc1",
    "acl_down_policy":"extend-cache",
    "acl_token":"${ACL_TOKEN}",
    "acl_agent_token":"${AGENT_TOKEN}"
}
EOF

tee ./etc/consul.d/tmp.consul.acl.json <<EOF
{
    "acl_master_token":"${ACL_MASTER_TOKEN}",
    "acl_datacenter":"dc1",
    "acl_default_policy":"deny",
    "acl_down_policy": "extend-cache",
    "acl_token":"${ACL_TOKEN}",
    "acl_agent_token":"${AGENT_TOKEN}"
}
EOF

for i in `vagrant status | grep running | grep -v consul | awk '{print $1}'`; do vagrant ssh $i -c 'sudo cp /vagrant/etc/consul.d/tmp.consul.acl.agent.json /etc/consul.d/consul.acl.agent.json'; sleep 1; done
for i in `vagrant status | grep running | grep consul | awk '{print $1}'`; do vagrant ssh $i -c 'sudo cp /vagrant/etc/consul.d/tmp.consul.acl.json /etc/consul.d/consul.acl.json'; sleep 1; done







for i in `vagrant status | grep running | awk '{print $1}'`; do vagrant ssh $i -c 'sudo killall -1 consul'; sleep 1; done



# set +x