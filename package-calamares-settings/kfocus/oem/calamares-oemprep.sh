#!/bin/bash
#
# Puts the installed system into OEM configuration mode. Argument 1 is the
# path to the installed system's root directory.

# Install the OEM configuration for Calamares
tar xvzf /etc/calamares/oemconfig.tar.gz -C "$1" --strip-components=2;
chown -R 1000:1000 "$1"/home/oem

# Enable passwordless sudo for the OEM user, making sure this can be undone later
mv "$1"/etc/sudoers "$1"/etc/sudoers.orig
mv "$1"/etc/sudoers.oem "$1"/etc/sudoers
