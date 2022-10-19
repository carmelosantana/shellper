#!/bin/bash

source ../shellper.sh

if [ ! -n "$1" ]; then
    UNATTENDED="0"
else
    UNATTENDED="$1"
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

apt_update_upgrade
setup_unattended_upgrades
install_ondrej_apache
install_ondrej_php
install_php_test
ask_mariadb_mysql "$UNATTENDED"
install_postfix
get_lamp_status

echo -n "+ ToDo"
echo "  - Update hostname"
echo "  - General security"
if [ "$MYSQL_SECURE" = "0" ]; then
    echo "  - mysql_secure_installation"
fi

echo -n "Install complete."
