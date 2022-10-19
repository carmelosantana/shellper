#!/bin/bash

# Setup paths
SHELLPER="shellper.sh"

# First argument can be branch name, default is "master"
BRANCH=${1:-master}

# Setup URL
URL="https://raw.githubusercontent.com/carmelosantana/shellper/$BRANCH/$SHELLPER"

# If curl is installed check if branch is valid
if command -v curl >/dev/null 2>&1; then
    # Check if branch is valid
    if ! curl -s -o /dev/null -I -w "%{http_code}" $URL | grep -q "200"; then
        echo "Branch $BRANCH does not exist."
        exit 1
    else
        curl -s -o "$SHELLPER" "$URL"
    fi
else
    # Download shellper
    wget -q $URL
fi

# Check if file was downloaded
if [ ! -f "$SHELLPER" ]; then
    echo "Failed to download shellper."
    exit 1
fi

# Check + install dependencies
for install in "rlwrap"; do
	if ! command -v "$install" >/dev/null 2>&1; then
        apt update
        apt install -y "$install"
    fi
done

# Set permissions
chmod +x "$SHELLPER"

# Install
mv "$SHELLPER" /usr/local/bin/shellper

# We're done
echo -n "Install complete."
echo

# Clean exit
exit 0
