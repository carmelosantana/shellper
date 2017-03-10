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
# ☐ Check if logwatch cron is working

# Start
echo "
----------------------
First 5 Minutes: Utils
----------------------
System:
  Distro update + upgrade

Utilities:
  fish
  git
  glances
  htop
  screen
  Webmin"

# continue with this?
echo ""
echo -n "Install utilities? (y|n) "
read answer
if echo "$answer" | grep -iq "^n"; then
	exit 1
fi

# upgrade, update
sudo apt-get update
sudo apt-get upgrade -y

# apt
curl -s http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" | sudo tee -a /etc/apt/sources.list

# install webmin
sudo apt-get update
sudo apt-get install -y webmin

# utilities
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install postfix
sudo apt-get -y install fish git glances htop screen

# thats it
echo "Install complete."