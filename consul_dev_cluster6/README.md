# Consul Encryption Gossip and RCP

Some references:

* https://www.consul.io/docs/agent/encryption.html
* https://www.digitalocean.com/community/tutorials/how-to-secure-consul-with-tls-encryption-on-ubuntu-14-04



## Getting Started

⚠️ ***This lab does not work without some preliminary configuration. Specifically the certificates for a CA and for every node that need to participate in the cluster need to be created and signed.***

<u>Instruction are explained below.</u>



1. Get the code

   ```
   git clone https://github.com/danielehc/consul_labs
   
   cd consul_labs/consul_dev_cluster6
   ```

2. Follow steps listed at [How to secure Consul with TLS encryption on Ubuntu 14.04](https://www.digitalocean.com/community/tutorials/how-to-secure-consul-with-tls-encryption-on-ubuntu-14-04) to generate the following files:

   ```
   etc/consul.d/ssl/ca.cert
   etc/consul.d/ssl/consul.cert
   etc/consul.d/ssl/consul.key
   ```

   ℹ️ For the lab the domain picked for the test is `dc1`so also the certificates are created as wildcard certificates for `*.dc1`.

3. Make sure files have the correct permissions

   ```
   chmod 0700 etc/ssl
   shmod 0600 etc/ssl/*
   ```

4. Start the Lab

   ```
   vagrant up
   ```



## Relevant Files

The configuration for Gossip and RPC Encryption is defined in `consul.default.json`:

```json
{
    "datacenter": "dc1",
    "data_dir": "/opt/consul/data",
    "client_addr": "0.0.0.0",
    "log_level": "INFO",
    "ui": true,
    "enable_script_checks" : true,
    "retry_join": [
        "172.20.20.11",
        "172.20.20.12",
        "172.20.20.13"
    ],
    "ca_file": "/etc/consul.d/ssl/ca.cert",
    "cert_file": "/etc/consul.d/ssl/consul.cert",
    "key_file": "/etc/consul.d/ssl/consul.key",
    "verify_incoming": true,
    "verify_outgoing": true,
    "encrypt": "91vHV0vyBY196vjy7MayHA=="
}
```



The `encrypt` parameter (explained in [encrypt](https://www.consul.io/docs/agent/options.html#encrypt)) is generated using the [consul keygen](https://www.consul.io/docs/commands/keygen.html) command.





