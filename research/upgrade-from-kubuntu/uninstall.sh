#!/bin/bash
_uninstall_success="no";
_uninstall_attempts=0;


while [ "${_uninstall_success}" = "no" ] && [ "${_uninstall_attempts}" != "3" ]; do
  if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o kfocus-team -p release; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o bit-team -p stable; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  if ! DEBIAN_FRONTEND=noninteractive apt-get -y purge google-chrome-*; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o kubuntu-ppa -p backports; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o phoerious -p keepassxc; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o ubuntustudio-ppa -p backports; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  rm -f /etc/apt/sources.list.d/nvidia-cuda.list \
    /etc/apt/sources.list.d/nvidia-ml.list \
    /etc/apt/sources.list.d/nodesource.list \
    /etc/apt/sources.list.d/google-cloud-sdk.list \
    /etc/apt/sources.list.d/google-chrome.list;

  if ! apt-get -y install linux-generic-hwe-22.04 \
    linux-headers-generic-hwe-22.04 \
    linux-image-generic-hwe-22.04 \
    linux-tools-generic-hwe-22.04; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  if ! DEBIAN_FRONTEND=noninteractive apt-get -y autopurge; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  _uninstall_success="yes";
done

if [ "${_uninstall_success}" = "no" ]; then
  exit 1;
fi
