#!/bin/bash
#
# Copyright 2023 MindShare Inc.
#
# Written for the Kubuntu Focus by M. Mikowski and A. Rainbolt.
#
# Name      : uninstall.sh
# Summary   : uninstall.sh
# Purpose   : Backend for kfocus-suite-manager that handles Kubuntu Focus Suite
#             uninstallation related tasks.
# Example   : uninstall.sh
# Arguments : None, however the script does start a two-way communication with
#             the script that executed it. It will provide the name of a repo
#             and then read a string from stdin. If the string is 'y' it will
#             purge the repo it provided the name of, if the string is 'n' it
#             will preserve it.
# License   : GPLv2
# Run By    : kfocus-suite-manager
#
set -u

source lib/kfocus-packagetree.source

## BEGIN _handleBitRepoFn {
_handleBitRepoFn () {
  declare _arg_str;

  _arg_str="${1:-}";

  if [ "${_arg_str}" = 'y' ]; then
    if ! DEBIAN_FRONTEND=noninteractive \
      ppa-purge -y -o 'bit-team' -p 'stable'; then
      echo 'FAIL';
      exit 1;
    fi
  fi
}
## . END _handleBitRepoFn }

## BEGIN _handleKubuntuBackportsRepoFn {
_handleKubuntuBackportsExtraRepoFn () {
  declare _arg_str;

  _arg_str="${1:-}";

  if [ "${_arg_str}" = 'y' ]; then
    if ! DEBIAN_FRONTEND=noninteractive \
      ppa-purge -y -o 'kubuntu-ppa' -p 'backports-extra'; then
      echo 'FAIL';
      exit 1;
    fi
  fi
}
## . END _handleKubuntuBackportsRepoFn }

## BEGIN _handleKubuntuBackportsRepoFn {
_handleKubuntuBackportsRepoFn () {
  declare _arg_str;

  _arg_str="${1:-}";

  if [ "${_arg_str}" = 'y' ]; then
    if ! DEBIAN_FRONTEND=noninteractive \
      ppa-purge -y -o 'kubuntu-ppa' -p 'backports'; then
      echo 'FAIL';
      exit 1;
    fi
  fi
}
## . END _handleKubuntuBackportsRepoFn }

## BEGIN _handleKeepassRepoFn {
_handleKeepassRepoFn () {
  declare _arg_str;

  _arg_str="${1:-}";

  if [ "${_arg_str}" = 'y' ]; then
    if ! DEBIAN_FRONTEND=noninteractive \
      ppa-purge -y -o 'phoerious' -p 'keepassxc'; then
      echo 'FAIL';
      exit 1;
    fi
  fi
}
## . END _handleKeepassRepoFn

## BEGIN _handleUbuntuStudioBackportsRepoFn {
_handleUbuntuStudioBackportsRepoFn () {
  declare _arg_str;

  _arg_str="${1:-}";

  if [ "${_arg_str}" = 'y' ]; then
    if ! DEBIAN_FRONTEND=noninteractive \
      ppa-purge -y -o 'ubuntustudio-ppa' -p 'backports'; then
      echo 'FAIL';
      exit 1;
    fi
  fi
}
## . END _handleUbuntuStudioBackportsRepoFn }

## BEGIN _handleNvidiaCudaRepoFn {
_handleNvidiaCudaRepoFn () {
  declare _arg_str;

  _arg_str="${1:-}";

  if [ "${_arg_str}" = 'y' ]; then
    if ! DEBIAN_FRONTEND=noninteractive \
      ppa-purge -s 'developer.download.nvidia.com' -o 'compute' -p 'cuda'; then
      echo 'FAIL';
      exit 1;
    fi
  fi
}
## . END _handleNvidiaCudaRepoFn }

## BEGIN _handleGoogleChromeRepoFn {
_handleGoogleChromeRepoFn () {
  declare _arg_str;

  _arg_str="${1:-}";

  if [ "${_arg_str}" = 'y' ]; then
    if ! DEBIAN_FRONTEND=noninteractive \
      ppa-purge -s 'dl.google.com' -o 'linux' -p 'chrome'; then
      echo 'FAIL';
      exit 1;
    fi
  fi
}
## . END _handleGoogleChromeRepoFn }

## BEGIN _mainFn {
_mainFn () {
  declare _rx_dir _repo_dir _pre_install_repo_str _purge_str _input_str;

  # _foundPkgList and _preInstallPkgStr provided by kfocus-packagetree.source

  _rx_dir='/var/lib/kfocus';
  _repo_dir='/etc/apt/sources.list.d';

  _foundPkgList=( 'kfocus-main' );
  _preInstallPkgStr="$(cat "${_rx_dir}/pre-install-pkgs.list";)" || exit 1;
  _loadKfPkgListFn;

  _pre_install_repo_str="$(cat "${_rx_dir}/pre-install-repos.list")";

  if ! apt-get -y install linux-generic-hwe-22.04 \
    linux-headers-generic-hwe-22.04 \
    linux-image-generic-hwe-22.04 \
    linux-tools-generic-hwe-22.04; then
    echo 'FAIL';
    exit 1;
  fi
  
  if ! DEBIAN_FRONTEND=noninteractive \
    ppa-purge -y -o kfocus-team -p release; then
    echo 'FAIL';
    exit 1;
  fi

  if ! [[ "${_pre_install_repo_str}" =~ 'o=LP-PPA-bit-team-stable' ]]; then
    echo 'BackInTime';
    read _input_str;
    _handleBitRepoFn "${_input_str}";
  fi
  
  if ! [[ "${_pre_install_repo_str}" =~ 'o=LP-PPA-kubuntu-ppa-backports-extra' ]]; then
    echo 'kubuntu-backports-extra';
    read _input_str;
    _handleKubuntuBackportsExtraRepoFn "${_input_str}";
  fi

  if ! [[ "${_pre_install_repo_str}" =~ 'o=LP-PPA-kubuntu-ppa-backports' ]]; then
    echo 'kubuntu-backports';
    read _input_str;
    _handleKubuntuBackportsRepoFn "${_input_str}";
  fi
  
  if ! [[ "${_pre_install_repo_str}" =~ 'o=LP-PPA-phoerious-keepassxc' ]]; then
    echo 'keepassxc';
    read _input_str;
    _handleKeepassRepoFn "${_input_str}";
  fi

  if ! [[ "${_pre_install_repo_str}" =~ 'o=LP-PPA-ubuntustudio-ppa-backports' ]]; then
    echo 'ubuntustudio-backports';
    read _input_str;
    _handleUbuntuStudioBackportsRepoFn "${_input_str}";
  fi

  if ! [[ "${_pre_install_repo_str}" =~ 'o=NVIDIA,l=NVIDIA CUDA' ]]; then
    echo 'nvidia-cuda';
    read _input_str;
    _handleNvidiaCudaRepoFn "${_input_str}";
  fi

  # TODO: Perhaps tighten up this check
  if ! [[ "${_pre_install_repo_str}" =~ 'o=Google LLC' ]]; then
    echo 'google-chrome';
    read _input_str;
    _handleGoogleChromeRepoFn "${_input_str}";
  fi

  # TODO: These repos are REALLY HARD to remove with ppa-purge
  # if ! [[ "${_pre_install_repo_str}" =~ "nodesource.list" ]]; then
  #   rm -f "${_repo_dir}/nodesource.list";
  # fi
  # if ! [[ "${_pre_install_repo_str}" =~ "google-cloud-sdk.list" ]]; then
  #   rm -f "${_repo_dir}/google-cloud-sdk.list";
  # fi

  _purge_str="$(_echoPurgeListStrFn;)";

  if ! apt -y purge ${_purge_str}; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  if ! DEBIAN_FRONTEND=noninteractive apt-get -y autopurge; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  _uninstall_success="yes";

  if [ "${_uninstall_success}" = "no" ]; then
    exit 1;
  fi
}
## . END _mainFn }

declare _binName _binDir _baseDir _baseName;

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  _binName="$(  readlink -f "$0"       )" || exit 101;
  _binDir="$(   dirname  "${_binName}" )" || exit 101;
  _baseDir="$(  dirname  "${_binDir}"  )" || exit 101;
  _baseName="$( basename "${_binName}" )" || exit 101;

  _mainFn;
fi
