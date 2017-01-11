#!/bin/sh
# Geekbench Installer
# Version 0.2.1
echo "Install+run geekbench?"
echo -n "Press y|Y to continue, any other key for No: "
read answer
if echo "$answer" | grep -iq "^y" ; then
	wget http://cdn.primatelabs.com/Geekbench-4.0.1-Linux.tar.gz
	tar -zxvf Geekbench-4.0.1-Linux.tar.gz
	cd build.pulse/dist/Geekbench-4.0.1-Linux/
	./geekbench4
fi