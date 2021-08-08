#!/bin/bash

#  +-+-+-+-+-+
#  | Globals |
#  +-+-+-+-+-+
#
#	Versioning and settings.

# Autocomplete hints
SHELLPER_ASK_REBOOT="Reboot in 30 seconds... CTRL C to exit script and cancel reboot."
SHELLPER_AUTOCOMPLETE_HINTS="apache_restart apt_update_upgrade ask_mariadb_mysql ask_reboot crontab_backup current_ssh_users file_change_append gen_password get_all_users get_lamp_status get_parent_dir get_php_version get_public_ip get_random_lwr_string hdd_test install_acme_sh install_apache_mod_security install_composer install_certbot install_clamav install_fish install_geekbench install_imagemagick install_ffmpeg install_mariadb install_maxmind install_memcached install_mod_pagespeed install_mycroft install_mysql install_mysql_setup install_ondrej_apache install_ondrej_php install_php_test install_phpbu install_postfix install_rkhunter install_security install_speedtest install_syncthing install_terminal_utils install_virtualmin install_webmin install_wp_cli restart_lamp setup_fqdn setup_hostname setup_script_log setup_apache setup_mysql setup_rkhunter setup_security setup_security_sshd setup_sudo_user setup_syncthing setup_unattended_upgrades"
SHELLPER_COMMAND_NOT_FOUND="Command not found"
SHELLPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)" # https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself?answertab=votes#tab-top
SHELLPER_HELP_AUTOCOMPLETE="• Press tab ⇄ to show command suggestions."
SHELLPER_HELP_QUIT="• Type q or exit to quit."
SHELLPER_HELP_START="[Start] Type a command: "
SHELLPER_VERSION="0.2.2"

# Geekbench
GEEKBENCH_VERSION="5.4.1"

# PHP
PHP_VERSION="8.0"

# Rootkit Hunter
RKHUNTER_VERSION="1.4.6"

#  +--------------------+
#  | Shellper internals |
#  +--------------------+
#
#	Functions that support running Shellper.

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

function shellper {
	# Only show one during first load
	if [ "$1" != "0" ]; then
		shellper_logo
	fi

	# If vlwrap is not installed go without autocomplete
	if ! command -v rlwrap &>/dev/null; then
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

	# Exiting
	if echo "$answer" | grep -iq "^q\|^exit"; then
		exit 0

	# Command was provided via user input
	elif [ -n "$answer" ] && [[ $(type -t "$answer") == function ]]; then
		($answer)
	else
		echo "[Error] $SHELLPER_COMMAND_NOT_FOUND:$answer"
	fi

	shellper 0
}

#  +-------------------+
#  | Functions library |
#  +-------------------+
#
#	Functions available to the end user during Shellper's execution.

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

function echo_install_complete {
	echo
	echo "+------------------+"
	echo "| Install complete |"
	echo "+------------------+"
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
	echo "$(systemctl status memcached)"
	echo "$(sudo ufw status verbose)"
}

function get_parent_dir {
	echo "$(dirname "$(pwd)")"
}

function get_php_version {
	echo "$(systemctl status | grep -io 'php[7-9].[0-9]')"
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

function hdd_test {
	if [ ! -n "$1" ]; then
		HDD="/dev/sda"
	else
		HDD="$1"
	fi
	sudo hdparm -Tt "$HDD"
}

function install_acme_sh {
	wget -O -  https://get.acme.sh | sh
}

function install_apache_mod_security {
	sudo apt install libapache2-mod-security2
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
	exit $RESULT
}

function install_certbot {
	sudo apt -y install software-properties-common
	sudo add-apt-repository -y universe
	sudo add-apt-repository -y ppa:certbot/certbot
	apt_update_upgrade
	sudo apt -y install certbot python-certbot-apache
}

function install_clamav {
	sudo apt -y install clamav clamav-daemon
	sudo systemctl stop clamav-freshclam
	sudo freshclam
	sudo systemctl start clamav-freshclam
}

function install_fail2ban {
	sudo apt -y install fail2ban
	cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
	cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
	sudo systemctl start fail2ban
	sudo systemctl enable fail2ban
}

function install_fish {
	sudo apt -y install fish
	chsh -s $(which fish)
}

function install_geekbench {
	wget "http://cdn.geekbench.com/Geekbench-$GEEKBENCH_VERSION-Linux.tar.gz"
	tar -zxvf Geekbench-*.*.*-Linux.tar.gz
}

function install_imagemagick {
	sudo apt -y install imagemagick
}

function install_ffmpeg {
	sudo apt -y install ffmpeg
}

function install_mariadb {
	sudo apt -y install mariadb-server mariadb-client
	echo "Sleeping while MySQL starts up for the first time..."
	sleep 5
}

function install_maxmind {
	sudo add-apt-repository -y ppa:maxmind/ppa
	apt_update_upgrade
	sudo apt -y install geoipupdate libmaxminddb0 libmaxminddb-dev mmdb-bin
}

function install_memcached {
	sudo apt -y install memcached
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
	sudo apt -y install mysql-server mysql-client
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

function install_ondrej_apache {
	sudo add-apt-repository -y ppa:ondrej/apache2
	apt_update_upgrade
	sudo apt install apache2 apache2-utils
}

function install_ondrej_php {
	if [ ! -n "$1" ]; then
		PHP="php$PHP_VERSION"
	else
		PHP="php$1"
	fi
	export PHP
	sudo add-apt-repository -y ppa:ondrej/php
	sudo apt -y install $PHP libapache2-mod-$PHP $PHP-bcmath $PHP-cli $PHP-common $PHP-curl $PHP-fpm $PHP-gd $PHP-int $PHP-mbstring $PHP-mysql $PHP-opcache $PHP-pspell $PHP-readline $PHP-snmp $PHP-soap $PHP-sqlite3 $PHP-xml $PHP-xsl $PHP-zip php-imagick php-memcached
	if [ ! command -v a2enmod ] &>/dev/null; then
		echo "Apache not installed."
	else
		a2enmod proxy_fcgi setenvif
		a2enconf "$PHP"-fpm
		a2dismod "$PHP"
		apache_restart
	fi
}

function install_php_test {
	sudo echo "<?php phpinfo();" >"/var/www/html/info.php"
}

function install_phpbu {
	wget http://phar.phpbu.de/phpbu.phar
	chmod +x phpbu.phar
	sudo mv phpbu.phar /usr/local/bin/phpbu
}

function install_postfix {
	sudo DEBIAN_FRONTEND=noninteractive apt -y install postfix

	# Installs postfix and configure to listen only on the local interface. Also
	# allows for local mail delivery
	echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
	echo "postfix postfix/mailname string localhost" | debconf-set-selections
	echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections

	/usr/sbin/postconf -e "inet_interfaces = loopback-only"
	#/usr/sbin/postconf -e "local_transport = error:local delivery is disabled"

	sudo systemctl restart postfix
}

function install_rkhunter {
	wget "https://downloads.sourceforge.net/project/rkhunter/rkhunter/$RKHUNTER_VERSION/rkhunter-$RKHUNTER_VERSION.tar.gz"
	tar zxvf "rkhunter-$RKHUNTER_VERSION.tar.gz"
	cd "rkhunter-$RKHUNTER_VERSION"
	sh installer.sh --layout default --install
}

function install_security {
	sudo apt -y install fail2ban ufw
}

function install_speedtest {
	# Source:
	# https://fossbytes.com/test-internet-speed-linux-command-line/
	sudo apt install -y python3-pip
	pip install speedtest-cli
}

function install_syncthing {
	wget -q -O- https://syncthing.net/release-key.txt | sudo apt-key add
	echo "deb https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
	apt_update_upgrade
	sudo apt install -y syncthing
}

function install_terminal_utils {
	apt_update_upgrade
	sudo apt install -y aptitude expect git glances screen
}

function install_virtualmin {
	wget https://software.virtualmin.com/gpl/scripts/install.sh
	chmod +x install.sh
	sudo ./install.sh
}

function install_webmin {
	wget -q -O- http://www.webmin.com/jcameron-key.asc | sudo apt-key add
	echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
	echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" | sudo tee -a /etc/apt/sources.list
	apt_update_upgrade
	sudo apt install -y webmin
	if [ "$1" = "1" ]; then
		sudo ufw allow webmin
	fi
}

function install_wp_cli {
	wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	php wp-cli.phar --info
	chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp
}

function restart_lamp {
	systemctl restart apache2
	PHP="$(get_php_version)"
	systemctl restart "$PHP-fpm"
	systemctl restart memcached
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
		echo "setup_fqdn() requires the HOSTNAME as its first argument"
		return 1
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
	if [ ! -n "$1" ]; then
		LOG="shellper-$(date +%Y%m%d-%H%M%S)"
	else
		LOG="$1"
	fi
	exec > >(tee -i "/var/log/$LOG.log")
}

function setup_apache {
	if [ ! -n "$1" ]; then
		APACHE_MEM=20
	else
		APACHE_MEM="$1"
	fi

	if [ ! -n "$2" ]; then
		PHP="php8.0"
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

function setup_mysql {
	mysql_secure_installation
}

function setup_rkhunter {
	rkhunter --update
	rkhunter --propupd

	# checkall
	rkhunter -c -sk
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
		OWNER="deploy"
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
	if [ "$3" = "1" ]; then
		sudo ufw allow syncthing
		sudo ufw allow syncthing-gui
	fi

	sudo echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf
	sudo systemctl enable "syncthing@${OWNER}.service"
	sudo systemctl start "syncthing@${OWNER}.service"
}

function setup_unattended_upgrades {
	APT_CONF="/etc/apt/apt.conf.d/10periodic"
	file_change_append "$APT_CONF" "APT::Periodic::Unattended-Upgrade" '"1";' 1
	file_change_append "$APT_CONF" "APT::Periodic::Download-Upgradeable-Packages" '"1";'
	file_change_append "$APT_CONF" "APT::Periodic::AutocleanInterval" '"7";'
}

#  +-----------------+
#  | Email templates |
#  +-----------------+
#
#  Parts for composing emails.

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

#  +----------------------+
#  | Deprecated Functions |
#  +----------------------+
#
#  Patches to keep deprecated functions working as expected. These functions
#  are no longer supported and should not be used.

function install_imagemagick_ffmpeg {
	install_ffmpeg
	install_imagemagick
}

function install_php_test {
	install_phpinfo
}

#  +-----------------+
#  | Launch Shellper |
#  +-----------------+
#
#	Launch script if primary processes.

if [[ "$0" = "$BASH_SOURCE" ]]; then
	shellper
fi
