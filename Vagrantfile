# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
PROJECTS_HOME = ENV['PROJECTS_HOME'] || "../"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "puppetlabs/ubuntu-14.04-64-nocm"
  
  config.vm.provision "shell", inline: <<SCRIPT
    # install
SCRIPT

  config.vm.define "node1" do |node|
    node.vm.network "private_network", ip: "192.168.8.120"
    node.vm.network :forwarded_port, guest: 443, host: 443
    node.vm.network :forwarded_port, guest: 80, host: 8080
    node.vm.hostname = "node1"
    node.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end
    if PROJECTS_HOME
      node.vm.synced_folder PROJECTS_HOME, "/srv/projects"
    end
  end

  config.vm.define "node2" do |node|
    node.vm.network "private_network", ip: "192.168.8.121"
    node.vm.hostname = "node2"
    node.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end
    if PROJECTS_HOME
      node.vm.synced_folder PROJECTS_HOME, "/srv/projects"
    end
  end

  config.vm.define "node3" do |node|
    node.vm.network "private_network", ip: "192.168.8.122"
    node.vm.hostname = "node3"
    node.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end
    if PROJECTS_HOME
      node.vm.synced_folder PROJECTS_HOME, "/srv/projects"
    end

  end
end