#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

# remove the proton icons we don't want
rm /usr/share/icons/hicolor/128x128/apps/proton-authenticator.png
rm /usr/share/icons/hicolor/256x256@2/apps/proton-authenticator.png
rm /usr/share/icons/hicolor/32x32/apps/proton-authenticator.png

# update icon cache
gtk-update-icon-cache -f /usr/share/icons/hicolor