#!/bin/bash
# Webmin Installer
echo -n "Install Webmin? (y|n)"
read answer
if echo "$answer" | grep -iq "^n" ; then
	exit
fi

# apt
curl -s http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" | sudo tee -a /etc/apt/sources.list

# install webmin
sudo apt-get update
sudo apt-get install -y webmin