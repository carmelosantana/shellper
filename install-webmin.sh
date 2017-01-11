#!/bin/sh
# Webmin Installer
# Version 0.2.1
echo "Install webmin?"
echo -n "Press y|Y to continue, any other key for No: "
read answer
	if echo "$answer" | grep -iq "^y" ;then
	wget -O - http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
	echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
	echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
	sudo apt-get update | sudo apt-get install -y webmin
fi