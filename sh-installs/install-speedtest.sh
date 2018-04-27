#!/bin/bash
# Install Speedtest CLI
# https://fossbytes.com/test-internet-speed-linux-command-line/
echo -n "Install + run Speedtest CLI? (y|n)"
read answer
if echo "$answer" | grep -iq "^n" ; then
	exit
fi
sudo apt-get install -y python-pip
pip install speedtest-cli
speedtest-cli