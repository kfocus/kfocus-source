#!/bin/bash
_rx_dir='/var/lib/kfocus';
mkdir -p "${_rx_dir}" || exit;
echo '1.3.0-0' > "${_rx_dir}/focusrx_version";

if ! apt-get -y -f install; then
  exit 1;
fi

if ! dpkg --configure -a; then
  exit 1;
fi

apt list --installed | awk -F '/' '{print $1}' > "${_rx_dir}/pre-install-pkgs.list";
apt-cache policy |sed '/^Pinned packages:/q' | grep -iE '^\s*release' > "${_rx_dir}/pre-install-repos.list";

dpkg --add-architecture i386;
add-apt-repository -y multiverse;

if ! add-apt-repository -y ppa:kfocus-team/release; then
  exit 1;
fi

# Retry if this fails due to https timeouts from launchpad or others.
_install_success='no';
_install_attempts=0;
while [ "${_install_success}" = 'no' ] && [ "${_install_attempts}" != '3' ]; do
  if ! DEBIAN_FRONTEND=noninteractive \
    apt-get -y install kfocus-apt-source; then
    _install_attempts=$((_install_attempts + 1));
    continue;
  fi

  apt-get update;

  if ! DEBIAN_FRONTEND=noninteractive apt-get -y install kfocus-main; then
    _install_attempts=$((_install_attempts + 1));
    continue;
  fi

  if ! DEBIAN_FRONTEND=noninteractive \
    apt-get -y purge google-chrome-unstable; then
    _install_attempts=$((_install_attempts + 1));
    continue;
  fi

  apt-get update;

  if ! DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade; then
    _install_attempts=$((_install_attempts + 1));
    continue;
  fi

  if ! DEBIAN_FRONTEND=noninteractive \
    apt-get -y install linux-generic-hwe-22.04-kfocus \
    linux-headers-generic-hwe-22.04-kfocus \
    linux-image-generic-hwe-22.04-kfocus \
    linux-tools-generic-hwe-22.04-kfocus; then
    _install_attempts=$((_install_attempts + 1));
    continue;
  fi

  if ! DEBIAN_FRONTEND=noninteractive apt-get -y autopurge; then
    _install_attempts=$((_install_attempts + 1));
    continue;
  fi

  _install_success='yes';
done

if [ "${_install_success}" = 'no' ]; then
  exit 1;
fi
