# Shellper

Simple tools to automate server provisioning and maintenance.

[![install_lamp](https://raw.githubusercontent.com/carmelosantana/shellper-assets/master/install-lamp-v0.12.gif)](https://www.youtube.com/watch?v=RiqMoP9DCSU)

## Compatible with

`Ubuntu 18.04 LTS` `Ubuntu 19.10`

## Usage

1. Install

```bash
git clone https://github.com/carmelosantana/shellper.git shellper
cd "shellper"
chmod +x shellper.sh
```

2. Run

```bash
(sudo) ./shellper.sh
```

## Contents

Joblets

| Function | Arguments |
| --- | --- |
| install_lamp ||

Functions

| Function | Arguments |
| --- | --- |
| apache_restart ||
| apt_update_upgrade ||
| ask_mariadb_mysql ||
| ask_reboot ||
| crontab_backup ||
| current_ssh_users ||
| echo_install_complete ||
| file_change_append ||
| gen_password ||
| get_parent_dir ||
| get_all_users ||
| get_random_lwr_string ||
| get_lamp_status ||
| get_php_version ||
| hdd_test ||
| increase_lvm_size ||
| install_apache_mod_security ||
| install_certbot ||
| install_fish ||
| install_geekbench ||
| install_imagemagick_ffmpeg ||
| install_mariadb ||
| install_maxmind ||
| install_memcached ||
| install_mod_pagespeed ||
| install_mycroft ||
| install_mysql ||
| install_mysql_setup ||
| install_ondrej_apache ||
| install_ondrej_php ||
| install_php_test ||
| install_postfix ||
| install_security ||
| install_speedtest ||
| install_syncthing ||
| install_terminal_utils ||
| install_webmin ||
| install_wp_cli ||
| restart_lamp ||
| setup_debian_frontend_noninteractive ||
| setup_fqdn ||
| setup_hostname ||
| setup_script_log ||
| setup_apache ||
| setup_mysql ||
| setup_security ||
| setup_security_sshd ||
| setup_sudo_user ||
| setup_syncthing ||
| setup_unattended_upgrades ||
| wp_cron_to_crontab ||

## ToDo

- [ ] Link to `/usr/bin`
- [ ] Apache Superset installer
- [ ] WordPress joblets
- [ ] *Secure* LAMP
- [ ] Check if root during `setup_sudo_user`
- [ ] Add xdebug

## Recently completed

- [x] Add options to functions with predefined values (hdd_test, increase_lvm_size)

## License

[MIT](https://en.wikipedia.org/wiki/MIT_License)
