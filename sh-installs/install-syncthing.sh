#!/bin/bash
echo -n "Install Syncthing? (y|n)"
read answer
if echo "$answer" | grep -iq "^n" ; then
	exit
fi

# apt
curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
echo "deb https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
sudo apt-get update
sudo apt-get install -y syncthing
sudo ufw allow syncthing
sudo ufw allow syncthing-gui