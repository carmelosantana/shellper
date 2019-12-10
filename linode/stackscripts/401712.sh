#!/bin/bash
# Helper functions
function apt_setup_update {
  # Force IPv4 and noninteractive update
  echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
}
function set_hostname {
  IP=`hostname -I | awk '{print$1}'`
  HOSTNAME=`dnsdomainname -A`
  hostnamectl set-hostname $HOSTNAME
  echo $IP $HOSTNAME  >> /etc/hosts
}
function mysql_root_preinstall {
  # Set MySQL root password on install
  debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBROOT_PASSWORD"
  debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBROOT_PASSWORD"
}
function run_mysql_secure_installation {
  # Installs expect, runs mysql_secure_installation and runs mysql secure installation.
  apt-get install -y expect
  SECURE_MYSQL=$(expect -c "
  set timeout 10
  spawn mysql_secure_installation
  expect \"Enter current password for root (enter for ):\"
  send \"$DBROOT_PASSWORD\r\"
  expect \"Change the root password?\"
  send \"n\r\"
  expect \"Remove anonymous users?\"
  send \"y\r\"
  expect \"Disallow root login remotely?\"
  send \"y\r\"
  expect \"Remove test database and access to it?\"
  send \"y\r\"
  expect \"Reload privilege tables now?\"
  send \"y\r\"
  expect eof
  ")
  echo "$SECURE_MYSQL"
}
function ufw_install {
  # Install UFW and add basic rules
  apt-get install ufw -y
  ufw default allow outgoing
  ufw default deny incoming
  ufw allow ssh
  ufw enable
  systemctl enable ufw
}
function fail2ban_install {
  # Install and configure Fail2ban
  apt-get install fail2ban -y
  cd /etc/fail2ban
  cp fail2ban.conf fail2ban.local
  cp jail.conf jail.local
  systemctl start fail2ban
  systemctl enable fail2ban
}
function stackscript_cleanup {
  # Force IPv4 and noninteractive upgrade after script runs to prevent breaking nf_conntrack for UFW
  echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
  export DEBIAN_FRONTEND=noninteractive 
  apt-get upgrade -y
  rm /root/StackScript
  rm /root/ssinclude*
  echo "Installation complete!"
}