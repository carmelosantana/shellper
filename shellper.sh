#!/bin/bash
function apt_update_upgrade {
	sudo apt update
	sudo apt upgrade -y
}

function crontab_backup {
	crontab -l > $(date +%Y%m%d).crontab
}

function current_ssh_users {
	netstat -tnpa | grep 'ESTABLISHED.*sshd'
}

function file_change_append {
	#TODO: Add checks for $1, $2, $3
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

function get_parent_dir {
	echo "$(dirname "$(pwd)")"
}

function get_all_users {
	cut -d: -f1 /etc/passwd
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
    sudo echo "<?php phpinfo();" > /var/www/html/info.php
}

function install_postfix {
    sudo apt update
    sudo apt upgrade -y
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
    sudo apt update
    sudo apt install -y syncthing
    sudo ufw allow syncthing
    sudo ufw allow syncthing-gui    
}

function install_terminal_utils {
    sudo apt update
    sudo apt -y install aptitude fish git glances htop screen
}

function install_webmin {
    curl -s http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
    echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
    echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
    sudo apt update
    sudo apt install -y webmin
	sudo ufw allow 10000	
}

function setup_apache {
    sudo apt install libapache2-mod-security2 -y
    sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
    file_change_append "/etc/modsecurity/modsecurity.conf" "SecRuleEngine" "On" 0
    
    sudo a2enmod actions expires proxy_fcgi proxy_http rewrite ssl vhost_alias http2 proxy_http2 security2 proxy_fcgi setenvif
	sudo a2enconf php7.4-fpm
    apache_tune
    sudo systemctl restart apache2.service

	sudo ufw allow 80
	sudo ufw allow 443
}

function setup_mysql {
	mysql_tune
}

function setup_security {
	echo y | sudo ufw enable

	# unattended-upgrades
	sudo 'cat <<EOF >> /etc/apt/apt.conf.d/10periodic
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF'
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

function setup_sudo_user_ssh {
	LINODE_ID
	if [ ! -n "$1" ];
		then PERMITROOT_NO="0"
		else PERMITROOT_NO="$1"
	fi
	if [ "$PERMITROOT_NO" = "1" ]; then
        file_change_append "/etc/ssh/sshd_config" "PermitRootLogin" "no" 1
    fi

	if [ ! -n "$2" ];
		then RESTART="0"
		else RESTART="$2"
	fi
	if [ "$RESTART" = "1" ]; then
        sudo systemctl restart ssh.service        
    fi	
}

function whose_my_host {
	if [ -n "$LINODE_ID" ]; 
		then echo "LINODE"
		else echo "Unknown"
	fi
}