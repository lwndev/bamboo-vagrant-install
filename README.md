bamboo-vagrant-install
===================

A project that uses Vagrant and Puppet to create and boot either a VirtualBox VM or Amazon EC2 instance and then download and install a copy of Bamboo 4.4.5.  

## Notes

1. This is intended as a proof of concept and is not intended to be a full provisioning solution for Bamboo.
2. You will need to supply your own Bamboo license.
3. You will need an Amazon Web Services account to use the AWS provider
4. A quick-start guide for using this project is available [here](http://www.lwndev.com/posts/2013/4/21/tutorial-using-the-vagrant-aws-provider-plugin-to-create-a-bamboo-ci-server-in-the-cloud)
5. Credit where credit is due: This project is based off of Nicola Paolucci's Stash provisioning example https://bitbucket.org/durdn/stash-vagrant-install.git. Check out https://blogs.atlassian.com/2013/03/instant-java-provisioning-with-vagrant-and-puppet-stash-one-click-install/ for more details

## Dependencies

1. [Vagrant](http://downloads.vagrantup.com/)
2. [VirtualBox (for local servers)](https://www.virtualbox.org/wiki/Downloads)
3. [Vagrant AWS Provider Plugin (for EC2-based servers)](https://github.com/mitchellh/vagrant-aws)
4. [An Amazon Web Services Account (for EC2-based servers)](http://aws.amazon.com)

## Usage

### Local Bamboo Server

	$ git clone https://github.com/lwndev/bamboo-vagrant-install.git && cd bamboo-vagrant-install
	$ vagrant up --provider=virtualbox

Once Bamboo is up and running you can access it at http://192.168.33.12

### Bamboo Server on Amazon EC2

	$ git clone https://github.com/lwndev/bamboo-vagrant-install.git && cd bamboo-vagrant-install
	$ vagrant up --provider=aws

Once Bamboo is up and running you can access it using the URL provided by Amazon in your AWS Management console.
