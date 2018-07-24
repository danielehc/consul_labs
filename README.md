# Consul Labs

This repository contains some environments I created while getting acquainted with Consul (https://www.consul.io/).



## Try it yourself

The only two requirements to try the labs are 

* **Vagrant** (https://www.vagrantup.com/) and 
* **Git** (https://git-scm.com/)



You can install them following the instructions provided on their respective websites.



Once the requirements are installed in your system you can try one of the labs by using the following commands:

```
git clone https://github.com/danielehc/consul_labs
cd consul_labs/consul_dev_clusterXYZ
vagrant up
```



## What are the labs doing

* ### Consul Dev Cluster 1

  Spins up a simple Consul cluster with 3 servers and 2 agents

* ### Consul Dev Cluster 2

  Spins up a Consul cluster with 3 servers and 3 agents. The 3 agents do the following:

  * **Agent 1:** Redis (https://redis.io/) server instance to be used by the other agents. Service and healthcheck are registered to Consul.
  * **Agent 2:** Simple bash application incrementing a value in Redis
  * **Agent 3:** Simple Go (https://golang.org/) application incrementing a value in Redis

* ### Consul Dev Cluster 3

  Spins up a Consul cluster with 3 servers and 2 agents. The agents do the following:

  - **Agent 1:** Redis server instance to be used by the other agents. Service and healthcheck are registered to Consul.
  - **Agent 2:**  
    - Go web application (listening on port `8080`) incrementing a value in Redis everytime a page is visited. The application is registered in Consul as a service and an healthcheck is present.
    - NGINX (https://www.nginx.com/) acts as a reverse proxy for the Go web application. The web server is registered in Consul as a service and an healthcheck is present.

* ### Consul Dev Cluster 4

  Spins up a Consul cluster with 3 servers and 4 agents. The agents do the following:

  - **Agent 1:** Redis server instance to be used by the other agents. Service and healthcheck are registered to Consul.
  - **Agent 2 add 3:**  
    - Two instances of the Go web application (listening on random port picked at startup) incrementing a value in Redis everytime a page is visited. The applications are registered in Consul as a service and an healthcheck is present.
  - **Agent 4:** NGINX acts as a reverse proxy and load balancer for the Go web application. The web server is registered in Consul as a service and an healthcheck is present. The LB configuration is changed automatically based on the apps random ports and is achieved using Consul Template (https://github.com/hashicorp/consul-template)

  

## FAQ

**Q:** I found something wrong in your code. Why you did such a thing?

**A:** I am learning, most of the things here are/were completely new to me. Please be patient and open a PR in case you want to help me learn.

