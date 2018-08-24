# Exploring Consul Multiple Datacenters

Some references:

* https://www.consul.io/docs/guides/datacenters.html



## Getting Started

1. Get the code

   ```
   git clone https://github.com/danielehc/consul_labs
   
   cd consul_labs/consul_dev_cluster7
   ```

2. Start the Lab

   ```
   vagrant up
   ```



## Configure Number of nodes in a cluster

The recommended number of nodes for a Consul cluster is 3 or 5 but, for this lab, we will spin up 2 clusters and having 6 VM plus some other nodes for the services we want to provision might be an high toll even for the most recent machines.

To tune this, `Vagrantfile` contains the following line:

```bash
SERVER_COUNT = 1
```

that will set, by default, the number of nodes in a cluster to 1.

This will make Consul express some concern at startup:

 ```
dc1-consul1: BootstrapExpect is set to 1; this is the same as Bootstrap mode.
dc1-consul1: bootstrap = true: do not enable unless necessary
 ```

Modify the value of the variable to 3 or 5 if you want a cluster composed by multiple nodes.



## IP Ranges and Machine names

### IPs

The configuration is made in such a way that Consul servers will have an IP such as

`10.10.DC_NUM*10.SERVER_NUM+10`

So for example:

* Consul server one of DC1 will have IP: `10.10.10.11`

* Consul server two of DC2 will have IP: `10.10.20.12`



Using this nomenclature and the variable `SERVER_COUNT` previously set,  the `consul.sh` script automates some of the startup parameters:

* **Cluster Join**

```bash
# Part of the IP defining a single DC (e.g. 10.10.10)
DC_RANGE=`echo $IP | awk '{split($0, a, "."); print a[1]"."a[2]"."a[3]}'`

JOIN_STRING=""
for i in `seq 1 $SERVER_COUNT`; do
	JOIN_STRING="$JOIN_STRING -retry-join=$DC_RANGE.$((10 + i))"
done
```

* **DC Join**

```bash
# Part of the IP defining the network (e.g. 10.10)
NET_RANGE=`echo $IP | awk '{split($0, a, "."); print a[1]"."a[2]}'`

JOIN_WAN_STRING=""
for j in 10 20; do
	for i in `seq 1 $SERVER_COUNT`; do
		JOIN_WAN_STRING="$JOIN_WAN_STRING -retry-join-wan=${NET_RANGE}.${j}.$((10 + i))"
	done
done
```

:information_source: The script only expects the creation of one or two datacenters. The script is not yet capable of understanding that more than two datacenters are being created.

### Hostnames

The configuration is made in such a way that Consul servers will have an hostname such as `DC_NAME-service_name` .

For Consul servers `machine_name` is defined as `consulX` where `X` is the instance number.

So for example:

- Consul server one of DC1 will have hostname: `dc1-consul1`

- Consul server two of DC2 will have hostname: `dc2-consul2`
- Redis server on DC2 will have hostname: `dc2-redis`

Using this nomenclature  the `consul.sh` script automates some of the startup parameters:

```bash
if [[ "${HOSTNAME}" =~ "consul" ]]; then
	echo "Configure node ${HOSTNAME} as Server"
	...	
else
	echo "Configure node ${HOSTNAME} as Client Agent"
	...
fi
```

