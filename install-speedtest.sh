#!/bin/sh
# Install Speedtest CLI
# Version 0.1
# https://fossbytes.com/test-internet-speed-linux-command-line/
echo "Install Speedtest CLI?"
echo -n "Press y|Y to continue, any other key for No: "
read answer
if echo "$answer" | grep -iq "^y" ;then
	sudo apt-get install python-pip --fix-missing
	pip install speedtest-cli
	speedtest-cli
fi