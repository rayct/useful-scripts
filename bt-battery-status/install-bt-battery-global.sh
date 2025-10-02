#!/bin/bash
# install-bt-battery-global.sh

PREFIX="/usr/local/bin"
SCRIPT_NAME="bt-battery"
SOURCE="bt-battery.sh"
TARGET="$PREFIX/$SCRIPT_NAME"

echo "Installing $SOURCE to $TARGET..."

sudo install -m 755 "$SOURCE" "$TARGET"
sudo chown root:root "$TARGET"

echo "Installed globally as: $SCRIPT_NAME"
echo "You can now run it with: $SCRIPT_NAME"

