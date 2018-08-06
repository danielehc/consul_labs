# Exploring Consul ACL

Some references:

* https://www.consul.io/docs/guides/acl.html
* https://www.consul.io/api/acl.html



## Getting Started

1. Get the code

   ```
   git clone https://github.com/danielehc/consul_labs
   
   cd consul_labs/consul_dev_cluster5
   ```

2. Start the Lab

   ```
   vagrant up
   ```



## Relevant Files

* `etc/consul.d/consul.acl.json` defines the ACL for the server nodes

  ```json
  {
      "acl_master_token":"745d360a-d408-4a0d-9c3f-99d1a32a82c8",
      "acl_datacenter":"dc1",
      "acl_default_policy":"deny",
      "acl_down_policy": "extend-cache",
      "acl_token":"097ba0c4-b237-7b5c-4318-162e8db53127"
  }
  ```

* `etc/consul.d/consul.acl.json`defines the ACL for the client nodes

  ```json
  {
      "acl_datacenter":"dc1",
      "acl_down_policy":"extend-cache",
      "acl_token":"097ba0c4-b237-7b5c-4318-162e8db53127",
     "acl_agent_token":"a05fe9cc-6d55-958a-a19f-65bee0a7aa13"
  }
  ```

  

## Notes on Security

The lab uses always the same tokens to setup the ACL.

These are defined in `scripts/consul.sh`:

```bash
curl \
    --request PUT \
    --header "X-Consul-Token: 745d360a-d408-4a0d-9c3f-99d1a32a82c8" \
    --data \
	'{
	"ID": "097ba0c4-b237-7b5c-4318-162e8db53127",
	"Name": "ACL Token",
	"Type": "client",
	"Rules": "node \"\" { policy = \"write\" } service \"\" { policy = \"write\" }"
	}' http://${IP}:8500/v1/acl/create


	curl \
		--request PUT \
		--header "X-Consul-Token: 745d360a-d408-4a0d-9c3f-99d1a32a82c8" \
		--data \
	'{
	"ID": "a05fe9cc-6d55-958a-a19f-65bee0a7aa13",
	"Name": "Agent Token",
	"Type": "client",
	"Rules": "node \"\" { policy = \"write\" } service \"\" { policy = \"read\" }"
	}' http://${IP}:8500/v1/acl/create
```

Ideally you should either change these values after `git clone` or change the script to pick these values from environment variables.



