#!/bin/bash
# v0.2
# <UDF name="sudo_username" Label="New sudo user" default="deploy" />
# <UDF name="sudo_password" Label="New sudo password"/>
# <UDF name="shellper_branch" Label="Shellper Github branch" oneOf="master,dev" default="master"/>

# dependencies
SHELLPER_PATH="$(dirname $(pwd))/shellper/shellper.sh"
if [ ! -f "$SHELLPER_PATH" ]; then
    if [ ! -n "$SHELLPER_BRANCH" ]; then
        SHELLPER_BRANCH="master"
    fi
    CURRENT_DIR="$(pwd)"
    cd ../        
    git clone https://github.com/carmelosantana/shellper -b "$SHELLPER_BRANCH"
    cd "$CURRENT_DIR"
fi
source "$SHELLPER_PATH"
apt_update_upgrade
setup_sudo_user "$SUDO_USERNAME" "$SUDO_PASSWORD"
