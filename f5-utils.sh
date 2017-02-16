#!/bin/bash
# First 5 minutes Utils Installer
# Version: 0.1

# Distros:
# ✔ Ubuntu 16.04.1

# Hosts:
# ✔ Baremetal
# ✔ AWS EC2
# ✔ GoDaddy Cloud
# ✔ Linode

# TODO:
# ☐ Add bzopen, bzcompress

# Start
echo "
----------------------
First 5 Minutes: Utils
----------------------
System:
  Distro update + upgrade

Utilities:
  debian-keyring
  fish
  git
  htop
  screen
  Webmin"

# continue with this?
echo ""
echo -n "Continue? (y|n) "
read answer
if echo "$answer" | grep -iq "^n"; then
	exit 1
fi

# unattended
echo -n "Unattended install? (y|n) "
read answer
if echo "$answer" | grep -iq "^y"; then
	UNATTENDED=1
else
	UNATTENDED=0	
fi

# upgrade, update
sudo apt-get update
sudo apt-get upgrade -y

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

# utilities
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install postfix
sudo apt-get -y install fish git htop screen

# cron
if [ "$UNATTENDED" = "0" ]; then
	echo -n "Setup daily email for critical entries via cron.daily? (enter@youremail.com|n) "
	read answer
	if echo "$answer" | grep -iq "^n"; then
		echo ""
	else	
		sudo echo "/usr/sbin/logwatch --output mail --mailto $answer --detail high" > /etc/cron.daily/logwatch
	fi
fi

# thats it
echo ""
echo "-----------------"
echo "Install complete!"
echo "-----------------"
echo ""