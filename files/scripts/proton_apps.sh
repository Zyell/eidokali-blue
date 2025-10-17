#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

### Install packages
mkdir temp_apps
cd temp_apps

# download latest protonmail bridge
BRIDGE_RELEASE=$(curl -s https://api.github.com/repos/ProtonMail/proton-bridge/releases/latest)
BRIDGE_RPM_URL=$(echo "$BRIDGE_RELEASE" | grep "browser_download_url.*x86_64.rpm\"" | grep -v "\.sig" | cut -d '"' -f 4)
wget "$BRIDGE_RPM_URL"
BRIDGE_RPM_FILE=$(basename "$BRIDGE_RPM_URL")

# obtain signature
wget https://proton.me/download/bridge/bridge_pubkey.gpg

# import bridge key and check signature
rpm --import bridge_pubkey.gpg

if rpm --checksig "$BRIDGE_RPM_FILE" 2>&1 | grep -q "digests signatures OK"; then
    dnf5 -y install "$BRIDGE_RPM_FILE"
else
    echo "GPG signature verification failed for ProtonMail Bridge!"
    exit 1
fi

# install protonvpn
FEDORA_VERSION=$(cat /etc/fedora-release | cut -d' ' -f 3)
PROTONVPN_REPO_URL="https://repo.protonvpn.com/fedora-${FEDORA_VERSION}-stable/protonvpn-stable-release"

# Get the latest protonvpn-stable-release RPM
PROTONVPN_RELEASE_RPM=$(curl -s "$PROTONVPN_REPO_URL/" | grep -oP 'protonvpn-stable-release-[^"<>]+\.noarch\.rpm' | sort -V | tail -1)

wget "${PROTONVPN_REPO_URL}/${PROTONVPN_RELEASE_RPM}"

# Verify the ProtonVPN GPG key fingerprint
EXPECTED_FINGERPRINT="55AA81128CFFFF46DF140838BC187A13AD10060B"

dnf5 -y install "./${PROTONVPN_RELEASE_RPM}"
dnf5 check-update --refresh || true

# Capture the output from dnf5 installation
dnf5 -y install proton-vpn-gnome-desktop 2>&1 | tee /tmp/protonvpn_install.log

# Extract all fingerprints from the output (removes spaces and colons)
IMPORTED_FINGERPRINTS=$(grep -oP 'Fingerprint:\s*\K[A-F0-9:\s]+' /tmp/protonvpn_install.log | tr -d ' :')

# Count how many fingerprints were found
FINGERPRINT_COUNT=$(echo "$IMPORTED_FINGERPRINTS" | grep -c '^[A-F0-9]\+$' || true)

if [ "$FINGERPRINT_COUNT" -ne 1 ]; then
    echo "ERROR: Expected exactly 1 GPG key to be imported, but found $FINGERPRINT_COUNT"
    if [ "$FINGERPRINT_COUNT" -gt 1 ]; then
        echo "Imported fingerprints:"
        echo "$IMPORTED_FINGERPRINTS"
    fi
    rm -f /tmp/protonvpn_install.log
    exit 1
fi

ACTUAL_FINGERPRINT="$IMPORTED_FINGERPRINTS"

if [ "$ACTUAL_FINGERPRINT" != "$EXPECTED_FINGERPRINT" ]; then
    echo "ERROR: GPG key fingerprint mismatch!"
    echo "Expected: $EXPECTED_FINGERPRINT"
    echo "Got:      $ACTUAL_FINGERPRINT"
    rm -f /tmp/protonvpn_install.log
    exit 1
fi

echo "GPG key fingerprint verified successfully: $ACTUAL_FINGERPRINT"
rm -f /tmp/protonvpn_install.log

dnf5 -y install libappindicator-gtk3 gnome-shell-extension-appindicator gnome-extensions-app

# install proton authenticator
wget https://proton.me/download/authenticator/linux/version.json -O authenticator_version.json
EXPECTED_SHA512=$(jq -r '.Releases[0].File[] | select(.Identifier == ".rpm (Fedora/RHEL)") | .Sha512CheckSum' authenticator_version.json)

wget https://proton.me/download/authenticator/linux/ProtonAuthenticator.rpm
ACTUAL_SHA512=$(sha512sum ProtonAuthenticator.rpm | cut -d ' ' -f 1)

if [ "$ACTUAL_SHA512" != "$EXPECTED_SHA512" ]; then
    echo "SHA512 checksum verification failed for ProtonAuthenticator!"
    echo "Expected: $EXPECTED_SHA512"
    echo "Got:      $ACTUAL_SHA512"
    exit 1
fi

dnf5 -y install ProtonAuthenticator.rpm

# install proton password manager
wget https://proton.me/download/PassDesktop/linux/x64/version.json -O pass_version.json
EXPECTED_SHA512=$(jq -r '.Releases[0].File[] | select(.Identifier == ".rpm (Fedora/RHEL)") | .Sha512CheckSum' pass_version.json)

wget https://proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm
ACTUAL_SHA512=$(sha512sum ProtonPass.rpm | cut -d ' ' -f 1)

if [ "$ACTUAL_SHA512" != "$EXPECTED_SHA512" ]; then
    echo "SHA512 checksum verification failed for ProtonPass!"
    echo "Expected: $EXPECTED_SHA512"
    echo "Got:      $ACTUAL_SHA512"
    exit 1
fi

dnf5 -y install ProtonPass.rpm

# install protonmail client
wget https://proton.me/download/mail/linux/version.json -O mail_version.json
EXPECTED_SHA512=$(jq -r '.Releases[0].File[] | select(.Identifier == ".rpm (Fedora/RHEL)") | .Sha512CheckSum' mail_version.json)

wget https://proton.me/download/mail/linux/ProtonMail-desktop-beta.rpm
ACTUAL_SHA512=$(sha512sum ProtonMail-desktop-beta.rpm | cut -d ' ' -f 1)

if [ "$ACTUAL_SHA512" != "$EXPECTED_SHA512" ]; then
    echo "SHA512 checksum verification failed for ProtonMail!"
    echo "Expected: $EXPECTED_SHA512"
    echo "Got:      $ACTUAL_SHA512"
    exit 1
fi

wget https://proton.me/download/mail/linux/ProtonMail-desktop-beta.rpm
dnf5 -y install ProtonMail-desktop-beta.rpm

cd ..
rm -rf ./temp_apps