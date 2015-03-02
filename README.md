arpanet2
========

WORK IN PROGRESS - not ready to use

[design notes for next steps](https://github.com/binocarlos/arpanet2/blob/master/designnotes.md)

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
$ sudo sh -c 'curl -L https://raw.githubusercontent.com/binocarlos/arpanet2/master/arpanet2 > /usr/local/bin/arpanet2'
$ sudo chmod a+x /usr/local/bin/arpanet2
$ sudo -E arpanet2 install
```

## architecture

arpanet2 runs on each physical host - this means that docker, consul and weave are running on the host.

When containers are started - they are analyzed (by watching the docker event stream) for WEAVE_IP env variables.  This enables us to assign a weave IP to a container.

The "name" and/or the "hostname" of the container determines the "service name" it provides.

We can then register the IP address as an external service with consul.

From any of our services - we can now load balance to multiple copies of another services all by hostname.

This means that we dont need to use SRV DNS records and can access all our services on standard ports.

## example

Imagine we have a stack like this:

```yaml
web:
  run: node web/index.js
  scale: 10
api:
  run: node api/index.js
  scale: 5
```

This means we will have 10 web servers and 5 api servers.

The scheduler should run each web server on a different server (i.e. there are not 2 web servers on the same physical host).

The key thing is that from inside the web server - we should be able to load balance to our 5 api servers by just using the hostname `api`:

```js
hyperquest('api').pipe(concat(function(reply){

  // we have a reply from the 'api' host

}))
```

In this example:

 * a web server asks to resolve the "api" hostname
 * the container (and docker) is hooked up to use consul DNS on the machine
 * there are 5 services registered with consul for "api"
 * consul returns one of them as a standard A record (i.e. just IP address)
 * the A record is a weave IP
 * communication happens over the weave bridge

Advantages of this approach:

 * Zero code needed to for load balancing in user app
 * Access any of your micro-services by just using their names
 * Cross data-centre secure communciation using weave

## license

MIT
