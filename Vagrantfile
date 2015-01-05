# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "hansode/centos-6.6-x86_64"

  config.ssh.forward_agent = true


  config.vm.define "vnmgr_vna1" do |node|
    node.vm.hostname = "vnmgrvna1"
    #node.vm.provision "shell", path: "bootstrap.sh"     # Bootstrapping: package installation (phase:1)
    #node.vm.provision "shell", path: "config.d/base.sh" # Configuration: node-common          (phase:2)
    #node.vm.provision "shell", path: "config.d/vnmgr_vna1.sh" # Configuration: node-specific (phase:2.5)
    # node.vm.network :private_network, ip: "10.100.0.2", virtualbox__intnet: "intnet1"
    # node.vm.network :private_network, ip: "172.16.9.10", virtualbox__intnet: "intnet2"

    node.vm.provider :virtualbox do |v, override|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]

      v.customize ["modifyvm", :id, "--nic2", "intnet"]
      v.customize ["modifyvm", :id, "--nictype2", "Am79C973"]
      v.customize ["modifyvm", :id, "--macaddress2", "020200000001"]
      v.customize ["modifyvm", :id, "--intnet2", "intnet1"]
      v.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]

      v.customize ["modifyvm", :id, "--nic3", "intnet"]
      v.customize ["modifyvm", :id, "--nictype3", "Am79C973"]
      v.customize ["modifyvm", :id, "--intnet3", "intnet2"]
      v.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
    end
  end

  config.vm.define "vna2" do |node|
    node.vm.hostname = "vna2"
    node.vm.provision "shell", path: "bootstrap.sh"     # Bootstrapping: package installation (phase:1)
    node.vm.provision "shell", path: "config.d/base.sh" # Configuration: node-common          (phase:2)
    node.vm.provision "shell", path: "config.d/vna2.sh" # Configuration: node-specific (phase:2.5)
    # node.vm.network :private_network, ip: "10.100.0.3", virtualbox__intnet: "intnet1"
    # node.vm.network :private_network, ip: "172.16.9.11", virtualbox__intnet: "intnet2"

    node.vm.provider :virtualbox do |v, override|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]

      v.customize ["modifyvm", :id, "--nic2", "intnet"]
      v.customize ["modifyvm", :id, "--nictype2", "Am79C973"]
      v.customize ["modifyvm", :id, "--macaddress2", "020200000002"]
      v.customize ["modifyvm", :id, "--intnet2", "intnet1"]
      v.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]

      v.customize ["modifyvm", :id, "--nic3", "intnet"]
      v.customize ["modifyvm", :id, "--nictype3", "Am79C973"]
      v.customize ["modifyvm", :id, "--intnet3", "intnet2"]
      v.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
    end
  end

  # config.vm.define "router" do |node|
  #   node.vm.hostname = "router"
  #   node.vm.provision "shell", path: "config.d/router.sh" # Configuration: node-specific (phase:2.5)
  #   node.vm.network :private_network, ip: "10.100.0.1", virtualbox__intnet: "intnet1"
  #   node.vm.network :private_network, ip: "172.16.9.1", virtualbox__intnet: "intnet2"
  #   node.vm.network :private_network, ip: "10.101.0.1", virtualbox__intnet: "intnet3"
  # end

  # config.vm.define "vna3" do |node|
  #   node.vm.hostname = "vna3"
  #   node.vm.provision "shell", path: "bootstrap.sh"     # Bootstrapping: package installation (phase:1)
  #   node.vm.provision "shell", path: "config.d/base.sh" # Configuration: node-common          (phase:2)
  #   node.vm.provision "shell", path: "config.d/vna3.sh" # Configuration: node-specific (phase:2.5)
  #   node.vm.network :private_network, ip: "10.101.0.2", virtualbox__intnet: "intnet3"
  #   node.vm.network :private_network, ip: "172.16.9.12", virtualbox__intnet: "intnet2"
  # end

  # config.vm.define "edge" do |node|
  #   node.vm.hostname = "edge"
  #   node.vm.provision "shell", path: "bootstrap.sh"     # Bootstrapping: package installation (phase:1)
  #   node.vm.provision "shell", path: "config.d/base.sh" # Configuration: node-common          (phase:2)
  #   node.vm.provision "shell", path: "config.d/vnmgr_vna1.sh" # Configuration: node-specific (phase:2.5)
  #   node.vm.network :private_network, ip: "10.100.0.4", virtualbox__intnet: "intnet1"
  #   node.vm.network :private_network, ip: "172.16.9.13", virtualbox__intnet: "intnet2"
  #   node.vm.network :private_network, ip: "192.168.1.10", virtualbox__intnet: "intnet4"
  # end
end
