arpanet2
========

WORK IN PROGRESS - not ready to use

Networking and service discovery for docker clusters.

![Whirlwind magnetic-core memory banks](https://github.com/binocarlos/arpanet2/raw/master/whirlwind.jpg)

arpanet2 is a wrapper around the following tools:

 * [docker](https://github.com/docker/docker) - running containers
 * [consul](https://github.com/hashicorp/consul) - service discovery
 * [weave](https://github.com/zettio/weave) - overlay network

It's an opinionated layer upon which you can create a Platform As A Service and is the natural successor to [arpanet](https://github.com/binocarlos/arpanet)

## quickstart

### install

First, make sure you have set the hostname of your machine

Then install docker:

```bash
$ curl -sSL https://get.docker.io/ubuntu/ | sudo sh
```

and arpanet2:

```bash
$ sudo sh -c 'curl -L https://raw.githbusercontent.com/binocarlos/arpanet2/master/arpanet2 > /usr/local/bin/arpanet2'
$ sudo chmod a+x /usr/local/bin/arpanet2
$ sudo -E arpanet2 install
```

### start

Pick an un-used arpanet address which is one half of an IP address (for example 0.1)

On the initial node - run the boot command:

```bash
node1$ sudo arpanet2 boot 0.1 Apples
```

Then on the second node we connect to both the arpanet and the normal IP from the first node:

```bash
node2$ sudo arpanet2 join:server 0.2 Apples 192.168.8.120 0.1
```

We can then start other servers (3 is recommended) and clients:

```bash
node14$ sudo arpanet2 join:client 0.14 Apples 192.168.8.120 0.1
```

## about

### weave IP assignment
We run a weave network of `10.0.0.0/8`.

We can think of an `arpanet2` address as `2.12` which would yield:

 * 10.255.2.12 - weave
 * 10.254.2.12 - docker
 * 10.253.2.12 - consul

This means we have a predictable addressing scheme for the arpanet system layer.

10.241.0.0 -> 10.252.0.0 are reserved for arpanet2 plugins.

10.0.0.0 -> 10.240.0.0 are reserved for application containers.

Application containers can be isolated from the arpanet2 layer by using /16 or greater.

### consul
We run consul inside a container and assign it the consul arpanet address (10.254.x.x)

Consul also binds onto 127.0.0.1 for all ports apart from DNS.

The DNS is bound onto the docker bridge and docker is configured to use the consul DNS.

DNS related docker opts (auto-generated):

```
--dns 172.17.42.1 --dns 8.8.8.8 --dns-search service.consul
```

### docker

We leave the UNIX socket alone and also listen to tcp://10.254.0.1:2375 (where the arpanet2 address is 0.1)

We then `weave expose` 10.254.0.1

The weave network (anything on /8) can now access the docker socket without it being exposed from the host.

### setup host

Commands to configure networking for a weave host - arpanet2 address = `0.1`:

First server (192.168.8.120):

```
$ sudo arpanet2 boot 0.1 Apple
```

The commands being done:

```
$ sudo weave launch 10.255.0.1/8 -password Apple
$ do "write docker config with 10.254.0.1:2375 & restart"
$ sudo weave expose 10.254.0.1/8
```

Second server:

```
$ sudo arpanet2 server 0.2 Apple 0.1 192.168.8.120
```

Client:

```
$ sudo arpanet2 client 4.22 Apple 0.1 192.168.8.120
```



## license

MIT
