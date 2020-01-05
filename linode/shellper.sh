#!/bin/bash
# v0.3
# <UDF name="sudo_username" Label="New sudo user" default="deploy" />
# <UDF name="sudo_password" Label="New sudo password"/>
# <UDF name="shellper_branch" Label="Shellper Github branch" oneOf="master,dev" default="master"/>

SHELLPER_PATH="shellper/shellper.sh"
if [ ! -f "$SHELLPER_PATH" ]; then
    if [ ! -n "$SHELLPER_BRANCH" ]; then
        SHELLPER_BRANCH="master"
    fi
    git clone https://github.com/carmelosantana/shellper -b "$SHELLPER_BRANCH"
    echo 'Git clone shellper.sh'
fi

if [ ! -f "$SHELLPER_PATH" ]; then
    echo 'Error loading shellper.sh'
    exit 1
fi

source "$SHELLPER_PATH"

apt_update_upgrade
setup_sudo_user "$SUDO_USERNAME" "$SUDO_PASSWORD"