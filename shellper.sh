#!/bin/bash

SHELLPER_ASK_REBOOT="Reboot in 30 seconds... [ctrl] [c] to exit script and cancel reboot."
SHELLPER_AUTOCOMPLETE_HINTS="apache_restart apt_update_upgrade ask_mariadb_mysql ask_reboot crontab_backup current_ssh_users debian_frontend_noninteractive file_change_append gen_password get_all_users get_lamp_status get_parent_dir get_php_version get_public_ip get_random_lwr_string get_ssh_session_ip hdd_test install_acme_sh install_apache_mod_security install_composer install_certbot install_clamav install_docker install_fail2ban install_fish install_geekbench install_mariadb install_maxmind install_memcached install_mod_pagespeed install_mysql install_mysql_setup install_mysql_to_sqlite3 install_ondrej_apache install_ondrej_php install_phpbu install_phpinfo install_portainer install_postfix install_python3_pip install_redis install_rkhunter install_security install_speedtest install_sqlite3_to_mysql install_syncthing install_terminal_utils install_virtualmin install_webmin install_wp_cli is_installed restart_lamp restart_lemp sendmail_fixed setup_cloudflare_ufw setup_apache setup_fqdn setup_hostname setup_mysql setup_rkhunter setup_ondrej_apache_repository setup_ondrej_php_repository setup_script_log setup_security setup_security_sshd setup_sudo_user setup_syncthing setup_unattended_upgrades"
SHELLPER_COMMAND_NOT_FOUND="Command not found"
SHELLPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)" # https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself?answertab=votes#tab-top
SHELLPER_HELP_AUTOCOMPLETE="• Press [tab ⇄] to show command suggestions."
SHELLPER_HELP_START="Type a command: "
SHELLPER_VERSION="0.4.0"

# Versions supported
GEEKBENCH_VERSION="6.0.1"
PHP_VERSION="8.2"
RKHUNTER_VERSION="1.4.6"

#  +----------------+
#  | Shellper Init. |
#  +----------------+

# Logo and version.
function shellper_logo {
	cat <<EOF
	
  █████████  █████               ████  ████                              
 ███░░░░░███░░███               ░░███ ░░███                              
░███    ░░░  ░███████    ██████  ░███  ░███  ████████   ██████  ████████ 
░░█████████  ░███░░███  ███░░███ ░███  ░███ ░░███░░███ ███░░███░░███░░███
 ░░░░░░░░███ ░███ ░███ ░███████  ░███  ░███  ░███ ░███░███████  ░███ ░░░ 
 ███    ░███ ░███ ░███ ░███░░░   ░███  ░███  ░███ ░███░███░░░   ░███     
░░█████████  ████ █████░░██████  █████ █████ ░███████ ░░██████  █████    
 ░░░░░░░░░  ░░░░ ░░░░░  ░░░░░░  ░░░░░ ░░░░░  ░███░░░   ░░░░░░  ░░░░░     
                                             ░███                        
                                             █████                       
                                            ░░░░░ v$SHELLPER_VERSION

EOF
}

# Shellper launched from shellper.sh.
function shellper {
	# Only show one during first load
	if [ "$1" != "0" ]; then
		shellper_logo
	fi

	# If vlwrap is not installed go without autocomplete
	if [ "$(is_installed rlwrap)" -eq 0 ]; then
		echo -n "$SHELLPER_HELP_START"
		read answer
	else
		# Only show one during first load
		if [ "$1" != "0" ]; then
			echo "$SHELLPER_HELP_AUTOCOMPLETE"
		fi

		# Autocomplete suggestions
		# https://unix.stackexchange.com/questions/278631/bash-script-auto-complete-for-user-input-based-on-array-data
		answer=$(rlwrap -S "$SHELLPER_HELP_START" -e '' -i -f <(echo "${SHELLPER_AUTOCOMPLETE_HINTS[@]}") -o cat)
	fi

	# Quit
	if echo "$answer" | grep -iq "^q\|^exit"; then
		exit 0
	fi

	answer_function=$(echo "$answer" | cut -f1 -d" ")

	# Command was provided via user input
	if [ -n "$answer" ] && [[ $(type -t "$answer_function") == function ]]; then
		($answer)
	else
		echo "[Error] $SHELLPER_COMMAND_NOT_FOUND:$answer"
	fi

	shellper 0
}

#  +-----------+
#  | Functions |
#  +-----------+

function apache_restart {
	sudo systemctl restart apache2.service
}

function apt_update_upgrade {
	sudo apt update
	# https://bugs.launchpad.net/ubuntu/+source/ansible/+bug/1833013 - 1/2/2020
	UCF_FORCE_CONFOLD=1 DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -qq -y upgrade
}

function ask_mariadb_mysql {
	if [ ! -n "$1" ]; then
		UNATTENDED="0"
	else
		UNATTENDED="$1"
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
		MYSQL_SECURE=0
	fi
	export MYSQL
	export MYSQL_SECURE
}

function ask_reboot {
	echo -n "$SHELLPER_ASK_REBOOT"
	sleep 30
	sudo reboot
}

function crontab_backup {
	crontab -l >$(date +%Y%m%d).crontab
}

function current_ssh_users {
	netstat -tnpa | grep 'ESTABLISHED.*sshd'
}

function debian_frontend_noninteractive {
	DEBIAN_FRONTEND=noninteractive
	UCF_FORCE_CONFOLD=1
	export DEBIAN_FRONTEND
	export UCF_FORCE_CONFOLD
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
		if [ $(echo "$line" | grep -c -P "^\s*$2\s+") = "1" ]; then
			match=1
			echo "$2 $3" >>$TMPFILE
		else
			echo "$line" >>$TMPFILE
		fi
	done <$INFILE

	# append option if not found in config
	if [ "$match" != "1" ] && [ "$4" = "1" ]; then
		echo "$2 $3" >>$TMPFILE
	fi

	# cp -f $TMPFILE $INFILE
	mv $TMPFILE $INFILE
	sync
}

function gen_password {
	if [ ! -n "$1" ]; then
		LEN="20"
	else
		LEN="$1"
	fi
	PASS="$(head -c 32 /dev/urandom | base64 | fold -w $LEN | head -n 1)"
	echo "$(sed -e 's/[[:space:]]*$//' <<<${PASS})"
}

function get_all_users {
	cut -d: -f1 /etc/passwd
}

function get_lamp_status {
	PHP=get_php_version
	echo "$(systemctl status apache2)"
	echo "$(apachectl -M | grep --color security)"
	echo "$(systemctl status $PHP-fpm)"
	echo "$(systemctl status mysql)"
	echo "$(sudo ufw status verbose)"
}

function get_parent_dir {
	echo "$(dirname "$(pwd)")"
}

function get_php_version {
	echo "$(systemctl status | grep -io 'php[7-99].[0-9]')"
}

function get_public_ip {
	echo "$(curl ifconfig.me)"
}

function get_random_lwr_string {
	if [ ! -n "$1" ]; then
		LEN="3"
	else
		LEN="$1"
	fi
	echo "$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w $LEN | head -n 1)"
}

function get_ssh_session_ip {
	echo "$SSH_CLIENT" | cut -d" " -f1
}

function hdd_test {
	# TODO: Add selectable drives
	if [ ! -n "$1" ]; then
		HDD="/dev/sda"
	else
		HDD="$1"
	fi
	sudo hdparm -Tt "$HDD"
}

function install_acme_sh {
	wget -O - https://get.acme.sh | sh
}

function install_apache_mod_security {
	sudo apt install -y libapache2-mod-security2
	sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
	file_change_append "/etc/modsecurity/modsecurity.conf" "SecRuleEngine" "On" 0
	sudo a2enmod security2
}

function install_composer {
	EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

	if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
		echo >&2 'ERROR: Invalid installer checksum'
		rm composer-setup.php
		exit 1
	fi

	php composer-setup.php --quiet
	RESULT=$?
	rm composer-setup.php

	if [ "$RESULT" != "0" ]; then
		echo "$RESULT"
	fi

	sudo mv composer.phar /usr/local/bin/composer
}

function install_certbot {
	sudo apt install -y software-properties-common
	sudo add-apt-repository -y universe
	sudo add-apt-repository -y ppa:certbot/certbot
	apt_update_upgrade
	sudo apt install -y certbot python-certbot-apache
}

function install_clamav {
	sudo apt install -y clamav clamav-daemon
	sudo systemctl stop clamav-freshclam
	sudo freshclam
	sudo systemctl start clamav-freshclam
}

function install_docker {
	if [ "$(is_installed docker)" -eq 0 ]; then
		apt_update_upgrade
		sudo apt install ca-certificates curl gnupg release
		sudo mkdir -p /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
		apt_update_upgrade
		sudo apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
	fi
}

function install_fail2ban {
	sudo apt install -y fail2ban
	cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
	cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
	sudo systemctl start fail2ban
	sudo systemctl enable fail2ban
}

function install_fish {
	sudo apt install -y fish
	chsh -s $(which fish)
}

function install_geekbench {
	wget "https://cdn.geekbench.com/Geekbench-$GEEKBENCH_VERSION-Linux.tar.gz"
	tar -zxvf Geekbench-*.*.*-Linux.tar.gz
}

function install_mariadb {
	sudo apt install -y mariadb-server mariadb-client
	echo "Sleeping while MySQL starts up for the first time..."
	sleep 5
}

function install_maxmind {
	sudo add-apt-repository -y ppa:maxmind/ppa
	apt_update_upgrade
	sudo apt install -y geoipupdate libmaxminddb0 libmaxminddb-dev mmdb-bin
}

function install_memcached {
	sudo apt install -y memcached php-memcached
}

function install_mod_pagespeed {
	if [ ! -n "$1" ]; then
		BRANCH="stable"
	else
		BRANCH="$1"
	fi

	wget -q -O- https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add

	case "$BRANCH" in
	"beta")
		wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-beta_current_amd64.deb
		;;
	*)
		wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb
		;;
	esac

	sudo dpkg -i mod-pagespeed-*.deb
	sudo apt -f -y install
}

function install_mysql {
	sudo apt install -y mysql-server mysql-client
	echo "Sleeping while MySQL starts up for the first time..."
	sleep 5
}

function install_mysql_setup {
	if [ ! -n "$1" ]; then
		echo "mysql_install() requires the root pass as its first argument"
		return 1
	fi
	echo "mysql-server mysql-server/root_password password $1" | debconf-set-selections
	echo "mysql-server mysql-server/root_password_again password $1" | debconf-set-selections
}

function install_mysql_to_sqlite3 {
	install_python3_pip
	pip install mysql-to-sqlite3
}

function install_ondrej_apache {
	sudo apt install -y apache2 apache2-utils
}

function install_ondrej_php {
	if [ ! -n "$1" ]; then
		PHP="php$PHP_VERSION"
	else
		PHP="php$1"
	fi
	export PHP
	sudo apt install -y $PHP libapache2-mod-$PHP $PHP-bcmath $PHP-cli $PHP-common $PHP-curl $PHP-fpm $PHP-gd $PHP-mbstring $PHP-mysql $PHP-opcache $PHP-pspell $PHP-readline $PHP-snmp $PHP-soap $PHP-sqlite3 $PHP-xml $PHP-xsl $PHP-zip php-imagick
	if [ ! command -v a2enmod ] &>/dev/null; then
		echo "Apache not installed."
	else
		a2enmod proxy_fcgi setenvif
		a2enconf "$PHP"-fpm
		a2dismod "$PHP"
		apache_restart
	fi
}

function install_phpbu {
	wget https://phar.phpbu.de/phpbu.phar
	chmod +x phpbu.phar
	sudo mv phpbu.phar /usr/local/bin/phpbu
}

function install_phpinfo {
	sudo echo "<?php phpinfo();" >"/var/www/html/phpinfo.php"
	sudo chown -R www-data:www-data /var/www/html
}

function install_portainer {
	# Check if docker is installed.
	install_docker

	# Setup portainer data directory.
	sudo docker volume create portainer_data

	CMD='sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/'
	BUSINESS='portainer-ee:latest'
	COMMUNITY='portainer-ce:latest'

	if [ "$1" = "business" ]; then
		CMD="$CMD$BUSINESS"
	else
		CMD="$CMD$COMMUNITY"
	fi

	# Execute $CMD
	$CMD

	# Check if Portainer is installed
	if [ "$(sudo docker ps -a | grep portainer | wc -l)" -eq 1 ]; then
		echo "Portainer installed successfully."
	else
		echo "Portainer failed to install."
	fi
}

function install_postfix {
	sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix

	# Installs postfix and configure to listen only on the local interface. Also
	# allows for local mail delivery
	echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
	echo "postfix postfix/mailname string localhost" | debconf-set-selections
	echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections

	/usr/sbin/postconf -e "inet_interfaces = loopback-only"
	#/usr/sbin/postconf -e "local_transport = error:local delivery is disabled"

	sudo systemctl restart postfix
}

function install_python3_pip {
	if [ "$(is_installed python3-pip)" -eq 0 ]; then
		apt_update_upgrade
		sudo apt install -y python3-pip
	fi
}

# https://redis.io/docs/getting-started/installation/install-redis-on-linux/
function install_redis {
	curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
	echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

	apt_update_upgrade
	sudo apt install -y redis
}

function install_rkhunter {
	wget "https://downloads.sourceforge.net/project/rkhunter/rkhunter/$RKHUNTER_VERSION/rkhunter-$RKHUNTER_VERSION.tar.gz"
	tar zxvf "rkhunter-$RKHUNTER_VERSION.tar.gz"
	cd "rkhunter-$RKHUNTER_VERSION"
	sh installer.sh --layout default --install
}

function install_security {
	sudo apt install -y fail2ban ufw
}

function install_speedtest {
	# Source: https://fossbytes.com/test-internet-speed-linux-command-line/
	# Check if pip is installed.
	install_python3_pip
	pip install speedtest-cli
}

function install_sqlite3_to_mysql {
	install_python3_pip
	pip install sqlite3-to-mysql
}

# https://apt.syncthing.net/
function install_syncthing {
	sudo curl -o /usr/share/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
	echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
	apt_update_upgrade
	sudo apt install -y syncthing
}

function install_terminal_utils {
	apt_update_upgrade
	sudo apt install -y aptitude expect git glances screen
}

function install_virtualmin {
	CMD="--force"

	if [ "$1" = "lemp" ] || [ "$2" = "lemp" ]; then
		CMD="$CMD --bundle LEMP"
	fi

	if [ "$1" = "minimal" ] || [ "$2" = "minimal" ]; then
		CMD="$CMD --minimal"
	fi

	wget https://software.virtualmin.com/gpl/scripts/install.sh
	chmod +x install.sh
	sudo ./install.sh $CMD
}

# https://linuxhint.com/install-and-use-webmin-in-ubuntu-22-04/
function install_webmin {
	wget https://download.webmin.com/jcameron-key.asc cat jcameron-key.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/jcameron-key.gpg >/dev/null
	sudo add-apt-repository "deb https://download.webmin.com/download/repository sarge contrib"
	apt_update_upgrade
	sudo apt install -y webmin

	# If UFW is installed, allow Webmin through the firewall.
	if [ "$(is_installed ufw)" -eq 0 ]; then
		sudo ufw allow webmin
	fi
}

function install_wp_cli {
	wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	php wp-cli.phar --info
	chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp
}

# Check if a package is installed.
# Usage: is_installed <package>
function is_installed {
	# Returns 1 if installed and 0 if not installed.
	if command -v "$1" >/dev/null 2>&1; then
		echo 1
	else
		echo 0
	fi
}

function restart_lamp {
	PHP="$(get_php_version)"
	systemctl restart apache2
	systemctl restart "$PHP-fpm"
	systemctl restart mysql
}

function restart_lemp {
	PHP="$(get_php_version)"
	systemctl restart nginx
	systemctl restart "$PHP-fpm"
	systemctl restart mysql
}

# https://www.exchangecore.com/blog/sendmail-email-fixed-monospace-typewriter-font
function sendmail_fixed {
	if [ ! -n "$1" ]; then
		echo "sendmail_fixed() requires a from address as the first argument"
		return 1
	fi
	if [ ! -n "$2" ]; then
		echo "sendmail_fixed() requires a from to address as the second argument"
		return 1
	fi
	if [ ! -n "$3" ]; then
		echo "sendmail_fixed() requires a subject as the third argument"
		return 1
	fi
	if [ ! -n "$4" ]; then
		echo "sendmail_fixed() requires a body as the fourth argument"
		return 1
	fi
	(
		echo "From: $1"
		echo "To: $2"
		echo "Subject: $3"
		cat "$(email_header)" "$4" "$(email_footer)"
	) | sendmail -t
}

function setup_cloudflare_ufw {
	# User arguments are ports to open. If none are provided, open 80 and 443.
	if [ -n "$1" ]; then
		ports="$@"
	else
		ports="80 443"
	fi

	# Loop through cloudflare IPs from https://www.cloudflare.com/ips-v4 and https://www.cloudflare.com/ips-v6 to open ports.
	for ip in $(curl -s https://www.cloudflare.com/ips-v4) $(curl -s https://www.cloudflare.com/ips-v6); do
		for port in $ports; do
			sudo ufw allow from $ip to any proto tcp port $port
		done
	done
}

function setup_apache {
	if [ ! -n "$1" ]; then
		APACHE_MEM=20
	else
		APACHE_MEM="$1"
	fi

	if [ ! -n "$2" ]; then
		PHP="php$PHP_VERSION"
	else
		PHP="php$1"
	fi

	sudo a2dismod mpm_prefork mpm_worker "$PHP"
	sudo a2enmod actions expires proxy_fcgi proxy_http rewrite ssl vhost_alias http2 proxy_http2 setenvif mpm_event
	sudo a2enconf "$PHP-fpm"
	apache_restart

	sudo chown -Rv www-data:www-data "/var/www/"
	sudo chmod 2775 "/var/www/"

	sudo ufw allow 80
	sudo ufw allow 443
}

function setup_fqdn {
	if [ ! -n "$1" ]; then
		echo "setup_fqdn() requires the HOSTNAME as its first argument"
		return 1
	fi
	if [ ! -n "$2" ]; then
		echo "setup_fqdn() requires the FQDN as its first argument"
		return 1
	fi

	# TODO: Consider change to localhost
	echo "$(get_public_ip) $FQDN $HOSTNAME" >>/etc/hosts
}

function setup_hostname {
	if [ ! -n "$1" ]; then
		echo "setup_hostname() requires the HOSTNAME as its first argument"
		return 1
	fi
	if [ ! -n "$2" ]; then
		echo "Optional: setup_hostname() accepts the FQDN as its second argument"
	fi
	hostnamectl set-hostname $1
	if [ -n "$2" ]; then
		setup_fqdn $2 $1
	fi
}

function setup_mysql {
	mysql_secure_installation
}

function setup_rkhunter {
	rkhunter --update
	rkhunter --propupd

	# checkall
	rkhunter -c -sk
}

function setup_ondrej_apache_repository {
	sudo add-apt-repository -y ppa:ondrej/apache2
	apt_update_upgrade
}

function setup_ondrej_php_repository {
	sudo add-apt-repository -y ppa:ondrej/php
	apt_update_upgrade
}

function setup_script_log {
	if [ ! -n "$1" ]; then
		LOG="shellper-$(date +%Y%m%d-%H%M%S)"
	else
		LOG="$1"
	fi
	exec > >(tee -i "/var/log/$LOG.log")
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
}

function setup_security_sshd {
	SSHD_CONFIG="/etc/ssh/sshd_config"
	sed -i "s/#AddressFamily any/AddressFamily inet/g" "$SSHD_CONFIG"
	sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" "$SSHD_CONFIG"
	sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/g" "$SSHD_CONFIG"
	systemctl restart sshd
}

function setup_sudo_user {
	if [ ! -n "$1" ]; then
		USER="deploy"
	else
		USER="$1"
	fi
	if [ ! -n "$2" ]; then
		PASS="0"
	else
		PASS="$2"
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
	if [ ! -n "$1" ]; then
		OWNER="www-data"
	else
		OWNER="$1"
	fi

	sudo systemctl start "syncthing@${OWNER}.service"
	sleep 30
	sudo systemctl stop "syncthing@${OWNER}.service"

	if [ "$2" = "1" ]; then
		SYNCTHING_PATH=$(eval echo "~$OWNER")"/.config/syncthing/config.xml"
		if [ -f "$SYNCTHING_PATH" ]; then
			OWNER="www-data"
			sed -i "s/127.0.0.1:8384/0.0.0.0:8384/g" "$SYNCTHING_PATH"
		else
			echo "setup_syncthing() can't find Syncthing config"
		fi
	fi

	# https://docs.syncthing.net/users/firewall.html
	if [ "$3" = "firewalld" ] || [ "$4" = "firewalld" ]; then
		sudo firewall-cmd --zone=public --add-service=syncthing --permanent
		sudo firewall-cmd --reload
	fi

	if [ "$3" = "ufw" ] || [ "$4" = "ufw" ]; then
		sudo ufw allow 22000:23000/tcp
	fi

	# Fix filesytem error.
	sudo echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf

	# https://docs.syncthing.net/users/autostart.html
	sudo systemctl enable "syncthing@${OWNER}.service"
	sudo systemctl start "syncthing@${OWNER}.service"
}

function setup_unattended_upgrades {
	APT_CONF="/etc/apt/apt.conf.d/10periodic"
	file_change_append "$APT_CONF" "APT::Periodic::Unattended-Upgrade" '"1";' 1
	file_change_append "$APT_CONF" "APT::Periodic::Download-Upgradeable-Packages" '"1";'
	file_change_append "$APT_CONF" "APT::Periodic::AutocleanInterval" '"7";'
}

#  +-------------+
#  | Email Parts |
#  +-------------+

function email_header {
	cat <<EOF
MIME-Version: 1.0
Content-Type: text/html
Content-Disposition: inline
<html>
<body>
<pre style="font: monospace">
EOF
}

function email_footer {
	cat <<EOF
</pre>
</body>
</html>
EOF
}

#  +----------+
#  | Launcher |
#  +----------+

# Launch script if primary processes.
if [[ "$0" = "$BASH_SOURCE" ]]; then
	shellper
fi
