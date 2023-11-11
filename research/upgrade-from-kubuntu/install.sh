#!/bin/bash
#
# Copyright 2023 MindShare Inc.
#
# Written for the Kubuntu Focus by M. Mikowski and A. Rainbolt.
#
# Name      : install.sh
# Summary   : install.sh -[i|c]
# Purpose   : Backend for kfocus-suite-manager that handles Kubuntu Focus Suite
#             installation related tasks.
# Example   : install.sh -i
# Arguments : -i: Install the suite. Must be run as root.
#             -c: Configure the current user account to use the suite. Must
#                 be run as the user being configured (NOT AS ROOT!).
# License   : GPLv2
# Run By    : kfocus-suite-manager
#
set -u;

## BEGIN _installSuiteFn {
_installSuiteFn () {
  declare _rx_dir _install_success _install_attempts;

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
  _install_attempts='0';
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
}
## . END _installSuiteFn }

## BEGIN _configureSuiteFn {
_configureSuiteFn () {
  # TODO: fill me in
}
## . END _configureSuiteFn }

## BEGIN _mainFn {
_mainFn () {
  declare _arg_str;

  _arg_str="${1:-}";
  case "${_arg_str}" in
    '-i') _installSuiteFn;;
    '-c') _configureSuiteFn;;
      '') _cm2ErrStrFn 'Flag required'; exit 1;;
  esac
}
## . END _mainFn }

declare _binName _binDir _baseDir _baseName;

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  _binName="$(  readlink -f "$0"       )" || exit 101;
  _binDir="$(   dirname  "${_binName}" )" || exit 101;
  _baseDir="$(  dirname  "${_binDir}"  )" || exit 101;
  _baseName="$( basename "${_binName}" )" || exit 101;

  _mainFn "$@";
fi
