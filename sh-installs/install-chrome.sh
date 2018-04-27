#!/bin/bash
echo -n "Install Google Chrome Stable? (y|n)"
read answer
if echo "$answer" | grep -iq "^n" ; then
	exit
fi

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
sudo apt-get update 
sudo apt-get install google-chrome-stable

# Source:
# https://askubuntu.com/questions/510056/how-to-install-google-chrome#510186