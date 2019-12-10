#!/bin/bash
source "$(pwd)/shellper.sh"
source "$(pwd)/linode/stackscripts/1.sh"

echo "
---------------------
First 5 Minutes: LAMP
---------------------
System:
  Distro update + upgrade
  Create sudo user

Security:
  ufw
  unattended-upgrades

Services:
  apache2
  php fpm
  MariaDB or MySQL
  Memcached
  postfix"

#TODO: add $1, and skip after sudo user crteatre

# unattended
echo
echo -n "Unattended install? (y)Yes (n)No (q)Quit: "
read answer
if echo "$answer" | grep -iq "^y"; 
	then UNATTENDED=1
elif echo "$answer" | grep -iq "^n"; 
	then UNATTENDED=0
	else exit 1
elif echo "$answer" | grep -iq "^sudo_user"; 
	then UNATTENDED=0
	else exit 1	
fi

apt_update_upgrade

if [ "$UNATTENDED" = "1" ]; then
	answer="y"
else
	echo -n "Create new sudo user? (y)Yes as deploy (n)Skip: "
	read answer
fi

if echo "$answer" | grep -iq "^n"; then
	echo -n "Skipping sudo user creation."
else	
	if echo "$answer" | grep -iq "^y";
		then USER="deploy"
		else USER=$answer
	fi
	setup_sudo_user "$USER"

	if [ "$UNATTENDED" = "0" ]; then
		echo -n "Restart SSH Service? Command may disrupt existing ssh connections. (y)Yes (n)No: "
		read answer
		if echo "$answer" | grep -iq "^y";
			then RESTART=1
			else RESTART=0     
		fi

		echo -n "Change PermitRootLogin to 'no'? (y)Yes (n)No: "
		read answer
		if echo "$answer" | grep -iq "^y";
			then PERMITROOT_NO=1
			else PERMITROOT_NO=0
		fi
		setup_sudo_user_ssh "$PERMITROOT_NO" "$RESTART"
	else 
		SSH_REMINDER=1
	fi

	if [ "$UNATTENDED" = "1" ]; then
		answer="y"
	else
		echo -n "Continue as $USER? (y)Yes (n)No: "
		read answer
	fi
	if echo "$answer" | grep -iq "^y"; then
		su "$USER"
	fi	
fi

install_security

# config ufw
if [ "$UNATTENDED" = "1" ]; then
	answer="n"
else
	echo -n "Limit SSH access to IP/subnet or allow all? (y)Limit to IP address (n)Allow All: "
	read answer	
fi
if echo "$answer" | grep -iq "^n"; then
	sudo ufw allow 22
else
	sudo ufw allow from "$answer"
fi
setup_security

install_ondrej_apache
install_ondrej_php
install_postfix
install_memcached
setup_apache

if [ "$UNATTENDED" = "1" ]; then
	answer=1
else
	echo -n "Install (1)MySQL (2)MariaDB (*)Skip: "
	read answer
fi

if echo "$answer" | grep -iq "1"; then
	MYSQL=1
	install_mysqldb
elif echo "$answer" | grep -iq "2"; then
	MYSQL=1
	install_mariadb
else
	MYSQL=0
fi

if [ "$MYSQL" = "1" ]; then
	mysql_tune
fi

# this will produce error when MySQL installed is skipped
if [ "$UNATTENDED" = "0" ] && [ "$MYSQL" = "1" ]; then
	mysql_secure_installation
fi

goodstuff

# status
echo "-----------------"
echo "Install complete."
echo "-----------------"
echo 
echo "$(systemctl status apache2)"
echo "$(apachectl -M | grep --color security)"
echo "$(systemctl status $PHP-fpm)"
echo "$(systemctl status mysql)"
echo "$(systemctl status memcached)"
echo "$(sudo ufw status verbose)"
echo 
echo "+ phpinfo()"
echo "- 127.0.0.1/info.php"
echo 
echo "+ ToDo"
echo "- Remove /var/www/html/info.php"
echo "- 'dpkg-reconfigure tzdata' to change timezone ($(date))"
if [ "$UNATTENDED" = "1" ]; then
	if [ "$PERMITROOT_NO" = "0" ]; then
		echo "- Change 'PermitRootLogin' to 'no' in /etc/ssh/sshd_config"
		echo "- 'sudo systemctl restart ssh.service' after SSH changes"
	fi	
	echo "- Update hostname (apache2.service could fail to start without proper hostname)"
	echo "- sudo passwd $USER"
	echo "- mysql_secure_installation"
elif [ "$SSH_REMINDER" = "1" ]; then
	echo "- sudo systemctl restart ssh.service"
fi
echo
IP=system_primary_ip
echo "+ Steps for generating login keys:

**On your local workstation**
ssh-keygen -t rsa -b 2048 -v
ssh-copy-id -f -i FILE_NAME.pub $USER@$IP
mv FILE_NAME FILE_NAME.pem
sudo chmod 400 FILE_NAME.pem
sudo ssh -i FILE_NAME.pem $USER@$IP"
echo
