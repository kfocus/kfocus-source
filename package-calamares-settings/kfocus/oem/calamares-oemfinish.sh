#!/bin/bash
#
# Remove OEM files from the system.

rm -rf /etc/calamares /usr/bin/basicwallpaper /usr/bin/calamares-finish-oem /usr/share/applications/calamares-finish-oem.desktop /usr/share/xsessions/kubuntu-oem-environment.desktop /usr/libexec/start-kubuntu-oem-env /etc/sudoers /usr/bin/calamares-logs-helper /usr/libexec/calamares-oemfinish.sh /usr/libexec/kfocus-prep-user /usr/lib/kfocus/bin/kfocus-chain-helper-* /usr/share/applications/kfocus-chain-helper.desktop

mv /etc/sudoers.orig /etc/sudoers