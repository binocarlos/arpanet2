design notes
============

This is a rough brain-storm document that outlines where this project is heading - it is by no means complete and provides more of a 'what is this all about' document than a detailed spec.

issues/PR's are welcome :-)

## background

arpanet2 is a system that enables a user to describe a stack of micro-services using a fig file and to run those services (in containers) on a cluster of physical hosts.

It will automatically connect the containers to each other using weave and will automatically load-balance across multiple copies of a single service.

## ingredients

There are several parts to the puzzle in order to make this system work:

#### fig.yml

The fig.yml will describe the micro-services in a single, standard fig file.

Here is an example of a fig file that we will use throughout the rest of this document:

```yaml
web:
  build: web
  ports:
    - 80
  links:
    - auth
    - catalogue
auth:
  build: auth
  ports:
    - 80
  links:
    - redis
catalogue:
  image: acmeinc/productcatalog
  ports:
    - 80
  links:
    - redis
    - pricing
pricing:
  build: pricing
  ports:
    - 80
redis:
  image: redis
```

There are 5 services in our stack:

 * web - the front facing HTTP web server that returns HTML / Ajax responses to browsers
 * auth - the authentication server that can log users in & out
 * catalogue - provide product listings to the web service - use the pricing service to calculate prices
 * pricing - a stateless service that has alogorithms for pricing that the catalogue will use
 * redis - standard database

This is an arbritrary collection of services - you can imagine any number of complex scenarios being developed.

#### links

Some services are linked to others.  In a standard fig setup (i.e. single host) - this is done using `docker --link` commands.

When a service is linked to another - docker makes a hostname entry in the linked from container.  So in our example - the `catalogue` container can access the `pricing` container's IP address by literally using the hostname `pricing`.  Docker makes an entry in `/etc/hosts` to make this work.

It is this simplicity we want to replicate but with multiple copies of the pricing service running on multiple physical hosts.

#### weave & consul

The solution is to replace the standard `docker --link` command with [weave](https://github.com/zettio/weave) and [consul](https://github.com/hashicorp/consul).

The following is a breakdown of the various pieces of the puzzle.

#### deployments

A deployment means a set of containers that have been started as a cohesive unit (i.e. fig file).  Each deployment will have an id from somewhere - this allows us to identify and separate different deployments of the same stack.  This means that the `pricing` service from deployment `abc` can be distinquished from the `pricing` service from deployment `xyz`.

#### service

A service is a single named entity in the fig.yml.  A service may represent multiple containers based on scale.  In our example `pricing` is a service.

#### scheduler

The scheduler will be based on [mdock](https://github.com/binocarlos/mdock) which means the standard fig client can speak to it.  It will use [dowding](https://github.com/binocarlos/dowding) to decide which machine to allocate each container onto and [cluster-advisor](https://github.com/binocarlos/cluster-advisor) to decide which machine is busy / not busy.

The concept here is very similar to [docker swarm](https://github.com/docker/swarm) and [powerstrip](https://github.com/clusterhq/powerstrip) i.e. present a standard docker HTTP api so that tools like fig can speak with it.

#### leader

There can be multiple schedulers in the cluster but they will all route to the current leader.

The leader is choosen using the consul [leader election module](http://www.consul.io/docs/guides/leader-election.html) and all non-leader schedulers proxy to the current leader so any scheduler endpoint can be used.

This means that if a scheduler goes down another will pick up the slack and state is maintained by the consul raft setup.

#### DHCP

When the scheduler sees a container being allocated to a server - it will need a weave IP address.  This is a stateful operation that needs to be aware of previous allocations (to avoid giving 2 containers the same IP).

The DHCP server has 2 jobs:

 * to allocate a subnet to a deployment
 * to allocate an IP address inside that subnet to each container in a deployment

Here is the information the DHCP service needs to allocate a subnet to a deployment:

 * currently running deployments and their subnets
 * the size of the deployment (will it need 255 or many more IP addresses)
 * the entire subnet available to the DHCP service (i.e. are there restrictions on the 10. namespace for weave)

Here is the information the DHCP service needs to know to allocate a weave IP to a container:

 * the subnet allocated to the containers deployment
 * the IP addresses already allocated in the containers deployment

Once the DHCP server has allocated a containers IP address - the fact it has been allocated and the deployment/service/container it has been allocated to is saved in consul.

#### consul service registration

When we have an IP address for a service container and after the container has started - we will register that IP with the consul service catalogue.

We register it as an external service because it has a custom (weave) IP address.

For example - lets take 2 deployments `abc` and `xyz` - both with `pricing` services that both have 2 copies running.

The full service name for deployment `abc` will be `pricing.abc` and for `xyz` it is `pricing.xyz` - these are the names we register with consul as the service names.

#### dns-search

To allow a different service container to use the hostname `pricing` and for this to point to only containers within the same deployment - we need to use a custom `dns-search` property for containers.

So - for ALL service containers in the `abc` deployment - we tell docker that the `--dns-search` value is `abc.service.consul`.

This means that for any service container in the `abc` deployment - we can now use the hostname `pricing` and it will load-balance to the 2 `pricing` containers in the `abc` deployment.

#### powerstrip

Running on each physical docker host is a copy of powerstrip and powerstrip-weave.  This makes actually allocating the weave IP addresses very easy because all the scheduler as to do is create an environment variable for the IP provided by the DHCP server.

## summary

 * a "stack" is a vanilla fig.yml which will work with normal "fig up" - the user says "DOCKER_HOST=tcp://arpanet:2375 fig up" to have arpanet features
 * there is a scheduler much like docker swarm - this enables decisions to be made and /container/create requests modified a bit like powerstrip
 * there is an auto IP address allocator (which I'm badly calling DHCP)
 * there are "deployments" which get allocated a subnet for all containers in the deployment 
 * deployments have an id - for example "abc"
 * register services (e.g. "apples") with consul as combo of service name from fig.yml and deployment name e.g. ServiceID="1.apples.abc" and ServiceName="apples.abc"
 * there can be multiple copies of the service e.g. "2.apples.abc" & "3.apples.abc" so we can scale - all are known as ServiceName "apples.abc"
 * Now - from any other container in the deployment, you could connect to apples using the hostname "apples.abc.service.consul"
 * Start containers with "--dns-search abc.service.consul"
 * Now - any other container in the deployment can use the hostname "apples" to get to all 3 containers

## license

MIT
