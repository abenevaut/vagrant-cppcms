[![Build Status](https://travis-ci.org/42antoine/vagrant-cppcms.svg?branch=master)](https://travis-ci.org/42antoine/vagrant-cppcms)

# vagrant-cppcms

Bootstrap VM for CPPCMS

###### /!\ Project for developers - never use this project to make production server!

# Install vagrant

Go to https://www.vagrantup.com/downloads.html and download / install vagrant for your system.

## Install Virtualbox

Vagrant works with a vm manager, by default you can work with virtualbox.

Go to  https://www.virtualbox.org/wiki/Downloads and download / install vagrant for your system.

# Deploy your server

Clone this repository :

	$> git clone https://github.com/42antoine/vagrant-cppcms.git
	$> cd vagrant-cppcms
	$> vagrant up
	$> vagrant ssh
	$> cd www
	$> ./hello -c config.js

## Services

Your server is now running on !

### MySQL

	- username : root
	- password : vagrant

### Apache2

On the vagrant vm, a web server is installed. You can access it via 127.0.0.1:8080
An "Hello World" cppcms website is available, and you need to run it to show something!

	$> vagrant ssh
	$> cd www
	$> ./hello -c config.js

You can also use phpmyadmin at this address 127.0.0.1:8080/phpmyadmin

All website content is available from you computer in : vagrant-cppcms/www *(1)

#### technical

We use Apache2 mod_scgi to pipe CPPCMS website to Apache2 output (port 80 on vagrant).
All CPPCMS website have to use the "scgi" API and the port 8080 inside config.js file.

	{
	    "service" : {
	        "api" : "scgi",
	        "ip" : "127.0.0.1",
	        "port" : 8080
	    },
	    "http" : {
	        "script_names" : [ "/hello" ]
	    }
	}

## VM file sharing

*(1) : On project root directory, you can see "www" directory. This folder is shared from VM, use it to share cppcms source/website with the VM.

## CPPCMS & CPPDB

At provisionning, the vagrant vm install CPPCMS (1.0.5) and CPPDB (0.3.1).
All libraries are stored at this path : /usr

## See also

http://cppcms.com
http://cppcms.com/wikipp/en/page/cppcms_1x_tut_hello

