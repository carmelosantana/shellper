#!/bin/bash

# Setup paths
SHELLPER="shellper.sh"

# Check + install dependencies
for install in "rlwrap"; do
    if ! $(command -v "$install") &>/dev/null; then
        apt update
        apt install "$install" -y
    fi
done

# Download directly from github branch
wget "https://raw.githubusercontent.com/carmelosantana/shellper/master/$SHELLPER"

# Set permissions
chmod +x "$SHELLPER"

# Install
mv "$SHELLPER" /usr/local/bin/shellper

# We're done
echo -n "Install complete."
echo
