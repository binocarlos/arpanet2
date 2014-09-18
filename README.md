arpanet
=======

Auto linking multi-host docker cluster

![PDP-10](https://github.com/binocarlos/arpanet/raw/master/pdp-10.jpg)

Arpanet is a wrapper around the following tools:

 * [docker](https://github.com/docker/docker) - for running containers
 * [consul](https://github.com/hashicorp/consul) - for service discovery
 * [cadvisor](https://github.com/google/cadvisor) - for container metrics
 * [ambassadord](https://github.com/progrium/ambassadord) - for auto tcp routing
 * [registrator](https://github.com/progrium/registrator) - for announcing services to consul
 * [fleetstreet](https://github.com/binocarlos/fleetstreet) - for publishing container env to consul

It is an opinionated layer upon which you can create a Platform As A Service.

## quickstart

The quickstart list of commands:

### install

On each machine that is part of the cluster:

```bash
$ export ARPANET_IP=192.168.8.120
$ curl -sSL https://get.docker.io/ubuntu/ | sudo sh
$ sudo sh -c 'curl -L https://raw.githbusercontent.com/binocarlos/arpanet/v2.1.0/wrapper > /usr/local/bin/arpanet'
$ sudo chmod a+x /usr/local/bin/arpanet
$ sudo -E arpanet setup
$ arpanet pull
```

### run

On the first machine (192.168.8.120):

```bash
$ arpanet start:consul boot
```

On the other 2 'server' nodes:

```bash
$ ssh node2 arpanet start:consul server 192.168.8.120
$ ssh node3 arpanet start:consul server 192.168.8.120
```

Then start the service stack on all 3 servers:

```bash
$ arpanet start:stack
$ ssh node2 arpanet start:stack
$ ssh node3 arpanet start:stack
```

Now we can join more nodes in consul client mode:

```bash
$ ssh node4 arpanet start:consul client 192.168.8.120
$ ssh node4 arpanet start:stack
```

## installation

#### 1. environment

The variables you should set in your environment before running the arpanet container:

##### `HOSTNAME`

Make sure the hostname of the machine is set correctly and is different to other hostnames on your arpanet.

##### `ARPANET_IP`

The IP address of the interface to use for cross host communication.

This should be the IP of a private network on the host.

```bash
$ export ARPANET_IP=192.168.8.120
```

#### 2. install docker

```bash
$ curl -sSL https://get.docker.io/ubuntu/ | sudo sh
```

#### 3. install wrapper

Arpanet runs in a docker container that starts and stops containers on the main docker host.

Because of this, the container must be run with the docker socket mounted as a volume.

There is a wrapper script that will handle this neatly - to install the wrapper:

```bash
$ curl -L https://raw.githubusercontent.com/binocarlos/arpanet/v0.2.4/wrapper > /usr/local/bin/arpanet
$ chmod a+x /usr/local/bin/arpanet
```

#### 4. pull image

Next - pull the arpanet image (optional - it will pull automatically in the next step):

```bash
$ docker pull binocarlos/arpanet
```

#### 5. setup

Run the setup command as root - it will create the data folder, configure the docker DNS bridge and bind it to the ARPANET_IP tcp endpoint:

```bash
$ sudo -E $(arpanet setup)
```

#### 6. pull service images

Finally pull the docker images for the various services:

```bash
$ arpanet pull
```

Everything is now installed - you can `arpanet start` and `arpanet stop`


## run

The arpanet script runs in a docker container - this means the docker socket must be mounted as a volume each time we run.

The wrapper script (installed to /usr/local/bin) will handle this for you.

Or, if you want to run arpanet manually - here is an example of pretty much what the wrapper script does:

```bash
$ docker run --rm \
	-h $HOSTNAME \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e ARPANET_IP \
	binocarlos/arpanet help
```

## api

#### `arpanet setup`

```bash
$ sudo -E arpanet setup
```

This should be run as root and will perform the following steps:

 * bind docker to listen on the the tcp://$ARPANET_IP interface
 * connect the docker DNS resolver to consul
 * create a host directory for the consul data volume
 * restart docker

#### `arpanet pull`

This will pull the images used by arpanet services.

```bash
$ arpanet pull
```

#### `arpanet start:consul boot|server|client [JOINIP] [CONSUL_ARGS...]`

Start the consul container on this host.

There are 3 modes to boot a node:

 * boot - used for the very first node
 * server - used for other servers (consul server)
 * client - used for other nodes (consul agent)

```bash
$ arpanet start:consul server 192.168.8.120
```

You can pass consul arguments after the JOINIP (or after boot):

```bash
$ arpanet start:consul server 192.168.8.120 -node mycustomname -dc dc34
```

#### `arpanet start:stack`

Before you start the arpanet services the consul cluster must be booted and operational.

This means you must run the `start:consul` command on all 3 (or 5 etc) server nodes before running `arpanet start:stack` on any of them.

If you are adding a client node then the `start:stack` command can be run directly after the `start:consul` command (because the consul cluster is already up and running).

#### `arpanet stop`

Stop the arpanet containers.

```bash
$ arpanet stop
```

#### `arpanet info`

Print information about this node

#### `arpanet kv <command> [OPTIONS...]`

A CLI tool to read and write to the consul key value store.

Commands:

#### `arpanet kv info <key>`

#### `arpanet kv get <key>`

#### `arpanet kv get <key>`

#### `arpanet kv del <key>`

To delete a key recursively:

```bash
$ arpanet kv del folder/a?recurse
```

#### `arpanet kv ls <key>`

## booting a cluster

Boot a cluster of 5 nodes, with 3 server and 2 client nodes.

First stash the ip of the first node - we will 'join' the other nodes to here and the consul gossip protocol will catch up.

```bash
$ export JOINIP=192.168.8.120
```

Then boot the first node:

```bash
$ arpanet start:consul boot
```

Now - boot the other 2 servers:

```bash
$ ssh node2 arpanet start:consul server $JOINIP
$ ssh node3 arpanet start:consul server $JOINIP
```

When all 3 servers are started - it means we have an operational consul cluster and can start the rest of the arpanet service stack on the nodes:

```bash
$ arpanet start:stack
$ ssh node2 arpanet start:stack
$ ssh node3 arpanet start:stack
```

Now we can setup further clients:

```bash
$ ssh node4 arpanet start:consul client $JOINIP
$ ssh node4 arpanet start:stack
$ ssh node5 arpanet start:consul client $JOINIP
$ ssh node5 arpanet start:stack
```

We can now use `consul members` to check our cluster:

```bash
$ arpanet consul members
```

## config

there are other environment variables that control arpanet behaviour:

 * DOCKER_PORT - the TCP port docker should listen on (2375)
 * CADVISOR_PORT - the port to expose for the cadvisor api (8080)
 * CONSUL_PORT - the port to expose the consul HTTP api (8500)
 * CONSUL_EXPECT - the number of server nodes to auto bootstrap (3)
 * CONSUL_DATA - the host folder to mount for consul state (/mnt/arpanet-consul)
 * CONSUL_KV_PATH - the Key/Value path to use to keep state (/arpanet)

You can control the images used by arpanet services using the following variables:

 * CONSUL_IMAGE (progrium/docker-consul)
 * CADVISOR_IMAGE (google/cadvisor)
 * REGISTRATOR_IMAGE (progrium/registrator)
 * AMBASSADORD_IMAGE (binocarlos/ambassadord) - will change to progrium
 * FLEETSTREET_IMAGE (binocarlos/fleetstreet)

You can control the names of the launched services using the following variables:

 * CONSUL_NAME (arpanet_consul)
 * CADVISOR_NAME (arpanet_cadvisor)
 * REGISTRATOR_NAME (arpanet_registrator)
 * AMBASSADOR_NAME (arpanet_backends)
 * FLEETSTREET_NAME (arpanet_fleetstreet)

The wrapper will source these variables from `~/.arpanetrc` and will inject them all into the arpanet docker container.

If you are running arpanet manually then pass these variables to docker using `-e CONSUL_NAME=...`.

## security

A basic arpanet will use the private network of a single data centre.

Securing the network is left up to the user to allow for multiple approaches - for example:

 * use iptables to block unknown hosts
 * use a VPN solution to encrypt traffic between hsots

Future versions of arpanet will allow for consul TLS encryption meaning it can bind onto public Internet ports and use the multi data-centre feature securely.

## wishlist

 * TLS encryption between consul nodes & for docker server
 * Make the service stack configurable so services become plugins
 * Replicate the service stack via consul so we can manage services across the cluster

## big thank you to

 * [Jeff Lindsay](https://github.com/progrium)
 * [the docker team](https://github.com/docker/docker/graphs/contributors)
 * [the coreos team](https://github.com/coreos/etcd/graphs/contributors)
 

## license

MIT
