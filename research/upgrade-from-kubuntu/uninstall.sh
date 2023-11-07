#!/bin/bash
_rx_dir="/var/lib/kfocus";
_repo_dir="/etc/apt/sources.list.d";
source lib/kfocus-packagetree.source

_uninstall_success="no";
_uninstall_attempts=0;
  
_foundPkgList=( "kfocus-main" );
_preInstallPkgStr="$(cat "${_rx_dir}/pre-install-pkgs.list";)" || exit 1;
_loadKfPkgListFn;
_purge_str="$(_echoPurgeListStrFn;)";
_pre_install_repo_str="$(cat ${_rx_dir}/pre-install-repos.list)";

while [ "${_uninstall_success}" = "no" ] && [ "${_uninstall_attempts}" != "3" ]; do
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
  else
    rm -f "${_repo_dir}/kfocus-team-ubuntu-release-jammy.list";
  fi

  if ! apt -y purge ${_purge_str}; then
    _uninstall_attempts=$((_uninstall_attempts + 1));
    continue;
  fi

  if ! [[ "${_pre_install_repo_str}" =~ "bit-team-ubuntu-stable-jammy.list" ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o bit-team -p stable; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    else
      rm -f "${_repo_dir}/bit-team-ubuntu-stable-jammy.list";
    fi
  fi
  
  if ! [[ "${_pre_install_repo_str}" =~ "kubuntu-ppa-ubuntu-backports-jammy.list" ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o kubuntu-ppa -p backports; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    else
      rm -f "${_repo_dir}/kubuntu-ppa-ubuntu-backports-jammy.list";
    fi
  fi
  
  if ! [[ "${_pre_install_repo_str}" =~ "kubuntu-ppa-ubuntu-backports-extra-jammy.list" ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o kubuntu-ppa -p backports-extra; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    else
      rm -f "${_repo_dir}/kubuntu-ppa-ubuntu-backports-extra-jammy.list";
    fi
  fi

  if ! [[ "${_pre_install_repo_str}" =~ "phoerious-ubuntu-keepassxc-jammy.list" ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o phoerious -p keepassxc; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    else
      rm -f "${_repo_dir}/phoerious-ubuntu-keepassxc-jammy.list";
    fi
  fi

  if ! [[ "${_pre_install_repo_str}" =~ "ubuntustudio-ppa-ubuntu-backports-jammy.list" ]]; then
    if ! DEBIAN_FRONTEND=noninteractive ppa-purge -y -o ubuntustudio-ppa -p backports; then
      _uninstall_attempts=$((_uninstall_attempts + 1));
      continue;
    else
      rm -f "${_repo_dir}/ubuntustudio-ppa-ubuntu-backports-jammy.list";
    fi
  fi

  if ! [[ "${_pre_install_repo_str}" =~ "nvidia-cuda.list" ]]; then
    rm -f "${_repo_dir}/nvidia-cuda.list";
  fi
  if ! [[ "${_pre_install_repo_str}" =~ "nvidia-ml.list" ]]; then
    rm -f "${_repo_dir}/nvidia-ml.list";
  fi
  if ! [[ "${_pre_install_repo_str}" =~ "nodesource.list" ]]; then
    rm -f "${_repo_dir}/nodesource.list";
  fi
  if ! [[ "${_pre_install_repo_str}" =~ "google-cloud-sdk.list" ]]; then
    rm -f "${_repo_dir}/google-cloud-sdk.list";
  fi
  if ! [[ "${_pre_install_repo_str}" =~ "google-chrome.list" ]]; then
    rm -f "${_repo_dir}/google-chrome.list";
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
