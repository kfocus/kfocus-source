#!/bin/bash
#
# Remove OEM files from the system.

rm -rf \
  /etc/calamares \
  /etc/sudoers \
  /usr/bin/basicwallpaper \
  /usr/bin/calamares-finish-oem \
  /usr/bin/calamares-logs-helper \
  /usr/libexec/calamares-oemfinish.sh \
  /usr/libexec/kfocus-enable-autosnapshot \
  /usr/libexec/kfocus-prep-user \
  /usr/libexec/kubuntu-oem-env-shim \
  /usr/libexec/start-kubuntu-oem-env \
  /usr/lib/kfocus/bin/kfocus-chain-helper-* \
  /usr/share/applications/calamares-finish-oem.desktop \
  /usr/share/applications/kfocus-chain-helper.desktop \
  /usr/share/wayland-sessions/kubuntu-oem-environment.desktop;

mv /etc/sudoers.orig /etc/sudoers;
