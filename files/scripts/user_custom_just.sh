#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

# Adding reference to eidokali user managed just recipes
echo "import? \"~/.config/just/eidokali.just\"" >>/usr/share/ublue-os/justfile