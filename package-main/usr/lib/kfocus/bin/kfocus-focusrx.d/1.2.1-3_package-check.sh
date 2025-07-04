#!/bin/bash
#
# Copyright 2019-2022 MindShare Inc.
# Written for the Kubuntu Focus by Michael Mikowski and Erich Eickmeyer
#
# Name      : 1.2.1-3_package-check.sh
# Purpose   : Provide common issues outside of package system
# License   : GPL v2
# Arguments : See _echoHelpFn
# Spec      : 744
# Exit codes:
#   * 99 - suggest reboot
#   *  0 - success
#
set -u;

## BEGIN _importCommonFn {
# Purpose: Import common library with _cm2* symbols
# Imports:
# Run ls-common-symbols.sh to get this list:
#   _cm2Arg01 _cm2Arg02 _cm2AskExitFn _cm2ChkDupRunFn
#   _cm2ChkInstalledPkgFn _cm2EchoModelStrFn _cm2EchoFn _cm2InterruptFn
#   _cm2ReadPromptYnFn _cm2SetMsgFn _cm2SucFn _cm2SucStrFn _cm2WarnFn
#   _cm2WarnStrFn
#
_importCommonFn() {
  declare _lib_file;
  _lib_file="${_topDir}/lib/common.2.source";
  if [ -r "${_lib_file}" ]; then
    # shellcheck source=../../lib/common.2.source
    source "${_lib_file}" || exit 202;
  else
    echo 1>&2 "${_baseName}: ABORT - Cannot source lib |${_lib_file}|";
    exit 202;
  fi
}
## . END _importCommonFn }

## BEGIN _echoHelpFn {
_echoHelpFn () {
  1>&2 cat <<_EOH
Usage: ${_baseName} [-c|-h]
  -c: Check if package check should run for this device. If it
      recommends a run, it echos an HTML paragraph describing its purpose.
  -h: Print this help message to STDERR

_EOH
}
## . END _echoHelpFn }

## BEGIN _echoBannerFn {
 # Requires _sysVersStr and _tgtVersStr
 #
_echoBannerFn () {
  declare _banner_msg _sys_vers _tgt_vers;

  _sys_vers="${1:-}";
  _tgt_vers="${2:-}";

  _banner_msg="$( cat <<'_EOL01';
 _____                    ____
|  ___|__   ___ _   _ ___|  _ \ __  __
| |_ / _ \ / __| | | / __| |_| |\ \/ /
|  _| |_| | |__| |_| \__ \  _ <  >  <
|_|  \___/ \___|\__,_|___/_| \_\/_/\_\

GUIDED SYSTEM MAINTENANCE: PACKAGE-CHECK
__upgrade_str__

FocusRx PACKAGE-CHECK looks for common system issues by scanning
files, packages, and settings. It then offers to fix and issues
it finds on your approval.

AS WITH ANY SYSTEM MAINTENANCE, PLEASE BACK UP YOUR DATA BEFORE
PROCEEDING. You may exit this app to back up your data, and then
start it again using Start Menu > Kubuntu Focus > FocusRx.

Please ensure system is connected to the Internet before proceeding.
The entire check can take 2-15 minutes depending on the system state
and connection speed.

Have questions? Write the support team at support@kfocus.org.
_EOL01
  )";

  # shellcheck disable=SC2001
  _banner_msg="$(echo "${_banner_msg}" \
    | sed "s|__upgrade_str__|${_sys_vers} => ${_tgt_vers}|g"
  )";
  _cm2EchoFn "${_banner_msg}\n";
}
## . END _echoBannerFn }

## BEGIN _chkRepoInUseFn {
 # Summary  : _chkRepoInUseFn <search_rx>
 # Purpose  : Checks if a repo is *actually currently in-use*
 #            regardless if in /etc/apt/sources.list or .d
 # Example  : _chkRepoInUseFn 'ppa.launchpad.net/graphics-drivers/ppa/ubuntu'
 # Stdout   : none
 # Returns  : 0 = repo found; >0 = repo not found
 # Throws   : none
 #
_chkRepoInUseFn () {
  declare _search_rx _apt_list_dir;
  _search_rx="$*";
  _apt_list_dir='/var/lib/apt/lists';
  # shellcheck disable=SC2010
  ls "${_apt_list_dir}" | grep -q --regexp="^${_search_rx}";
}
## . End _chkRepoInUseFn }

## BEGIN _nextStepFn {
_nextStepFn () {
  declare _this_msg _this_descr _step_msg _ans_str;

  _this_msg="${1:-Next}";
  _this_descr="${2:-}";
  _step_msg="${_stepNum}. ${_this_msg}";
  _cm2EchoFn;
  _cm2SetMsgFn "$_step_msg";
  if [ -n "${_this_descr}" ]; then
    _cm2EchoFn "${_this_descr}\n";
  fi
  ((_stepNum++));
  _ans_str="$( _cm2ReadPromptYnFn 'Continue' 'y' )";
  if [ "${_ans_str}" = 'n' ]; then
    _cm2InterruptFn;
  fi
  _cm2EchoFn "${_adviceStr} Please wait; this can take up to a minute...\n";
}
## . END _nextStepFn }

## BEGIN _reinstallRecommendsFn {
 # Summary   : _reinstallRecommendsFn;
 # Purpose   : Reinstall all kfocus-main recommended packages that
 #   have been removed and mark them auto install as opposed to manual.
 # Example   : As above
 # Arguments : none
 # Returns   : 0 on success, 1 on issue
 # Throws    : none
 #
_reinstallRecommendsFn () {
  declare _return_int _recommends_list _reinstall_list _pkg_name \
    _status_str _prompt_msg _ans_str;

  _return_int='0';

  # Get list of all recommended packages
  IFS=$'\n' read -r -d '' -a _recommends_list < <(
    apt-cache depends kfocus-main \
      | grep 'Recommends' | grep -v '<' | awk '{print $2}';
    printf '\0';
  );

  # Create reinstall list from above
  _reinstall_list=();
  for _pkg_name in "${_recommends_list[@]}"; do
    if grep -q '^kfocus-tools' <<< "${_pkg_name}"; then continue; fi
    _status_str="$(dpkg-query -f '${db:Status-abbrev}' -W "${_pkg_name}")";
    if echo "${_status_str}"| grep -vqE '^.i '; then
      _reinstall_list+=( "${_pkg_name}" );
    fi
  done

  # Reinstall now
  if [ "${#_reinstall_list[@]}" -gt 0 ]; then
    _cm2EchoFn "These recommended packages are not installed:"
    _cm2EchoFn "${_reinstall_list[*]}";
    _prompt_msg='Reinstall these (recommended)';

    _ans_str="$( _cm2ReadPromptYnFn "${_prompt_msg}" 'y' )";
    if [ "${_ans_str}" = 'y' ]; then
      if ! apt-get install --reinstall "${_reinstall_list[@]}";
        then _return_int=1; fi

      # Mark these restored packages as auto, since they are recommended
      # by kfocus-main and are not used by anything else at present
      for _pkg_name in "${_reinstall_list[@]}"; do
        apt-mark auto "${_pkg_name}" || true;
      done
    else
      _cm2SucStrFn "${_adviceStr} Skip reinstall per user request";
    fi
  else
    _cm2SucStrFn "${_adviceStr} No packages to reinstall";
  fi
  return "${_return_int}"
}
## . END _reinstallRecommendsFn }

## BEGIN _getNvSeriesStrFn {
# Purpose: Determine nvidia graphics card series
# IMPORTANT: This is a direct copy from kfocus-focusrx-set
#
_getNvSeriesStrFn () {
  declare _nv_line;
  if [ ! "${_lspciExe}" ]; then echo 'ERROR'; return 1; fi

  _nv_line=$("${_lspciExe}" |grep -i 'VGA compatible controller' |grep -i 'nvidia');
  if grep -q 'RTX 20' <<< "${_nv_line}"; then
    echo 'rtx20';
  elif grep -q 'RTX 30' <<< "${_nv_line}"; then
    echo 'rtx30';
  # GN21 = RTX 4090
  elif grep -qE '(RTX 40|GN21)' <<< "${_nv_line}"; then
    echo 'rtx40';
  elif grep -qE 'RTX 50' <<< "${_nv_line}"; then
    echo 'rtx50';
  else echo '';
  fi
}
## . END _getNvSeriesStrFn }

## BEGIN _installNvidiaFn {
# Purpose: Install kfocus nvidia packages.
#   The caller must determine if this step is appropriate.
# IMPORTANT: This is a direct copy from kfocus-focusrx-set
#
_installNvidiaFn () {
  declare _config_code _nv_series_str _nv_pkg_suffix;
  _config_code="${1:-}";
  _nv_series_str="${2:-}";

  _nv_pkg_suffix='';
  if [ "${_config_code}" = 'm2g6' ]; then
    _nv_pkg_suffix='-edge';
  elif [ "${_nv_series_str}" = 'rtx50' ]; then
    _nv_pkg_suffix='-edge';
  fi

  _cm2SetMsgFn 'Install NVIDIA Packages';
  if ! apt-get reinstall -y "kfocus-nvidia-pinning${_nv_pkg_suffix}"; then
    _cm2WarnStrFn "Trouble installing nvidia-pinning${_nv_pkg_suffix}.";
    _cm2WarnFn; return 1;
  fi
  if ! apt-get update; then
    _cm2WarnStrFn 'Trouble updating apt package list.';
    _cm2WarnFn; return 1;
  fi
  if ! apt-get reinstall -y "kfocus-nvidia${_nv_pkg_suffix}"; then
    _cm2WarnStrFn "Trouble installing kfocus-nvidia${_nv_pkg_suffix}.";
    _cm2WarnFn; return 1;
  fi
  _cm2SucFn;
}
## END _installNvidiaFn }

## BEGIN _echoInstalledNvPkgsFn {
_echoInstalledNvPkgsFn () {
  declare _name _suffix _pkg_name;
  for _name in kfocus-nvidia kfocus-nvidia-pinning; do
    for _suffix in '' '-edge'; do
      _pkg_name="${_name}${_suffix}";
      _cm2ChkInstalledPkgFn "${_pkg_name}" && echo "${_pkg_name}";
    done
  done
  # Include nvidia driver package as well
  2>/dev/null dpkg-query -f '${db:Status-abbrev} ${Package}\n' \
    -W 'nvidia-driver*' | grep '^.i' | awk '{print $2}';
}
## . END _echoInstalledNvPkgsFn }

## BEGIN _mainFn {
_mainFn () {
  declare _config_code _is_nv_system _model_code _model_label \
    _nv_series_str _option_key _dup_pid _step_name \
    _installed_nv_list _sys_vers _tgt_vers _do_safe \
    _disk_space_dir _fs_type _do_pkg_warn _do_advise_reboot \
    _prompt_msg _prime_query_key _prime_set_key;

  _config_code="$( _cm2EchoModelStrFn 'config_code')" || exit 202;
  _is_nv_system="$(_cm2EchoModelStrFn 'is_nv_sys'  )" || exit 202;
  _model_code="$(  _cm2EchoModelStrFn 'code'       )" || exit 202;
  _model_label="$( _cm2EchoModelStrFn 'label'      )" || exit 202;
  _nv_series_str="$( _getNvSeriesStrFn )";

  if [ "${_model_label}" != 'generic' ]; then
    _model_label="Kubuntu Focus ${_model_label}";
  fi

  # Supplemental check for NVIDIA systems
  if ! [ "${_is_nv_system}" = 'y' ]; then
    if [ -n "${_nv_series_str}" ]; then _is_nv_system='y'; fi
  fi

  # Import distro info
  # Example: DISTRIB_RELEASE=24.04  DISTRIB_CODENAME=noble
  if [ -f '/etc/lsb-release' ]; then
    # shellcheck source=/etc/lsb-release
    source '/etc/lsb-release';
  fi

  ## Begin Process Options {
  while getopts ':ch' _option_key; do
    case "${_option_key}" in
      c ) echo "
  <p>FocusRx PACKAGE-CHECK inspects libraries, configurations,<br>
  and other settings to ensure this ${_model_label}<br>
  system works properly.</p>";
          exit 0;;
      h ) _echoHelpFn; exit 0;;
      * ) _cm2EchoFn "\nInvalid option: -${OPTARG} \n";
          _echoHelpFn; exit 1;;
    esac
  done
  ## . End Process Options }

  _sys_vers="${_cm2Arg01:=0.0.0-0}";
  _tgt_vers="${_cm2Arg02:=1.2.1-3}";
  [ $# -gt 2 ] && _do_safe='y' || _do_safe='n';

  # Trap interrupts in xterm exec env to prevent script crash message
  trap _cm2InterruptFn SIGINT SIGTERM;

  # Echo banner
  _echoBannerFn "${_sys_vers}" "${_tgt_vers}";

  if [ "${_do_safe}" = 'y' ]; then
    _cm2WarnStrFn "${_alertStr} No changes will be made.";
  fi

  read -rp 'Press <return> to continue or <ctrl-c> to cancel. ';
  _cm2EchoFn;

  if [ "$(id -u)" != '0' ]; then
    _cm2AskExitFn 7 "Please run as root. Press <return> to exit.";
  fi

  # Reverse trap as this can cause problems (TODO: indicate how)
  trap '' SIGINT SIGTERM;

  # Prevent concurrent runs
  # shellcheck disable=SC2119
  _dup_pid="$(_cm2ChkDupRunFn)";
  if [ -n "${_dup_pid}" ]; then
    _cm2WarnStrFn "${_baseName} is already running pid ${_dup_pid}";
    _cm2AskExitFn 3;
  fi

  _step_name='Check disk space';
  _nextStepFn "${_step_name}";
  _cm2EchoFn "${_adviceStr} Please review the disk space. The system
  disk, /, should have 5GB free, as should any separate /home
  disk. If you see full disks, open another terminal and backup
  or remove files as needed to get more disk space.

  The /boot partition (if it exists) should have at least 150MB
  free. If it does not, run the Focus Kernel Cleaner tool to
  free up space.

  ";

  ## TODO: Check the for the user. This is horrible with BTRFS.
  for _disk_space_dir in '/' '/home' '/boot'; do
    if findmnt --mountpoint="${_disk_space_dir}"; then
      _fs_type="$(stat -f -c %T "${_disk_space_dir}")";
      if [ "${_fs_type}" = 'btrfs' ]; then
        btrfs 'filesystem' 'usage' "${_disk_space_dir}";
      else
        df -h "${_disk_space_dir}";
      fi
    fi
  done
  _cm2EchoFn;
  _cm2SucFn;

  _step_name='Repair packages';
  if [ "${_do_safe}" = 'y' ]; then
    _cm2WarnStrFn "${_alertStr} Skip: ${_step_name}";
  else
    _nextStepFn "${_step_name}";
    _cm2EchoFn 'The following steps will repair packages.
  Please provide your user password when prompted.
  ';

    _do_pkg_warn='n';
    # See /usr/share/wajig/commands.py for source commands
    _cm2EchoFn 'Fix an interrupted install';
    # wajig fix-configure || _doWarn='y';
    /usr/bin/dpkg --configure --pending || _do_pkg_warn='y';

    _cm2EchoFn 'Fix an install interrupted by broken dependencies';
    # wajig fix-install   || _doWarn='y';
    /usr/bin/apt-get --fix-broken install || _do_pkg_warn='y';

    _cm2EchoFn 'Fix and install even though there are missing dependencies';
    # wajig fix-missing   || _doWarn='y';
    /usr/bin/apt-get --ignore-missing upgrade || _do_pkg_warn='y';

    if [ "${_do_pkg_warn}" = 'y' ]; then _cm2WarnFn; else _cm2SucFn; fi
  fi

  _step_name='Reinstall kfocus-apt-source, update, and full-upgrade';
  if [ "${_do_safe}" = 'y' ]; then
    _cm2WarnStrFn "${_alertStr} Skip: ${_step_name}";
  else
    _nextStepFn "${_step_name}";
    apt-get update || _cm2WarnFn;
    apt-get install --reinstall kfocus-apt-source || _cm2WarnFn;
    apt-get update || _cm2WarnFn;
    apt-get dist-upgrade || _cm2WarnFn;
    _cm2SucFn;
  fi

  _do_advise_reboot='n';

  # Reinstall drivers if nvidia system
  if [ "${_is_nv_system}" = 'y' ]; then
    _step_name='Ensure NVIDIA drivers are installed';
    if [ "${_do_safe}" = 'y' ]; then
      _cm2WarnStrFn "${_alertStr} Skip ${_step_name}";
    else
      _nextStepFn "${_step_name}";
      if _installNvidiaFn "${_config_code}" "${_nv_series_str}"; then
         _cm2SucFn; else _cm2WarnFn;
      fi
    fi

  # Offer to uninstall drivers if NOT nvidia system
  else
    _step_name='Remove kfocus nvidia packages';
    _installed_nv_list=( $(_echoInstalledNvPkgsFn) );
    if (( "${#_installed_nv_list[@]}" > 0 )); then
      if [ "${_do_safe}" = 'y' ]; then
        _cm2WarnStrFn "${_alertStr} Skip ${_step_name}";
      else
        _nextStepFn "${_step_name}";
        _cm2EchoFn "NVIDIA libs are not expected for this ${_model_label} system:";
        _cm2EchoFn "${_installed_nv_list[*]}";
        _prompt_msg='Shall we remove them';
        _ans_str="$( _cm2ReadPromptYnFn "${_prompt_msg}" 'n' )";
        if [ "${_ans_str}" = 'y' ]; then
          if apt-get purge "${_installed_nv_list[@]}"; then
            _cm2SucFn; else _cm2WarnFn; fi
          _do_advise_reboot='y';
        else
          _cm2SucStrFn "Removing kfocus nvidia libs skipped per user request";
          _cm2SucFn;
        fi
      fi
    else
      _cm2SucStrFn 'kfocus-nvidia not installed';
    fi
  fi

  # Remove popular gfx repository
  if (_chkRepoInUseFn 'ppa.launchpad.net/graphics-drivers/ppa/ubuntu'); then
    _step_name='Purge conflicting graphics ppa repository'
    if [ "${_do_safe}" = 'y' ]; then
      _cm2WarnStrFn "${_alertStr} Skip ${_step_name}";
    else
      _nextStepFn "${_step_name}";
      _prompt_msg='Shall we remove this?';
      _ans_str="$( _cm2ReadPromptYnFn "${_prompt_msg}" 'y' )";
      if [ "${_ans_str}" = 'y' ]; then
        if ppa-purge graphics-drivers; then
          _cm2SucFn; else _cm2WarnFn;
        fi
      else
        _cm2SucFn
      fi
    fi
  fi

  # Reinstall
  _step_name='Reinstall recommended packages (you may remove later)'
  if [ "${_do_safe}" = 'y' ]; then
    _cm2WarnStrFn "${_alertStr} Skip ${_step_name}";
  else
    _nextStepFn "${_step_name}";
    if _reinstallRecommendsFn; then _cm2SucFn; else _cm2WarnFn; fi
  fi

  # Auto-remove unused packages
  _step_name='Auto-remove unused packages'
  if [ "${_do_safe}" = 'y' ]; then
    _cm2WarnStrFn "${_alertStr} Skip ${_step_name}";
  else
    _nextStepFn "${_step_name}" \
      'It is normal to see dozens of old kernel or library packages here.';
    if apt-get autoremove; then _cm2SucFn; else _cm2WarnFn; fi
  fi

  # Initial ramdisk
  _step_name="Update Initial RAM Disk";
  if [ "${_do_safe}" = 'y' ]; then
    _cm2WarnStrFn "${_alertStr} Skip ${_step_name}";
  else
    _nextStepFn "${_step_name}";
    _cm2EchoFn "${_adviceStr} This updates only the latest kernel version.";
    _cm2EchoFn "${_adviceStr} Do not be alarmed by missing i915 module warnings,";
    _cm2EchoFn "  THESE ARE NORMAL.\n";
    # Use -k all to update all initramfs (this can be dangerous as it can
    # propagate an issue to all kernels, so be careful!)
    if update-initramfs -u; then _cm2SucFn; else _cm2WarnFn; fi
  fi

  if [ "${_do_safe}" = 'y' ]; then
    _cm2WarnStrFn "${_alertStr} Exiting before any system changes";
    read -rp 'Press return to continue. ';
    exit 0;
  fi

  if [ -n "${_primeExe}" ]; then
    _prime_set_key='';
    _prime_query_key="$("${_primeExe}" query || true)";
    if [ "${_is_nv_system}" = 'n' ]; then
      if ! [ "${_prime_query_key}" = 'intel' ]; then
        _nextStepFn 'Ensure Intel mode for next boot';
        _prime_set_key='intel';
      fi
    else
      if ! [ "${_prime_query_key}" = 'nvidia' ]; then
        _nextStepFn 'Ensure NVIDIA mode for next boot';
        _prime_set_key='nvidia';
      fi
    fi

    # Set display mode to expected
    if [ -n "${_prime_set_key}" ]; then
      if "${_primeExe}" "${_prime_set_key}"; then
         _cm2SucFn; else _cm2WarnFn;
      fi
    fi
  fi

  read -rp 'Press return to finish FocusRx Package Check. ';
  if [ "${_do_advise_reboot}" = 'y' ]; then exit 99; fi
  exit 0;
}
## . END _mainFn }

## BEGIN Declare global variables {
declare _binName _binDir _baseDir _baseName _assignList \
  _adviceStr _alertStr _stepNum _lspciExe _primeExe \
  _do_safe;

_adviceStr='FocusRx Advice:';
_alertStr='FocusRx SAFE MODE:';
_stepNum=1;
## . END Declare global variables }

## BEGIN Run main if script is not sourced {
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  _binName="$(  readlink -f "$0"        )" || exit 101;
  _binDir="$(   dirname  "${_binName}"  )" || exit 101;
  _baseDir="$(  dirname  "${_binDir}"   )" || exit 101;
  _baseName="$( basename "${_binName}"  )" || exit 101;
  _topDir="$(   dirname  "${_baseDir}"  )" || exit 101;
  _importCommonFn;

  _assignList=(
    '_lspciExe|lspci||optional'
    '_primeExe|prime-select||optional'
  );
  if ! _cm2AssignExeVarsFn  "${_assignList[@]}"; then
    _cm2ErrStrFn 'Could not assign variable';
    exit 1;
  fi

  _mainFn "$@";
fi
## . END Run main if script is not sourced }

