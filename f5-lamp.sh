#!/bin/bash
# First 5 minutes LAMP installer
# Version: 0.2.3
# Tested: Ubuntu 16.04.1

# TODO:
# ☐ Add check if email is correct
# ☐ Add apache config
# 	☐ http2
# 	☐ apache2 version header
# ☐ Add additional IP loop for ufw
# ☐ Add create pem for deploy
# ☐ Add no sudo password
# ☐ Which?
# 	☐ systemctl: systemctl restart apache2.service
# 	☐ service: service apache2 restart
# ☐ Fix interrupted Debian install (mariaDB password prompt)

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

# start
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
  PHP7
    fpm

Utilities:
  debian-keyring
  fish
  git
  htop
  logwatch
  postfix
  python-letsencrypt-apache
  screen
  Webmin"

# continue with this?
echo ""
echo -n "Continue? (y|n) "
read answer
if echo "$answer" | grep -iq "^n"; then
	exit 1
fi

# unattended
echo -n "Unattended install? (y|n) "
read answer
if echo "$answer" | grep -iq "^y"; then
	UNATTENDED=1
else
	UNATTENDED=0	
fi

# upgrade, update
sudo apt-get update
sudo apt-get upgrade -y

# username or skip
if [ "$UNATTENDED" = "1" ]; then
	answer="y"
else
	echo -n "Enter another username, continue with 'deploy' or skip sudo user creation. (y|n=skip)"
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

	# copy keys
	authorized_keys="/root/.ssh/authorized_keys"
	if [ -f "$authorized_keys" ]; then
		sudo cp $authorized_keys /home/$USER/.ssh/authorized_keys
		sudo chmod 400 /home/$USER/.ssh/authorized_keys
	else
		authorized_keys=0
	fi

	# finish setting up user
	sudo chown $USER:$USER /home/$USER -R
	if [ "$UNATTENDED" = "0" ]; then
		sudo passwd $USER
	fi

	# safe sudoers edit
	if [ -e /etc/sudoers.tmp -o "$(pidof visudo)" ]; then 
		echo "/etc/sudoers busy, try again later"
	else
		cp /etc/sudoers /etc/sudoers.bak
		cp /etc/sudoers /etc/sudoers.tmp
		chmod 0740 /etc/sudoers.tmp
		echo "$USER  ALL=(ALL:ALL) ALL" >> /etc/sudoers.tmp
		chmod 0440 /etc/sudoers.tmp
		mv /etc/sudoers.tmp /etc/sudoers
	fi

	# restart SSH?
	if [ "$UNATTENDED" = "0" ]; then
		echo -n "Command may disrupt existing ssh connections. Proceed with operation? (y|n) "
		read answer
		if echo "$answer" | grep -iq "^y"; then
			SSH_REMINDER=0
			sudo service ssh restart
		else 
			SSH_REMINDER=1
		fi
	fi

	# edit sshd_config
	if [ "$authorized_keys" != "0" ]; then
		file_change_append "/etc/ssh/sshd_config" "PermitRootLogin" "no" 1
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
	echo -n "Install Apache from (1)Distro PPA (2)PPA:ondrej/apache2 (1|2) "
	read answer
fi
if echo "$answer" | grep -iq "1"; then
	sudo apt-get -y install apache2 apache2-utils
else
	sudo add-apt-repository ppa:ondrej/apache2
	sudo apt-get update
	sudo apt-get -y install apache2 apache2-utils
fi

# modsecurity
sudo apt-get -y install libapache2-modsecurity

# config modsecurity
sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
file_change_append "/etc/modsecurity/modsecurity.conf" "SecRuleEngine" "On" 0
sudo service apache2 restart

# mysql
if [ "$UNATTENDED" = "1" ]; then
	answer=1
else
	echo -n "Install (1)MariaDB (2)MySQL (1|2) "
	read answer
fi
if echo "$answer" | grep -iq "^2"; then
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
	echo -n "Install (1)libapache2-mod-fastcgi php7.0-fpm (2)libapache2-mod-php7.0 (1|2) "
	read answer
fi
if echo "$answer" | grep -iq "^2"; then
	FPM=0
	sudo apt-get -y install libapache2-mod-php7.0 php7.0
else
	FPM=1
	sudo apt-get -y install libapache2-mod-fastcgi php7.0-fpm php7.0
	a2enmod actions fastcgi alias
	sudo cat <<EOF >> /etc/apache2/sites-available/000-default.conf
<Directory /usr/lib/cgi-bin>
    Require all granted
</Directory>
<IfModule mod_fastcgi.c>
	AddHandler php7-fcgi .php
	Action php7-fcgi /php7-fcgi
	Alias /php7-fcgi /usr/lib/cgi-bin/php7-fcgi
	FastCgiExternalServer /usr/lib/cgi-bin/php7-fcgi -socket /var/run/php/php7.0-fpm.sock -pass-header Authorization
</IfModule>
EOF
fi
sudo service apache2 restart

# php packages
if [ "$UNATTENDED" = "1" ]; then
	answer=1
else
	echo -n 'Install PHP modules: (1)WordPress Recommended (2)WordPress Minimum (3)All debian.org packages (1|2|3) '
	read answer
fi
if echo "$answer" | grep -iq "^3"; then
	# ALL
	sudo apt-get -y install php7.0-bcmath php7.0-bz2 php7.0-cgi php7.0-cli php7.0-common php7.0-curl php7.0-dba php7.0-dev php7.0-enchant php7.0-gd php7.0-gmp php7.0-imap php7.0-interbase php7.0-intl php7.0-json php7.0-ldap php7.0-mbstring php7.0-mcrypt php7.0-mysql php7.0-odbc php7.0-opcache php7.0-pgsql php7.0-phpdbg php7.0-pspell php7.0-readline php7.0-recode php7.0-snmp php7.0-soap php7.0-sqlite3 php7.0-sybase php7.0-tidy php7.0-xml php7.0-xmlrpc php7.0-xsl php7.0-zip php-redis php-xdebug
elif echo "$answer" | grep -iq "^2"; then
	# WP Min
	sudo apt-get -y install php7.0-cli php7.0-common php7.0-curl php7.0-gd php7.0-json php7.0-mbstring php7.0-mcrypt php7.0-mysql php7.0-opcache php7.0-readline php7.0-xml php7.0-xmlrpc php7.0-xsl
else
	# WP Recommended
	sudo apt-get -y install php7.0-cli php7.0-common php7.0-curl php7.0-gd php7.0-json php7.0-mbstring php7.0-mcrypt php7.0-mysql php7.0-opcache php7.0-pspell php7.0-readline php7.0-snmp php7.0-soap php7.0-sqlite3 php7.0-xml php7.0-xmlrpc php7.0-xsl php7.0-zip
fi

# www extras
sudo echo "<?php phpinfo();" > /var/www/html/info.php

# Install utilities
if [ "$UNATTENDED" = "1" ]; then
	answer="y"
else
	echo -n "Install utilities? (y|n) "
	read answer
fi
if echo "$answer" | grep -iq "^y"; then
	UTILITIES=1
	# needed to add key
	sudo apt-get install debian-keyring
	
	# setup key + repo
	wget http://www.webmin.com/jcameron-key.asc
	chmod 777 jcameron-key.asc
	sudo apt-key add jcameron-key.asc
	echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
	echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
	
	# install webmin
	sudo apt-get update | sudo apt-get install -y --allow-unauthenticated webmin

	# utilities
	sudo DEBIAN_FRONTEND=noninteractive apt-get -y install postfix
	sudo apt-get -y install fish git htop logwatch python-letsencrypt-apache screen

	# cron
	if [ "$UNATTENDED" = "0" ]; then
		echo -n "Setup daily email for critical entries via cron.daily? (enter@youremail.com|n) "
		read answer
		if echo "$answer" | grep -iq "^n"; then
			echo ""
		else	
			sudo echo "/usr/sbin/logwatch --output mail --mailto $answer --detail high" > /etc/cron.daily/logwatch
		fi
	fi
else
	UTILITIES=0
fi	

# status
echo ""
echo "------"
echo "Status"
echo "------"
echo ""
echo "$(systemctl status apache2)"
echo ""
echo "● mod_security"
echo "$(apachectl -M | grep --color security)"
echo ""
echo "$(systemctl status mysql)"
if [ "$FPM" = "1" ]; then
	echo ""
	echo "$(systemctl status php7.0-fpm)"
fi
echo ""
echo "$(systemctl status ufw)"
echo ""
echo "● ufw"
sudo ufw status verbose

# notes
echo "● Time: $(date)"
echo "Run 'dpkg-reconfigure tzdata' if you wish to change it."
echo ""
echo "● phpinfo()"
echo "127.0.0.1/info.php"
if [ "$UTILITIES" = "1" ]; then
	echo ""
	echo "● Let's Encrypt"
	echo "letsencrypt --apache -d site.com"
	echo "letsencrypt certonly --standalone --email you@site.com --agree-tos -d site.com -d site2.com"
fi
if [ "$UNATTENDED" = "1" ]; then
	echo ""
	echo "● Skipped"
	echo "These commands were skipped during unattended installation:"
	echo "sudo passwd $USER"
	echo "sudo service ssh restart"
	echo "mysql_secure_installation"
else
	if [ "$SSH_REMINDER" = "1" ]; then
		echo ""
		echo "● Skipped"
		echo "These commands were skipped during installation:"
		echo "sudo service ssh restart"
	fi
fi

# thats it
echo ""
echo "-----------------"
echo "Install complete!"
echo "-----------------"
echo ""

# Sources:
# https://gist.github.com/gpassarelli/52bc73f3fdb7359a43c8
# https://help.ubuntu.com/community/UFW# https://www.howtoforge.com/tutorial/apache-with-php-fpm-on-ubuntu-16-04/
# https://packages.debian.org/source/stretch/php7.0
# https://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers
# https://stackoverflow.com/questions/36070562/disable-ssh-root-login-by-modifying-etc-ssh-sshd-conf-from-within-a-script#36071618
# https://ubuntuforums.org/showthread.php?t=1352310&p=8481506#post8481506
# https://www.digitalocean.com/community/tutorials/how-to-set-up-mod_security-with-apache-on-debian-ubuntu
# https://www.howtoforge.com/tutorial/apache-with-php-fpm-on-ubuntu-16-04/
# http://www.andrewault.net/2010/05/17/securing-an-ubuntu-server/
# http://askubuntu.com/questions/556385/how-can-i-install-apt-packages-non-interactively
# http://superuser.com/questions/228173/whats-the-difference-between-mod-fastcgi-and-mod-fcgid#514555