#!/bin/bash
_rx_dir='/var/lib/kfocus';
_repo_dir='/etc/apt/sources.list.d';
source lib/kfocus-packagetree.source

_uninstall_success='no';
_uninstall_attempts=0;
  
_foundPkgList=( 'kfocus-main' );
_preInstallPkgStr="$(cat "${_rx_dir}/pre-install-pkgs.list";)" || exit 1;
_loadKfPkgListFn;
_pre_install_repo_str="$(cat "${_rx_dir}/pre-install-repos.list")";

while [ "${_uninstall_success}" = 'no' ] && [ "${_uninstall_attempts}" != '3' ]; do
  if ! apt-get -y install linux-generic-hwe-22.04 \
    linux-headers-generic-hwe-22.04 \
    linux-image-generic-hwe-22.04 \
    linux-tools-generic-hwe-22.04; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi
  
  if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o kfocus-team -p release; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  if ! [[ "${_pre_install_repo_str}" =~ 'o=LP-PPA-bit-team-stable' ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o bit-team -p stable; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    fi
  fi

  if ! [[ "${_pre_install_repo_str}" =~ 'o=LP-PPA-kubuntu-ppa-backports' ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o kubuntu-ppa -p backports; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    fi
  fi

  if ! [[ "${_pre_install_repo_str}" =~ 'o=LP-PPA-kubuntu-ppa-backports-extra' ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o kubuntu-ppa -p backports-extra; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    fi
  fi
  
  if ! [[ "${_pre_install_repo_str}" =~ 'o=LP-PPA-phoerious-keepassxc' ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o phoerious -p keepassxc; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    fi
  fi

  if ! [[ "${_pre_install_repo_str}" =~ 'o=LP-PPA-ubuntustudio-ppa-backports' ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o ubuntustudio-ppa -p backports; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    fi
  fi

  if ! [[ "${_pre_install_repo_str}" =~ 'o=NVIDIA,l=NVIDIA CUDA' ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -s developer.download.nvidia.com -o compute -p cuda; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    fi
  fi

  # TODO: Perhaps tighten up this check
  if ! [[ "${_pre_install_repo_str}" =~ 'o=Google LLC' ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -s dl.google.com -o linux -p chrome; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    fi
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
done

if [ "${_uninstall_success}" = "no" ]; then
  exit 1;
fi
