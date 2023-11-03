#!/bin/bash
_rx_dir='/var/lib/kfocus/';
mkdir -p "${_rx_dir}" || exit;
echo '1.3.0-0' > "${_rx_dir}/focusrx_version";

dpkg --add-architecture i386;
add-apt-repository -y multiverse;
add-apt-repository -y ppa:kfocus-team/release;
apt-get -y install kfocus-apt-source;

apt-get update;
apt-get -y install kfocus-main;
apt-get -y purge google-chrome-unstable;
apt-get update;

# Retry if this fails due to https timeouts from launchpad or others.
_install_success="no";
_install_attempts=0;
while [ "${_install_success}" = "no" ] && [ "${_install_attempts}" != "3" ]; do
  apt-get -y full-upgrade;
  if [ "$?" != "0" ]; then
    _install_attempts=$((_install_attempts + 1));
    continue;
  fi

  apt-get -y install linux-generic-hwe-22.04-kfocus \
    linux-headers-generic-hwe-22.04-kfocus \
    linux-image-generic-hwe-22.04-kfocus \
    linux-tools-generic-hwe-22.04-kfocus;
  if [ "$?" != "0" ]; then
    _install_attempts=$((_install_attempts + 1));
    continue;
  fi

  apt-get -y autopurge;
  
  if [ "$?" != "0" ]; then
    _install_attempts=$((_install_attempts + 1));
    continue;
  fi

  _install_success="yes";
done

if [ "${_install_success}" = "no" ]; then
  exit 1;
fi
