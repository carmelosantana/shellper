#!/bin/bash
# First 5 minutes LAMP installer
# Version: 0.2.5

# Distros:
# ✔ Ubuntu 16.04.2

# TODO:
# ☐ Add no sudo password
# ☐ sudo ufw limit ssh - rate limit SSH

# helpers
file_change_append(){
	INFILE=$1
	BAKFILE="$1.bak"
	TMPFILE="$1.tmp"

	# backup
	sudo cp -f $INFILE $BAKFILE

	# create
	sudo touch $TMPFILE

	# check for line to edit
	while read -r line || [[ -n "$line" ]]; do
	    if [ `echo "$line" | grep -c -P "^\s*$2\s+"` = "1" ]; then
	        match=1
	        echo "$2 $3" >> $TMPFILE
	    else
	        echo "$line" >> $TMPFILE
	    fi
	done < $INFILE
	
	# append option if not found in config
	if [ "$match" != "1" ] && [ "$4" = "1" ]; then
	    echo "" >> $TMPFILE
	    echo "$2 $3" >> $TMPFILE
	fi

	# sudo cp -f $TMPFILE $INFILE
	sudo mv $TMPFILE $INFILE
	sync	
}

# Start
echo "
---------------------
First 5 Minutes: LAMP
---------------------
System:
  Distro update + upgrade
  Create sudo user
  PermitRootLogin no

Security:
  fail2ban
  ufw
  unattended-upgrades

Services:
  apache2
    modsecurity
  MariaDB or MySQL
  Memcached
  PHP7
    fpm

Utilities:
  postfix"

# continue with this?
echo

# unattended
echo -n "Unattended install? (y|n|q) "
read answer
if echo "$answer" | grep -iq "^y"; then
	UNATTENDED=1
elif echo "$answer" | grep -iq "^n"; then
	UNATTENDED=0
else
	exit 1
fi

# upgrade, update
sudo apt-get update && sudo apt-get upgrade -y

# username or skip
if [ "$UNATTENDED" = "1" ]; then
	answer="y"
else
	echo -n "Enter another username, continue with 'deploy' or skip sudo user creation. (y=deploy|n=skip)"
	read answer
fi
# continue?
if echo "$answer" | grep -iq "^n"; then
	echo -n "Skipping sudo user creation."
else	
	if echo "$answer" | grep -iq "^y"; then
		USER="deploy"
	else
		USER=$answer
	fi
	sudo useradd $USER
	sudo mkdir /home/$USER
	sudo mkdir /home/$USER/.ssh
	sudo chmod 700 /home/$USER/.ssh
	sudo chsh -s /bin/bash $USER
	sudo cp .bashrc .profile /home/$USER

	# finish setting up user
	sudo chown $USER:$USER /home/$USER -R
	if [ "$UNATTENDED" = "0" ]; then
		sudo passwd $USER
	fi

	# safe sudoers add
	sudo adduser $USER adm
	sudo adduser $USER cdrom
	sudo adduser $USER sudo
	sudo adduser $USER dip
	sudo adduser $USER plugdev
	sudo adduser $USER lxd
	sudo adduser $USER lpadmin
	sudo adduser $USER sambashare

	# restart SSH?
	if [ "$UNATTENDED" = "0" ]; then
		echo -n "Command may disrupt existing ssh connections. Proceed with operation? (y|n) "
		read answer
		if echo "$answer" | grep -iq "^y"; then
			SSH_REMINDER=0
			sudo systemctl restart ssh.service
		else 
			SSH_REMINDER=1
		fi

		# edit sshd_config
		echo -n "
Steps for generating login keys:

(On your machine)
ssh-keygen -t rsa -b 2048 -v
ssh-copy-id -f -i FILE_NAME.pub $USER@SERVER_IP
mv FILE_NAME FILE_NAME.pem
sudo chmod 400 FILE_NAME.pem
sudo ssh -i FILE_NAME.pem $USER@SERVER_IP

Conitinue with PermitRootLogin no?(y|n) "
		read answer
		if echo "$answer" | grep -iq "^y"; then
			file_change_append "/etc/ssh/sshd_config" "PermitRootLogin" "no" 1
		fi		
	fi
fi	

# security
sudo apt-get -y install fail2ban ufw

# config ufw
if [ "$UNATTENDED" = "1" ]; then
	answer="n"
else
	echo -n "Limit access to SSH to your IP/subnet, or allow all? (IP Address|n) "
	read answer	
fi
if echo "$answer" | grep -iq "^n"; then
	sudo ufw allow 22
	sudo ufw allow 10000
else
	# TODO: add loop for additional IPs
	sudo ufw allow from "$answer"
fi
sudo ufw allow 80
sudo ufw allow 443
echo y | sudo ufw enable

# config unattended-upgrades
sudo cat <<EOF >> /etc/apt/apt.conf.d/10periodic
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# apache2
if [ "$UNATTENDED" = "1" ]; then
	answer=1
else
	echo -n "Install Apache from (1)PPA:ondrej/apache2 (2)Distro PPA (1|2) "
	read answer
fi
ONDREJ_APACHE2=0
if echo "$answer" | grep -iq "1"; then
	ONDREJ_APACHE2=1
	echo | sudo add-apt-repository ppa:ondrej/apache2
	sudo apt-get update
fi
sudo apt-get -y install apache2 apache2-utils

# modsecurity
sudo apt-get -y install libapache2-modsecurity

# config modsecurity
sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
file_change_append "/etc/modsecurity/modsecurity.conf" "SecRuleEngine" "On" 0
sudo systemctl restart apache2.service

# mysql
if [ "$UNATTENDED" = "1" ]; then
	answer=0
else
	echo -n "Install (1)MariaDB (2)MySQL (1|2|0) "
	read answer
fi
if echo "$answer" | grep -iq "2"; then
	sudo apt-get -y install mysql-server mysql-client
else	
	sudo apt-get -y install mariadb-server mariadb-client
fi
if [ "$UNATTENDED" = "0" ]; then
	mysql_secure_installation
fi

# php7
if [ "$UNATTENDED" = "1" ]; then
	answer=1
else
	echo -n "Install (1)php7.2-fpm (2)php7.0-fpm (1|2) "
	read answer
fi
if echo "$answer" | grep -iq "2"; then
	ONDREJ_PHP=0
	PHP="php7.0"
else
	ONDREJ_PHP=1
	PHP="php7.2"
	echo | sudo add-apt-repository ppa:ondrej/php
	sudo apt-get update
fi
export PHP
sudo apt-get -y install libapache2-mod-fastcgi $PHP $PHP-cli $PHP-common $PHP-curl $PHP-fpm $PHP-gd $PHP-json $PHP-mbstring $PHP-mcrypt $PHP-mysql $PHP-opcache $PHP-pspell $PHP-readline $PHP-snmp $PHP-soap $PHP-sqlite3 $PHP-xml $PHP-xmlrpc $PHP-xsl $PHP-zip php-memcached
sudo ln -rs "/etc/apache2/conf-available/$PHP-fpm.conf" "/etc/apache2/conf-enabled/$PHP-fpm.conf"

# apache modules
sudo a2enmod actions expires proxy_fcgi proxy_http rewrite ssl vhost_alias
if [ "$ONDREJ_APACHE2" = "1" ]; then
	sudo a2enmod http2 proxy_http2
fi
sudo systemctl restart apache2.service

# www extras
sudo echo "<?php phpinfo();" > /var/www/html/info.php

# utilities
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install postfix
sudo apt-get -y install memcached

# status
echo "Install complete."
echo 
echo "------"
echo "Status"
echo "------"
echo 
echo "$(systemctl status apache2)"
echo 
echo "● mod_security"
echo "$(apachectl -M | grep --color security)"
echo 
echo "$(systemctl status mysql)"
if [ "$FPM" = "1" ]; then
	echo ""
	echo "$(systemctl status php7.0-fpm)"
fi
echo 
if [ "$MEMCACHED" = "1" ]; then
	echo ""
	echo "$(systemctl status memcached)"
fi
echo 
echo "$(systemctl status ufw)"
echo 
echo "● ufw"
sudo ufw status verbose

# notes
echo "● Time: $(date)"
echo "Run 'dpkg-reconfigure tzdata' if you wish to change it."
echo 
echo "● phpinfo()"
echo "127.0.0.1/info.php"
echo 
echo "● Let's Encrypt"
echo "letsencrypt --apache -d site.com"
echo "letsencrypt certonly --standalone --email you@site.com --agree-tos -d site.com"

# thats it
echo 
echo "● ToDo"
echo "☐ Add SSL certificate to postfix"
echo "☐ Remove /var/www/html/info.php"
if [ "$UNATTENDED" = "1" ]; then
	echo "☐ Change 'PermitRootLogin' to 'no' in /etc/ssh/sshd_config"
	echo "☐ Update hostname (apache2.service may fail to start without proper hostname)"
	echo "☐ sudo passwd $USER"
	echo "☐ sudo systemctl restart ssh.service"
	echo "☐ mysql_secure_installation"
elif [ "$SSH_REMINDER" = "1" ]; then
	echo "☐ sudo systemctl restart ssh.service"
fi
echo 

# Sources:
# https://gist.github.com/gpassarelli/52bc73f3fdb7359a43c8
# https://help.ubuntu.com/community/UFW
# https://www.howtoforge.com/tutorial/apache-with-php-fpm-on-ubuntu-16-04/
# https://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers
# https://ubuntuforums.org/showthread.php?t=1352310&p=8481506#post8481506
# https://www.digitalocean.com/community/tutorials/how-to-set-up-mod_security-with-apache-on-debian-ubuntu
# https://www.howtoforge.com/tutorial/apache-with-php-fpm-on-ubuntu-16-04/
# http://www.andrewault.net/2010/05/17/securing-an-ubuntu-server/
# http://askubuntu.com/questions/556385/how-can-i-install-apt-packages-non-interactively
# http://superuser.com/questions/228173/whats-the-difference-between-mod-fastcgi-and-mod-fcgid#514555