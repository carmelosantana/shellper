#!/bin/sh
# Geekbench Installer
echo -n "Install + run geekbench? (y|n)"
read answer
if echo "$answer" | grep -iq "^n" ; then
	exit
fi
wget http://cdn.primatelabs.com/Geekbench-4.0.4-Linux.tar.gz
tar -zxvf Geekbench-4.0.4-Linux.tar.gz
cd build.pulse/dist/Geekbench-4.0.4-Linux/
./geekbench4