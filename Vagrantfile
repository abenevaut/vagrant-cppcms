# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below.
Vagrant.configure(2) do |config|

  config.vm.box = "vagrant-debian-11.7.0-amd64"
  config.vm.box_url = "https://pub.abenevaut.dev/debian-11.7.0-amd64/package.box"

  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine.  
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 8080, host: 8081

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder "./www", "/home/vagrant/www"

  # Provision script
  config.vm.provision "shell", path: "shell.sh", privileged: false

end
