#!/bin/sh
# Install Speedtest CLI
# https://fossbytes.com/test-internet-speed-linux-command-line/
echo -n "Install + run Speedtest CLI? (y|n)"
read answer
if echo "$answer" | grep -iq "^y" ;then
	sudo apt-get install python-pip
	pip install speedtest-cli
	speedtest-cli
fi