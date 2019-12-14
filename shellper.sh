#!/bin/bash
SHELLPER_VERSION="0.13"
export SHELLPER_VERSION

function _shellper_help {
    echo "
+------------------------+
| Shellper - shellper.org|
+------------------------+ v$SHELLPER_VERSION 
./shellper.sh [COMMAND]

Recently added:
  - install_wp_cli

Joblets:
  - install_lamp

Functions:
  - apache_restart			- apt_update_upgrade
  - ask_mariadb_mysql			- ask_new_sudo_user
  - ask_security 			- crontab_backup
  - current_ssh_users			- echo_install_complete
  - file_change_append 			- get_parent_dir
  - get_all_users			- get_lamp_status
  - hdd_test 				- increase_lvm_size
  - install_apache_mod_security		- install_chrome
  - install_fish 			- install_geekbench
  - install_lamp 			- install_mariadb
  - install_maxmind			- install_memcached
  - install_mycroft			- install_mysql
  - install_ondrej_apache		- install_ondrej_php
  - install_php_test 			- install_postfix
  - install_security 			- install_speedtest
  - install_syncthing			- install_terminal_utils
  - install_webmin 			- set_debian_frontend_noninteractive
  - setup_apache 			- setup_mysql
  - setup_security 			- setup_sudo_user
  - setup_permit_root_login		- setup_unattended_upgrades
  "	
}

function shellper {
	_shellper_help
	echo -n "Type a command or Q to quit: "
	read answer
	if echo "$answer" | grep -iq "^q"; then
		exit 0
	elif [ -n "$answer" ]; then	
	    ($answer)
	fi
	echo -n
	exit 0
}

function apache_restart {
    sudo systemctl restart apache2.service
}

function apt_update_upgrade {	
	sudo apt update
	sudo apt upgrade -yq
}

function ask_mariadb_mysql {
	if [ ! -n "$1" ];
		then UNATTENDED="0"
		else UNATTENDED="$1"
	fi

	if [ "$UNATTENDED" = "1" ]; then
		answer=1
	else
		echo -n "Install (1)MySQL (2)MariaDB (*)Skip: "
		read answer
	fi

	if echo "$answer" | grep -iq "1"; then
		MYSQL=1
		install_mysql
	elif echo "$answer" | grep -iq "2"; then
		MYSQL=1
		install_mariadb
	else
		MYSQL=0
	fi

	# this will produce error when MySQL installed is skipped
	if [ "$UNATTENDED" = "0" ] && [ "$MYSQL" = "1" ]; then
		setup_mysql
		MYSQL_SECURE=1
	elif [ "$MYSQL" = "1" ]; then
		mysql_tune
		MYSQL_SECURE=0
	fi
	export MYSQL
	export MYSQL_SECURE
}

function ask_new_sudo_user {
	if [ ! -n "$1" ];
		then UNATTENDED="0"
		else UNATTENDED="$1"
	fi
	PERMITROOT_N0=0
	SSH_REMINDER=0

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
			echo -n "Change PermitRootLogin to 'no'? (y)Yes (n)No: "
			read answer
			if echo "$answer" | grep -iq "^y"; then
				setup_permit_root_login
			fi

			echo -n "Restart SSH Service? Command may disrupt existing ssh connections. (y)Yes (n)No: "
			read answer
			if echo "$answer" | grep -iq "^y"; then
		        sudo systemctl restart ssh.service
			fi
		else 
			SSH_REMINDER=1
		fi

		if [ "$UNATTENDED" = "1" ]; then
			answer="n"
		else
			echo -n "Continue as $USER? (Require's restarting the script.) (y)Yes (n)No: "
			read answer
		fi
		if echo "$answer" | grep -iq "^y"; then
			su "$USER"
		fi	
	fi
	export PERMITROOT_NO
	export SSH_REMINDER
	export USER
}

function ask_security {
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
}

function crontab_backup {
	crontab -l > $(date +%Y%m%d).crontab
}

function current_ssh_users {
	netstat -tnpa | grep 'ESTABLISHED.*sshd'
}

function echo_install_complete {
	echo
	echo "+----------------+"
	echo "|Install complete|"
	echo "+----------------+"
	echo
	exit 0	
}

function file_change_append {
	#TODO: Add checks for $1, $2, $3
	INFILE=$1
	BAKFILE="$1.bak"
	TMPFILE="$1.tmp"

	# backup
	cp -f $INFILE $BAKFILE

	# create
	touch $TMPFILE

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
	    echo "$2 $3" >> $TMPFILE
	fi

	# cp -f $TMPFILE $INFILE
	mv $TMPFILE $INFILE
	sync	
}

function get_parent_dir {
	echo "$(dirname "$(pwd)")"
}

function get_all_users {
	cut -d: -f1 /etc/passwd
}

function get_lamp_status {
	if [ ! -n "$1" ];
		then PHP="7.4"
		else PHP="$1"
	fi
	echo "$(systemctl status apache2)"
	echo "$(apachectl -M | grep --color security)"
	echo "$(systemctl status $PHP-fpm)"
	echo "$(systemctl status mysql)"
	echo "$(systemctl status memcached)"
	echo "$(sudo ufw status verbose)"	
}

function hdd_test {
	#TODO: HDD select
	sudo hdparm -Tt /dev/sda
}

function increase_lvm_size {
	#TODO: volume select
	sudo lvdisplay -m
	sudo lvresize -l+100%FREE /dev/ubuntu-vg/ubuntu-lv
	sudo resize2fs /dev/ubuntu-vg/ubuntu-lv	
}

function install_apache_mod_security {
    sudo apt install libapache2-mod-security2 -y
    sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
    file_change_append "/etc/modsecurity/modsecurity.conf" "SecRuleEngine" "On" 0
}

function install_chrome {
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
	sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
	apt_update_upgrade
	sudo apt install google-chrome-stable -y
}

function install_fish {
    sudo apt install fish -y
    chsh -s `which fish`
}

function install_geekbench {
	wget http://cdn.primatelabs.com/Geekbench-5.0.4-Linux.tar.gz
	tar -zxvf Geekbench-5.0.4-Linux.tar.gz
	cd build.pulse/dist/Geekbench-5.0.4-Linux/
	./geekbench5
}

function install_lamp {
	if [ ! -n "$1" ];
		then UNATTENDED="0"
		else UNATTENDED="$1"
	fi
	if [ ! -n "$2" ];
		then SKIP_SUDO_CREATE="0"
		else SKIP_SUDO_CREATE="$2"
	fi	

	echo "
+---------------------+
|First 5 Minutes: LAMP|
+---------------------+
System:
  Distro update + upgrade
  Create sudo user

Security:
  fail2ban
  ufw
  unattended-upgrades

Services:
  apache2
  php fpm
  MariaDB or MySQL
  Memcached
  postfix"

	if [ "$UNATTENDED" = "0" ]; then
		echo -n "Unattended install? (y)Yes (n)No (q)Quit: "
		read answer
	else
		answer="y"
	fi
	if echo "$answer" | grep -iq "^y"; then
		UNATTENDED=1
		set_debian_frontend_noninteractive

	elif echo "$answer" | grep -iq "^n"; then
		UNATTENDED=0
	else
		exit 1	
	fi

	apt_update_upgrade
	if [ "$SKIP_SUDO_CREATE" = "0" ]; then
		ask_new_sudo_user "$UNATTENDED"
	fi
	install_security
	install_ondrej_apache
	install_ondrej_php
	install_php_test
	ask_mariadb_mysql "$UNATTENDED"
	install_postfix
	install_memcached
	setup_apache
	ask_security "$UNATTENDED"
	get_lamp_status

	echo 
	echo "+ ToDo"
	echo "  - Update hostname"
	if [ "$UNATTENDED" = "1" ]; then
		echo "  - sudo passwd $USER"
	fi	
	if [ "$MYSQL_SECURE" = "0" ]; then
		echo "  - mysql_secure_installation"
	fi
	if [ "$PERMITROOT_NO" = "0" ]; then
		echo "  - Change 'PermitRootLogin' to 'no' in /etc/ssh/sshd_config followed by 'sudo systemctl restart ssh.service'"
	fi			
	if [ "$SSH_REMINDER" = "1" ]; then
		echo "  - systemctl restart ssh.service"
	fi
	echo_install_complete
}

function install_mariadb {
	sudo apt -y install mariadb-server mariadb-client
}

function install_maxmind {
	echo | sudo add-apt-repository ppa:maxmind/ppa
	apt_update_upgrade
	sudo apt-get install geoipupdate libmaxminddb0 libmaxminddb-dev mmdb-bin -y	
}

function install_memcached {
	sudo apt -y install memcached
}

function install_mycroft {
	#TODO: Add avx check
    grep avx /proc/cpuinfo

    cd ~/
    git clone https://github.com/MycroftAI/mycroft-core.git
    cd mycroft-core
    bash dev_setup.sh    
}

function install_mysql {
	sudo apt -y install mysql-server mysql-client
}

function install_ondrej_apache {
    echo | sudo add-apt-repository ppa:ondrej/apache2
	apt_update_upgrade
    sudo apt install apache2 apache2-utils -y
}

function install_ondrej_php {
	if [ ! -n "$1" ];
		then PHP="php7.4"
		else PHP="$1"
	fi
    export PHP
    echo | sudo add-apt-repository ppa:ondrej/php
    sudo apt -y install $PHP libapache2-mod-$PHP $PHP-cli $PHP-common $PHP-curl $PHP-fpm $PHP-gd $PHP-json $PHP-mbstring $PHP-mysql $PHP-opcache $PHP-pspell $PHP-readline $PHP-snmp $PHP-soap $PHP-sqlite3 $PHP-xml $PHP-xmlrpc $PHP-xsl $PHP-zip php-memcached
    sudo ln -rs "/etc/apache2/conf-available/$PHP-fpm.conf" "/etc/apache2/conf-enabled/$PHP-fpm.conf"
	a2dismod $PHP
	apache_restart
}

function install_php_test {
	sudo echo "<?php phpinfo();" > "/var/www/html/info.php"
	sudo chown -Rv www-data:www-data "/var/www/"
	sudo chmod -Rv 2755 "/var/www/"
}

function install_postfix {
    sudo DEBIAN_FRONTEND=noninteractive apt -y install postfix    
}

function install_security {
	sudo apt -y install fail2ban ufw
}

function install_speedtest {
	# Source:
    # https://fossbytes.com/test-internet-speed-linux-command-line/
    sudo apt install -y python-pip
    pip install speedtest-cli
    speedtest-cli    
}

function install_syncthing {
    curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
    echo "deb https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
    apt_update_upgrade
    sudo apt install -y syncthing
    sudo ufw allow syncthing
    sudo ufw allow syncthing-gui    
}

function install_terminal_utils {
    apt_update_upgrade
    sudo apt -y install aptitude git glances htop screen
}

function install_webmin {
    curl -s http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
    echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
    echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
    apt_update_upgrade
    sudo apt install -y webmin
	sudo ufw allow 10000	
}

function install_wp_cli {
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	# TODO: Add check
	php wp-cli.phar --info
	chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp
}

function set_debian_frontend_noninteractive {
	DEBIAN_FRONTEND=noninteractive
	export DEBIAN_FRONTEND
}

function setup_apache {
    sudo a2enmod actions expires proxy_fcgi proxy_http rewrite ssl vhost_alias http2 proxy_http2 setenvif
	sudo a2enconf php7.4-fpm
    apache_tune
	apache_restart

	sudo ufw allow 80
	sudo ufw allow 443
}

function setup_mysql {
	mysql_tune
	mysql_secure_installation
}

function setup_security {
	echo y | sudo ufw enable
	setup_unattended_upgrades
}

function setup_sudo_user {
	if [ ! -n "$1" ];
		then USER="deploy"
		else USER="$1"
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
}

function setup_permit_root_login {
	if [ ! -n "$1" ];
		then PERMITROOT_NO="no"
		else PERMITROOT_NO="$1"
	fi
	file_change_append "/etc/ssh/sshd_config" "PermitRootLogin" "$PERMITROOT_NO" 1
}

function setup_unattended_upgrades {
	file_change_append "/etc/apt/apt.conf.d/10periodic" "APT::Periodic::Unattended-Upgrade" '"1";' 1
	file_change_append "/etc/apt/apt.conf.d/10periodic" "APT::Periodic::Download-Upgradeable-Packages" '"1";'
	file_change_append "/etc/apt/apt.conf.d/10periodic" "APT::Periodic::AutocleanInterval" '"7";'
}

function _source_files {
	LINODE_1="$(pwd)/linode/stackscripts/1.sh"
	LINODE_401712="$(pwd)/linode/stackscripts/401712.sh"

	for FILE in LINODE_1 LINODE_401712
	do
		if [ -f "$FILE" ]
			then source "$FILE"
		fi
	done	
}

_source_files

if [[ "$0" = "$BASH_SOURCE" ]]; then
	shellper
fi