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
| debian_frontend_noninteractive ||
| echo_install_complete ||
| file_change_append ||
| gen_password ||
| get_all_users ||
| get_lamp_status ||
| get_parent_dir ||
| get_php_version ||
| get_public_ip ||
| get_random_lwr_string ||
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
| sendmail_fixed ||
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
| stackscript_cleanup_ip4 ||
| wp_cron_to_crontab ||

## ToDo

- [ ] Link to `/usr/bin`
- [ ] Apache Superset installer
- [ ] WordPress joblets
- [ ] *Secure* LAMP
- [ ] Check if root during `setup_sudo_user`
- [ ] Add xdebug

## Recently completed

- [x] Fixed `debian_frontend_noninteractive`
- [x] Added `sendmail` wrapper
- [x] Added `stackscript_cleanup_ip4`

## License

[MIT](https://en.wikipedia.org/wiki/MIT_License)
