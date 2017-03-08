#!/bin/bash
# Webmin Installer
echo -n "Install Webmin? (y|n)"
read answer
if echo "$answer" | grep -iq "^n" ; then
	exit
fi

# needed to add key
sudo apt-get install debian-keyring

# setup key + repo
wget http://www.webmin.com/jcameron-key.asc
chmod 777 jcameron-key.asc
sudo apt-key add jcameron-key.asc
echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" | sudo tee -a /etc/apt/sources.list

# install webmin
sudo apt-get update | sudo apt-get install -y --allow-unauthenticated webmin