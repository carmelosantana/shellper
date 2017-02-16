#!/bin/sh
# Geekbench Installer
echo -n "Install + run geekbench? (y|n)"
read answer
if echo "$answer" | grep -iq "^y" ; then
	wget http://cdn.primatelabs.com/Geekbench-4.0.1-Linux.tar.gz
	tar -zxvf Geekbench-4.0.1-Linux.tar.gz
	cd build.pulse/dist/Geekbench-4.0.1-Linux/
	./geekbench4
fi