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
#   * 98 - user cancel
#   *  0 - success
#
set -u;

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
  declare _banner_msg;
  _banner_msg="$( cat <<'_EOL01';
 _____                    ____
|  ___|__   ___ _   _ ___|  _ \ __  __
| |_ / _ \ / __| | | / __| |_| |\ \/ /
|  _| |_| | |__| |_| \__ \  _ <  >  <
|_|  \___/ \___|\__,_|___/_| \_\/_/\_\

GUIDED SYSTEM MAINTENANCE: PACKAGE CHECK
__upgrade_str__

FocusRx PACKAGE CHECK looks for common system issues by scanning
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
    | sed "s|__upgrade_str__|${_sysVersStr} => ${_tgtVersStr}|g"
  )";
  _cm2EchoFn "${_banner_msg}\n";
}
## . END _echoBannerFn }

## BEGIN _chkRepoInUseFn {
 # Summary  : _chkRepoInUseFn <search_rx>
 # Purpose  : Checks if a repo is *actually currently in-use*
 #            regardless if in /etc/apt/sources.list or .d
 # Example  : _chkRepoInUseFn 'graphics.tuxedocomputers.com'
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

## BEGIN _cm2ChkInstalledPkgFn {
 # Summary  : _cm2ChkInstalledPkgFn <package-name>;
 # Purpose  : Check to see if package is installed, quickly
 # Example  : _cm2ChkInstalledPkgFn kfocus-nvidia;
 # Returns  : 0 = package found; 1 = not found
 # Throws   : none
 #
_cm2ChkInstalledPkgFn () {
  declare _pkg_name _status_str;
  [ "$#" -gt 0 ] && _pkg_name="${1}" || return 1;
  _status_str="$(dpkg-query -f '${db:Status-abbrev}' -W "${_pkg_name}")";
  if echo "${_status_str}"| grep -vqE '^.i '; then
    return 1;
  fi
  return 0;
}
## . END _cm2ChkInstalledPkgFn }

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
    _status_str _prompt_str _ans_str;

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
    _prompt_str='Reinstall these (recommended)';

    _ans_str="$( _cm2ReadPromptYnFn "${_prompt_str}" 'y' )";
    if [ "${_ans_str}" = 'y' ]; then
      if ! apt-get install --reinstall "${_reinstall_list[@]}";
        then _return_int=1; fi

      # Mark these restored packages as auto, since they are recommended
      # by kfocus-main and are not used by anything else at present
      for _pkg_name in "${_reinstall_list[@]}"; do
        apt-mark auto "${_pkg_name}" || true;
      done
    else
      _cm2SucStrFn "${_adviceStr} Skip reinstall as directed by user";
    fi
  else
    _cm2SucStrFn "${_adviceStr} No packages to reinstall";
  fi
  return "${_return_int}"
}
## . END _reinstallRecommendsFn }

## BEGIN MAIN {
## Begin Initialize {
# Set _binDir and _baseDir
_binName="$(  readlink -f "$0"       )" || exit 101;
_baseName="$( basename "${_binName}" )" || exit 101;
_binDir="$(   dirname "$(dirname  "${_binName}")" )" || exit 101;
_baseDir="$(  dirname  "${_binDir}"  )" || exit 101;

_adviceStr='FocusRx Advice:';
_alertStr='FocusRx SAFE MODE:';

_sourceStr='';
_stepNum=1;
## . End Initialize }

## Begin Import Common {
 # Imports: _cm2Arg01 _cm2Arg02 _cm2AskExitFn _cm2ChkDupRunFn
 # _cm2ChkInstalledPkgFn _cm2EchoModelStrFn _cm2EchoFn _cm2InterruptFn
 # _cm2ReadPromptYnFn _cm2SetMsgFn _cm2SucFn _cm2SucStrFn _cm2WarnFn
 # _cm2WarnStrFn
 #
 # Run ls-common-symbols.sh to get this list
 #
_libFile="${_baseDir}/lib/common.2.source";
if [ -r "${_libFile}" ]; then
  # shellcheck source=../../lib/common.2.source
  source "${_libFile}" || exit 201;
else
  1>&2 echo "${_baseName}: ABORT - Cannot source lib |${_libFile}|";
  exit 201;
fi
## . End Import Common }

_isNvidiaSystem="$(_cm2EchoModelStrFn 'is_nv_sys')" || exit 202;
_modelLabel="$(    _cm2EchoModelStrFn 'label'    )" || exit 202;
if [ "${_modelLabel}" != 'generic' ]; then
  _modelLabel="Kubuntu Focus ${_modelLabel}";
fi

# Import distro info
# Example: DISTRIB_RELEASE=20.04  DISTRIB_CODENAME=focal
if [ -f '/etc/lsb-release' ]; then
  # shellcheck source=/etc/lsb-release
  source '/etc/lsb-release';
fi

## Begin Process Options {
while getopts ':ch' _opt_str; do
  case "${_opt_str}" in
    c ) echo "
<p>FocusRx PACKAGE-CHECK inspects libraries, configurations,<br>
and other settings to ensure this ${_modelLabel} system works<br>
properly.</p>";
        exit 0;;
    h ) _echoHelpFn; exit 0;;
    * ) _cm2EchoFn "\nInvalid option: -${OPTARG} \n";
        _echoHelpFn; exit 1;;
  esac
done
## . End Process Options }

_tgtVersStr="${_cm2Arg02:=1.2.1-3}";
_sysVersStr="${_cm2Arg01:=0.0.0-0}";
[ $# -gt 2 ] && _doSafe='y' || _doSafe='n';

# Trap interrupts in xterm exec env to prevent script crash message
trap _cm2InterruptFn SIGINT SIGTERM;

# Echo banner
_echoBannerFn;

if [ "${_doSafe}" = 'y' ]; then
  _cm2WarnStrFn "${_alertStr} No changes will be made.";
fi

read -rp 'Press <return> to continue or <ctrl-c> to cancel. ';
_cm2EchoFn;

_uidInt="$(id -u)" || exit 105;
if [ "${_uidInt}" != '0' ]; then
  _cm2AskExitFn 7 "Please run as root. Press <return> to exit.";
fi

# Reverse trap as this can cause problems (TODO: indicate how)
trap '' SIGINT SIGTERM;

# Prevent concurrent runs
# shellcheck disable=SC2119
_dupStr="$(_cm2ChkDupRunFn)";
if [ -n "${_dupStr}" ]; then
  _cm2WarnStrFn "${_baseName} is already running pid ${_dupStr}";
  _cm2AskExitFn 3;
fi

_stepName='Check disk space';
_nextStepFn "${_stepName}";
_cm2EchoFn "${_adviceStr} Please review the disk space. The system
disk, /, should have 5GB free, as should any separate
/home disk. If you see full disks, open another terminal
 and backup or remove files as needed to get more disk space.

The /boot partition (if it exists) should have at least
150MB free. If it does not, run the Focus Kernel Cleaner tool
to free up space.

";

df -h |head -n1;
df -h |grep -E ' /$| /home$| /boot$';
_cm2EchoFn;
_cm2SucFn;

_stepName='Repair packages';
if [ "${_doSafe}" = 'y' ]; then
  _cm2WarnStrFn "${_alertStr} Skip: ${_stepName}";
else
  _nextStepFn "${_stepName}";
  _cm2EchoFn 'The following steps will repair packages.
Please provide your user password when prompted.
';

  _doWarn='n';
  # See /usr/share/wajig/commands.py for source commands
  _cm2EchoFn 'Fix an interrupted install';
  # wajig fix-configure || _doWarn='y';
  /usr/bin/dpkg --configure --pending || _doWarn='y';

  _cm2EchoFn 'Fix an install interrupted by broken dependencies';
  # wajig fix-install   || _doWarn='y';
  /usr/bin/apt-get --fix-broken install || _doWarn='y';

  _cm2EchoFn 'Fix and install even though there are missing dependencies';
  # wajig fix-missing   || _doWarn='y';
  /usr/bin/apt-get --ignore-missing upgrade || _doWarn='y';

  if [ "${_doWarn}" = 'y' ]; then _cm2WarnFn; else _cm2SucFn; fi
fi

_stepName='Reinstall kfocus-apt-source, update, and full-upgrade';
if [ "${_doSafe}" = 'y' ]; then
  _cm2WarnStrFn "${_alertStr} Skip: ${_stepName}";
else
  _nextStepFn "${_stepName}";
  apt-get update || _cm2WarnFn;
  apt-get install --reinstall kfocus-apt-source || _cm2WarnFn;
  apt-get update || _cm2WarnFn;
  apt-get dist-upgrade || _cm2WarnFn;
  _cm2SucFn
fi

_doReboot='n';

# Reinstall drivers if nvidia system
if [ "${_isNvidiaSystem}" = 'y' ]; then
  _stepName='Ensure Nvidia drivers are installed'
  if [ "${_doSafe}" = 'y' ]; then
    _cm2WarnStrFn "${_alertStr} Skip ${_stepName}";
  else
    _nextStepFn "${_stepName}"
    if apt-get install --reinstall kfocus-nvidia; then
    _cm2SucFn; else _cm2WarnFn; fi
  fi

# Offer to uninstall drivers if NOT nvidia system
else
  _stepName='Remove kfocus-nvidia package';
  if _cm2ChkInstalledPkgFn 'kfocus-nvidia'; then
    if [ "${_doSafe}" = 'y' ]; then
      _cm2WarnStrFn "${_alertStr} Skip ${_stepName}";
    else
      _cm2EchoFn "Nvidia libs are not expected for this ${_modelLabel} system.";
      _prompt_str='Shall we remove them';
      _ans_str="$( _cm2ReadPromptYnFn "${_prompt_str}" 'n' )";
      if [ "${_ans_str}" = 'y' ]; then
        if apt-get purge kfocus-nvidia; then
          _cm2SucFn; else _cm2WarnFn; fi
        _doReboot='y';
      else
        _cm2SucFn;
      fi
    fi
  else
    _cm2SucStrFn 'kfocus-nvidia not installed';
  fi
fi

# Remove popular gfx repository
if (_chkRepoInUseFn 'ppa.launchpad.net/graphics-drivers/ppa/ubuntu'); then
  _stepName='Purge conflicting graphics ppa repository'
  if [ "${_doSafe}" = 'y' ]; then
    _cm2WarnStrFn "${_alertStr} Skip ${_stepName}";
  else
    _nextStepFn "${_stepName}";
    _prompt_str='Shall we remove this?';
    _ans_str="$( _cm2ReadPromptYnFn "${_prompt_str}" 'y' )";
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
_stepName='Reinstall recommended packages (you may remove later)'
if [ "${_doSafe}" = 'y' ]; then
  _cm2WarnStrFn "${_alertStr} Skip ${_stepName}";
else
  _nextStepFn "${_stepName}";
  if _reinstallRecommendsFn; then _cm2SucFn; else _cm2WarnFn; fi
fi

# Autoremove
_stepName='Auto remove unused packages'
if [ "${_doSafe}" = 'y' ]; then
  _cm2WarnStrFn "${_alertStr} Skip ${_stepName}";
else
  _nextStepFn "${_stepName}" \
    'It is normal to see dozens of old kernel or library packages here.';
  if apt-get autoremove; then _cm2SucFn; else _cm2WarnFn; fi
fi

# Initramdisk
_stepName="Update Initial RAM Disk";
if [ "${_doSafe}" = 'y' ]; then
  _cm2WarnStrFn "${_alertStr} Skip ${_stepName}";
else
  _nextStepFn "${_stepName}";
  _cm2EchoFn "${_adviceStr} This updates only the latest kernel version.";
  _cm2EchoFn "${_adviceStr} Do not be alarmed by missing i915 module warnings,";
  _cm2EchoFn "  THESE ARE NORMAL.\n";
  # Use -k all to update all initramfs (this can be dangerous as it can
  # propogate an issue to all kernels, so be careful!)
  if update-initramfs -u; then _cm2SucFn; else _cm2WarnFn; fi
fi

if [ "${_doSafe}" = 'y' ]; then
  _cm2WarnStrFn "${_alertStr} Exiting before any system changes";
  read -rp 'Press return to continue. ';
  exit 0;
fi

if [ "${_isNvidiaSystem}" = 'y' ]; then
  _primeExeStr=$(command -v 'prime-select');
  if [ "${_primeExeStr}" ]; then
    _primeQueryStr=$("${_primeExeStr}" query);
    if [ "${_primeQueryStr}" != 'nvidia' ]; then
      _nextStepFn 'Ensure Nvidia mode for next boot';
      if "${_primeExeStr}" 'nvidia'; then _cm2SucFn; else _cm2WarnFn; fi
    fi
  fi
fi

read -rp 'Press return to finish FocusRx Package Check. ';
if [ "${_doReboot}" = 'y' ]; then exit 99; fi
exit 0;
## . END MAIN }
