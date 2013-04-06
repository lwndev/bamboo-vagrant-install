bamboo-vagrant-install
===================

A project that uses Vagrant and Puppet to create and boot a VirtualBox VM and then to download and install a copy of Bamboo 4.4.5.  This project is very closely based off of Nicola Paolucci's Stash provisioning example https://bitbucket.org/durdn/stash-vagrant-install.git

Check out https://blogs.atlassian.com/2013/03/instant-java-provisioning-with-vagrant-and-puppet-stash-one-click-install/ for more details

# Dependencies

1. Vagrant
2. VirtualBox

# Usage

	$ git clone https://github.com/lwndev/bamboo-vagrant-install.git && cd bamboo-vagrant-install
	$ vagrant up

Once Bamboo is up and running you can access it at http://localhost:8085 or http://192.168.33.12