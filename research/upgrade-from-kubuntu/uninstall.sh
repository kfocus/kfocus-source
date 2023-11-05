#!/bin/bash
_uninstall_success="no";
_uninstall_attempts=0;

while [ "${_uninstall_success}" = "no" ] && [ "${_uninstall_attempts}" != "3" ]; do
  ppa-purge ppa:kfocus-team/release;
  if [ "$?" != "0" ]; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  apt-get -y install linux-generic-hwe-22.04 \
    linux-headers-generic-hwe-22.04 \
    linux-image-generic-hwe-22.04 \
    linux-tools-generic-hwe-22.04;
  if [ "$?" != "0" ]; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  apt-get -y autopurge;
  if [ "$?" != "0" ]; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  _uninstall_success="yes";
done

if [ "${_uninstall_success}" = "no" ]; then
  exit 1;
fi
