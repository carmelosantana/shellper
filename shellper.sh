#!/bin/bash
# cd shellper && chmod +x shellper.sh && ./shellper.sh
SHELLPER_VERSION="0.15"
export SHELLPER_VERSION

function _shellper_help {
    echo "
+------------------------+
| Shellper - shellper.org|
+------------------------+ v$SHELLPER_VERSION 
[Joblets]
install_lamp

[Functions]
apache_restart                  apt_update_upgrade
ask_mariadb_mysql               ask_reboot
crontab_backup                  current_ssh_users
debian_frontend_noninteractive  echo_install_complete
file_change_append              gen_password
get_parent_dir                  get_all_users
get_random_lwr_string           get_lamp_status
get_php_version                 hdd_test
increase_lvm_size               install_apache_mod_security
install_certbot                 install_fish
install_geekbench               install_imagemagick_ffmpeg
install_mariadb                 install_maxmind
install_memcached               install_mod_pagespeed
install_mycroft                 install_mysql
install_mysql_setup             install_ondrej_apache
install_ondrej_php              install_php_test
install_postfix                 install_security
install_speedtest               install_syncthing
install_terminal_utils          install_webmin
install_wp_cli                  restart_lamp
setup_fqdn                      setup_hostname
setup_script_log                setup_apache
setup_mysql                     setup_security
setup_security_sshd             setup_sudo_user
setup_syncthing                 setup_unattended_upgrades
wp_cron_to_crontab               
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
		shellper
	fi
	echo -n
	exit 0
}

function apache_restart {
    sudo systemctl restart apache2.service
}

function apt_update_upgrade {	
	sudo apt-get update
	sudo apt-get upgrade -yq
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

function ask_reboot {
	echo -n "Reboot in 30 seconds ... CTRL C to exit script and cancel reboot."
	sleep 30 
	sudo reboot
}

function crontab_backup {
	crontab -l > $(date +%Y%m%d).crontab
}

function current_ssh_users {
	netstat -tnpa | grep 'ESTABLISHED.*sshd'
}

function debian_frontend_noninteractive {
	DEBIAN_FRONTEND=noninteractive
	export DEBIAN_FRONTEND
}

function echo_install_complete {
	echo
	echo "+----------------+"
	echo "|Install complete|"
	echo "+----------------+"
	echo
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

function gen_password {
	if [ ! -n "$1" ];
		then LEN="20"
		else LEN="$1"
	fi
	PASS="$(head -c 32 /dev/urandom | base64 | fold -w $LEN | head -n 1)"
	echo "$(sed -e 's/[[:space:]]*$//' <<<${PASS})"
}

function get_parent_dir {
	echo "$(dirname "$(pwd)")"
}

function get_all_users {
	cut -d: -f1 /etc/passwd
}

function get_random_lwr_string {
	if [ ! -n "$1" ];
		then LEN="3"
		else LEN="$1"
	fi
	echo "$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w $LEN | head -n 1)"	
}

function get_lamp_status {
	PHP=get_php_version
	echo "$(systemctl status apache2)"
	echo "$(apachectl -M | grep --color security)"
	echo "$(systemctl status $PHP-fpm)"
	echo "$(systemctl status mysql)"
	echo "$(systemctl status memcached)"
	echo "$(sudo ufw status verbose)"	
}

function get_php_version {
	echo "$(systemctl status | grep -io 'php[7-9].[0-9]')"
}

function hdd_test {
	if [ ! -n "$1" ];
		then HDD="/dev/sda"
		else HDD="$1"
	fi
	sudo hdparm -Tt "$HDD"
}

function increase_lvm_size {
	if [ ! -n "$1" ];
		then LVM="/dev/ubuntu-vg/ubuntu-lv"
		else LVM="$1"
	fi
	sudo lvdisplay -m
	sudo lvresize -l+100%FREE "$LVM"
	sudo resize2fs "$LVM"
}

function install_apache_mod_security {
    sudo apt-get install libapache2-mod-security2 -y
    sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
    file_change_append "/etc/modsecurity/modsecurity.conf" "SecRuleEngine" "On" 0
}

function install_certbot {
	sudo apt-get -y install software-properties-common
	sudo add-apt-repository -y universe
	sudo add-apt-repository -y ppa:certbot/certbot
	apt_update_upgrade
	sudo apt-get -y install certbot python-certbot-apache
}

function install_fish {
    sudo apt-get install fish -y
    chsh -s `which fish`
}

function install_geekbench {
	wget http://cdn.primatelabs.com/Geekbench-5.0.4-Linux.tar.gz
	tar -zxvf Geekbench-5.0.4-Linux.tar.gz
	cd build.pulse/dist/Geekbench-5.0.4-Linux/
	./geekbench5
}

function install_imagemagick_ffmpeg {
	sudo apt-get -y install imagemagick ffmpeg	
}

function install_lamp {
	if [ ! -n "$1" ];
		then UNATTENDED="0"
		else UNATTENDED="$1"
	fi
	if [ ! -n "$2" ];
		then SUDO_USERNAME="deploy"
		else SUDO_USERNAME="$2"
	fi

	if [ "$UNATTENDED" = "0" ]; then
		echo -n "Unattended install? (y)Yes (n)No (q)Quit: "
		read answer
	else
		answer="y"
	fi
	if echo "$answer" | grep -iq "^y"; then
		UNATTENDED=1
		debian_frontend_noninteractive

	elif echo "$answer" | grep -iq "^n"; then
		UNATTENDED=0
	else
		exit 1	
	fi

	setup_sudo_user "$SUDO_USERNAME"

	apt_update_upgrade
	setup_unattended_upgrades
	install_security
	install_ondrej_apache
	install_ondrej_php
	install_php_test
	ask_mariadb_mysql "$UNATTENDED"
	postfix_install_loopback_only
	install_memcached
	get_lamp_status

	echo -n "+ ToDo"
	echo "  - Update hostname"
	echo "  - General security"
	if [ "$MYSQL_SECURE" = "0" ]; then
		echo "  - mysql_secure_installation"
	fi
	echo "  - Change 'PermitRootLogin' to 'no' in /etc/ssh/sshd_config followed by 'sudo systemctl restart ssh.service'"
	echo "  -- systemctl restart ssh.service"
	echo "  - sudo passwd $SUDO_PASSWORD"
	echo_install_complete
}

function install_mariadb {
	sudo apt-get -y install mariadb-server mariadb-client
	echo "Sleeping while MySQL starts up for the first time..."
	sleep 5	
}

function install_maxmind {
	echo | sudo add-apt-repository ppa:maxmind/ppa
	apt_update_upgrade
	sudo apt-get -y install geoipupdate libmaxminddb0 libmaxminddb-dev mmdb-bin
}

function install_memcached {
	sudo apt-get -y install memcached
}

function install_mod_pagespeed {
	if [ ! -n "$1" ];
		then BRANCH="stable"
		else BRANCH="$1"
	fi
	
    case "$BRANCH" in
    "beta")
        wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-beta_current_amd64.deb
        ;;
    *)
        wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb
        ;;
    esac
	
	sudo dpkg -i mod-pagespeed-*.deb
	sudo apt-get -f -y install
}

function install_mycroft {
	#TODO: Add avx check
    grep avx /proc/cpuinfo

	if [ ! -n "$1" ];
		then PATH="~/"
		else PATH="$1"
	fi
    cd "$PATH"
    git clone https://github.com/MycroftAI/mycroft-core.git
    cd mycroft-core
    bash dev_setup.sh    
}

function install_mysql {
	sudo apt-get -y install mysql-server mysql-client
	echo "Sleeping while MySQL starts up for the first time..."
	sleep 5	
}

function install_mysql_setup {
	if [ ! -n "$1" ]; then
		echo "mysql_install() requires the root pass as its first argument"
		return 1;
	fi
	echo "mysql-server mysql-server/root_password password $1" | debconf-set-selections
	echo "mysql-server mysql-server/root_password_again password $1" | debconf-set-selections	
}

function install_ondrej_apache {
    echo | sudo add-apt-repository ppa:ondrej/apache2
	apt_update_upgrade
    sudo apt-get install apache2 apache2-utils -y
}

function install_ondrej_php {
	# TODO: Add default to latest
	if [ ! -n "$1" ];
		then PHP="php7.4"
		else PHP="$1"
	fi
    export PHP
    echo | sudo add-apt-repository ppa:ondrej/php
    sudo apt-get -y install $PHP libapache2-mod-$PHP $PHP-bcmath $PHP-cli $PHP-common $PHP-curl $PHP-fpm $PHP-gd $PHP-json $PHP-int $PHP-mbstring $PHP-mysql $PHP-opcache $PHP-pspell $PHP-readline $PHP-snmp $PHP-soap $PHP-sqlite3 $PHP-xml $PHP-xmlrpc $PHP-xsl $PHP-zip php-memcached
    a2enmod proxy_fcgi setenvif
	a2enconf "$PHP"-fpm
	a2dismod "$PHP"
	apache_restart
}

function install_php_test {
	sudo echo "<?php phpinfo();" > "/var/www/html/info.php"
}

function install_postfix {
    sudo DEBIAN_FRONTEND=noninteractive apt -y install postfix    
}

function install_security {
	sudo apt-get -y install fail2ban ufw
}

function install_speedtest {
	# Source:
    # https://fossbytes.com/test-internet-speed-linux-command-line/
    sudo apt-get install -y python-pip
    pip install speedtest-cli
    speedtest-cli    
}

function install_syncthing {
    curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
    echo "deb https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
    apt_update_upgrade
    sudo apt-get install -y syncthing
}

function install_terminal_utils {
    apt_update_upgrade
    sudo apt-get install -y aptitude expect git glances htop screen
}

function install_webmin {
    curl -s http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
    echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
    echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
    apt_update_upgrade
    sudo apt-get install -y webmin
	if [ "$1" = "1" ]; then
		sudo ufw allow webmin
	fi
}

function install_wp_cli {
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	# TODO: Add check
	php wp-cli.phar --info
	chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp
}

function restart_lamp {
	systemctl restart apache2
	PHP="$(get_php_version)"
	systemctl restart "$PHP"
	systemctl restart memcached
	systemctl restart mysql
}

function setup_fqdn {
	if [ ! -n "$1" ]; then
		echo "setup_fqdn() requires the HOSTNAME as its first argument"
		return 1;		
	fi
	if [ ! -n "$2" ]; then
		echo "setup_fqdn() requires the FQDN as its first argument"
		return 1;		
	fi			
	echo "$(system_primary_ip) $FQDN $HOSTNAME" >> /etc/hosts
} 

function setup_hostname {
	if [ ! -n "$1" ]; then
		echo "setup_fqdn() requires the HOSTNAME as its first argument"
		return 1;		
	fi
	if [ ! -n "$2" ]; then
		echo "Optional: setup_fqdn() accepts the FQDN as its second argument"
	fi	
	hostnamectl set-hostname $1
	if [ -n "$2" ]; then
		setup_fqdn $2 $1
	fi		
}

function setup_script_log {
	if [ ! -n "$1" ];
		then LOG="shellper-$(date +%Y%m%d-%H%M%S)"
		else LOG="$1"
	fi
	exec > >(tee -i "/var/log/$LOG.log")
}

function setup_apache {
	if [ ! -n "$1" ];
		then APACHE_MEM=20
		else APACHE_MEM="$1"
	fi	
    sudo a2enmod actions expires proxy_fcgi proxy_http rewrite ssl vhost_alias http2 proxy_http2 setenvif
	sudo a2enconf php7.4-fpm
    apache_tune "$APACHE_MEM"
	apache_restart

	sudo chown -Rv www-data:www-data "/var/www/"
	sudo chmod -Rv 2755 "/var/www/"

	sudo ufw allow 80
	sudo ufw allow 443
}

function setup_mysql {
	mysql_tune
	mysql_secure_installation
}

function setup_security {
	setup_unattended_upgrades
	ufw default allow outgoing
	ufw default deny incoming
	if [ -n "$1" ]; then 
		ufw allow from "$1"
	fi	
	echo y | ufw enable
	systemctl enable ufw
	fail2ban_install
}

function setup_security_sshd {	
	SSHD_CONFIG="/etc/ssh/sshd_config"
	sed -i "s/#AddressFamily any/AddressFamily inet/g" "$SSHD_CONFIG"
	sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" "$SSHD_CONFIG"
	sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/g" "$SSHD_CONFIG"
	systemctl restart sshd
}

function setup_sudo_user {
	if [ ! -n "$1" ];
		then USER="deploy"
		else USER="$1"
	fi
	if [ ! -n "$2" ];
		then PASS="0"
		else PASS="$2"
	fi		
	
	sudo useradd $USER
	sudo mkdir /home/$USER
	sudo mkdir /home/$USER/.ssh
	sudo chmod 700 /home/$USER/.ssh
	sudo chsh -s /bin/bash $USER
	sudo chown $USER:$USER /home/$USER -R

	if [ "$PASS" != "0" ]; then
		# https://stackoverflow.com/questions/714915/using-the-passwd-command-from-within-a-shell-script?answertab=votes#tab-top
		echo "$USER:$PASS" | chpasswd
	fi

	# safe sudoers add
	sudo adduser $USER sudo
}

function setup_syncthing {
	if [ ! -n "$1" ];
		then OWNER="deploy"
		else OWNER="$1"
	fi

	sudo systemctl start "syncthing@${OWNER}.service"	
	sleep 30
	sudo systemctl stop "syncthing@${OWNER}.service"	

	if [ "$2" = "1" ]; then
		SYNCTHING_PATH=$(eval echo "~$OWNER")"/.config/syncthing/config.xml"
		if [ -f "$SYNCTHING_PATH" ]; then
			OWNER="www-data"; sed -i "s/127.0.0.1:8384/0.0.0.0:8384/g" "$SYNCTHING_PATH"
		else
			echo "setup_syncthing() can't find Syncthing config"
		fi
	fi	
	if [ "$3" = "1" ]; then
		sudo ufw allow syncthing
		sudo ufw allow syncthing-gui
	fi

	sudo systemctl enable "syncthing@${OWNER}.service"
	sudo systemctl start "syncthing@${OWNER}.service"	
}

function setup_unattended_upgrades {
	APT_CONF="/etc/apt/apt.conf.d/10periodic"
	file_change_append "$APT_CONF" "APT::Periodic::Unattended-Upgrade" '"1";' 1
	file_change_append "$APT_CONF" "APT::Periodic::Download-Upgradeable-Packages" '"1";'
	file_change_append "$APT_CONF" "APT::Periodic::AutocleanInterval" '"7";'
}

function wp_cron_to_crontab {
	if [ -n "$1" ]; then
        echo "0 1 * * * '/usr/local/bin/wp core update --allow-root --path=$1' > /dev/null 2>&1" >> wpcron
        crontab wpcron
        rm wpcron
	fi
}

function _source_files {
	# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself?answertab=votes#tab-top
	DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
	source "$DIR/linode/stackscripts/1.sh"
	source "$DIR/linode/stackscripts/401712.sh"	
}

_source_files

if [[ "$0" = "$BASH_SOURCE" ]]; then
	shellper
fi