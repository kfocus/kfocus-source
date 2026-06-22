#!/bin/bash
#
# Copyright 2019-2026 MindShare Inc.
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
  declare _msg _sys_vers _tgt_vers;

  _sys_vers="${1:-}";
  _tgt_vers="${2:-}";

  _msg="$( cat <<'_EOL01';

FOCUSRX: PACKAGE-CHECK
__upgrade_str__

This script looks for common system issues by scanning files,
packages, and settings and offers to fix them.

As with any system maintenance, PLEASE BACK UP YOUR DATA BEFORE
PROCEEDING. You may exit this app to back up your data, and then
start it again using Start Menu > Kubuntu Focus > FocusRx.

When you are ready, make sure this system is connected to the
Internet and continue. The entire check can take 2-15 minutes
depending on the system state and connection speed.

Have questions? Write the support team at support@kfocus.org.
_EOL01
  )";

  # shellcheck disable=SC2001
  _msg="$(
    sed "s|__upgrade_str__|${_sys_vers} => ${_tgt_vers}|g" <<< "${_msg}"
  )";
  _cm2EchoFn "${_msg}\n";
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
  _ans_str="$( _cm2ReadPromptYnFn 'Continue' 'y' )";
  if [ "${_ans_str}" = 'n' ]; then
    _cm2InterruptFn;
  fi
  ((_stepNum++));
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
    _status_str _msg _ans_str;

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
    _msg='Reinstall these (recommended)';

    _ans_str="$( _cm2ReadPromptYnFn "${_msg}" 'y' )";
    if [ "${_ans_str}" = 'y' ]; then
      if ! apt-get reinstall "${_reinstall_list[@]}";
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
  ## TODO 2026-05-08: No edge drivers in 26.04 yet
  # if [ "${_config_code}" = 'm2g6' ]; then
  #   _nv_pkg_suffix='-edge';
  # elif [ "${_nv_series_str}" = 'rtx50' ]; then
  #   _nv_pkg_suffix='-edge';
  # fi

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

## BEGIN _printDiskReportLineFn {
_printDiskReportLineFn () {
  declare _mount_str _size_int _space_int _unalloc_pct_num _alert_pct_num \
    _crit_pct_num _pretty_size_num _pretty_space_num _status_str _printf_str;

  _mount_str="${1:-}";
  _size_int="${2:-}";
  _space_int="${3:-}";
  _unalloc_pct_num="${4:-}";
  _alert_pct_num="${5:-}";
  _crit_pct_num="${6:-}";
  _printf_str="${7:-}";

  _pretty_size_num="$(
    bc <<< "scale=2; ${_size_int} / 1024 / 1024 / 1024"
  )";
  _pretty_space_num="$(
    bc <<< "scale=2; ${_space_int} / 1024 / 1024 / 1024"
  )";
  if [ "$(bc <<< "${_unalloc_pct_num} < ${_crit_pct_num}")" = '1' ]; then
    _status_str="$(printf 'CRIT < %2.2f%%' "${_crit_pct_num}")";
  elif [ "$(bc <<< "${_unalloc_pct_num} < ${_alert_pct_num}")" = '1' ]; then
    _status_str="$(printf 'ALERT < %2.2f%%' "${_alert_pct_num}")";
  else
    _status_str="$(printf 'Good > %2.2f%%' "${_alert_pct_num}")";
  fi

  # shellcheck disable=SC2059
  printf "${_printf_str}"  \
    "${_mount_str}"        \
    "${_pretty_size_num}"  \
    "${_pretty_space_num}" \
    "${_unalloc_pct_num}"  \
    "${_status_str}";
}
## . END _printDiskReportLineFn }

## BEGIN _echoDiskCritAdviceFn {
_echoDiskCritAdviceFn () {
  declare _mount_str _fs_type _unalloc_pct_num _crit_pct_num _list \
  _crit_str _unalloc_str _msg;

  _mount_str="${1:-}";
  _fs_type="${2:-}";
  _unalloc_pct_num="${3:-}";
  _crit_pct_num="${4:-}";
  _list=();

  _crit_str="$(printf '%2.2f%%' "${_crit_pct_num}")";
  _unalloc_str="$(printf '%2.2f%%' "${_unalloc_pct_num}")";

  _msg="Available (${_unalloc_str}) < CRIT threshold (${_crit_str}).\n";
  case "${1:0}" in
    '/')
      _list+=('Root (/) disk space is critically low.');
      _list+=("${_msg}");
      _list+=('This can prevent the system from booting or app issues.');
      _list+=('  * Compress or remove log file found in /var/log.');
      _list+=('  * Compress databases & VMs, or move to another filesystem.');
      if [ "${_fs_type}" = 'btrfs' ]; then
        _list+=('  * Use Start Menu > Kubuntu Focus Tools > System Rollback');
        _list+=('    then [ Show Snapshot Sizes ], to find snapshots that');
        _list+=('    use root (/) disk space and delete them if possible.');
      fi
    ;;
    '/boot')
      _list+=('Boot (/boot) disk space is critically low.');
      _list+=("${_msg}");
      _list+=('This can prevent the system from booting.');
      _list+=('  * Use Start Menu > Kubuntu Focus Tools > Kernel Cleaner');
      _list+=('    to identify and remove old kernels.');
      _list+=('  * Remove old kernels using the package manager.');
      _list+=('    Remember to autoremove old packages to free up space.');
      if [ "${_fs_type}" = 'btrfs' ]; then
        _list+=('  * Use Start Menu > Kubuntu Focus Tools > System Rollback');
        _list+=('    then [ Show Snapshot Sizes ], to find snapshots that');
        _list+=('    use /boot disk space and delete them if possible.');
      fi
    ;;
    '/home')
      _list+=('Home (/home) disk space is critically low');
      _list+=("${_msg}");
      _list+=('This can prevent apps opening or the ability to save files.');
      _list+=('  * Delete unused files or local app data stored on /home.');
      _list+=('    For example, large ML models or Steam games.');
      _list+=('  * Use Dolphin to empty the Trash');
   ;;
  esac
  IFS=$'\n'; echo "${_list[*]}";
}
## . END _echoDiskCritAdviceFn }

## BEGIN _displayDiskReportFn {
_displayDiskReportFn () {
  declare _mount_list _crit_pct_list _fs_type_list _alert_pct_list  \
    _size_list _space_list _unalloc_pct_list _mount_str _fs_type  \
    _btrfs_report_str _size_int _space_int _calc_str _unalloc_int \
    _crit_int _df_report_str _unalloc_pct_num _alert_pct_num _crit_pct_num \
    _disk_advice_list _idx _was_ext4_head_printed _was_btrfs_head_printed;

  _mount_list=( '/' '/home' '/boot' );
  _crit_pct_list=();
  _fs_type_list=();
  _alert_pct_list=();
  _size_list=();
  _space_list=();
  _unalloc_pct_list=();

  for _mount_str in "${_mount_list[@]}"; do
    # Skip filesystems that are not a mount point
    if ! mountpoint -q "${_mount_str}"; then
      _alert_pct_list+=( '' );
      _crit_pct_list+=( '' );
      _fs_type_list+=( '' );
      _size_list+=( '' );
      _space_list+=( '' );
      _unalloc_pct_list+=( '' );
      continue;
    fi
    _fs_type="$(stat -f -c %T "${_mount_str}")";

    ## Begin Handle btrfs fs type
    if [ "${_fs_type}" = 'btrfs' ]; then
      _btrfs_report_str="$(
        btrfs filesystem usage -b "${_mount_str}" 2>/dev/null
      )";

      # Calc size, skip mount on error
      _size_int="$(
        awk '/Device size/{ print $3 }' <<< "${_btrfs_report_str}"
      )";
      _size_int="$(_cm2EchoIntFn "${_size_int}")";
      if (( _size_int == 0 )); then continue; fi

      # Calc space, skip mount on error
      _space_int="$(
        awk '/Free \(estimated\)/{ print $3 }' <<< "${_btrfs_report_str}"
      )";
      _space_int="$(_cm2EchoIntFn "${_space_int}")";
      if (( _space_int == 0 )); then continue; fi

      # Calc unalloc percent, skip mount on error
      _unalloc_int="$(
        awk '/Device unallocated/{ print $3 }' <<< "${_btrfs_report_str}"
      )";
      _unalloc_int="$(_cm2EchoIntFn "${_unalloc_int}")"
      if (( _unalloc_int == 0 )); then continue; fi
      _calc_str="scale=4; ( ${_unalloc_int} / ${_size_int} ) * 100";
      _unalloc_pct_num="$(bc <<< "${_calc_str}")";

      if [ "${_mount_str}" = '/boot' ]; then
        _crit_int="${_btrfsBootCritInt}"; # was 300 MiB
        _alert_pct_num="${_btrfsBootAlertPct}";
      else
        _crit_int="${_btrfsMainCritInt}"; # was 10 GiB
        _alert_pct_num="${_btrfsMainAlertPct}";
      fi
    ## . End Handle btrfs fs type

    ## Begin Handle other fs types
    else
      _df_report_str="$(df "${_mount_str}" | tail -n-1)";

      # Calc size, skip mount on error
      _size_int="$(awk '{ print $2 }' <<< "${_df_report_str}")";
      _size_int="$(_cm2EchoIntFn "${_size_int}")";
      if (( _size_int == 0 )); then continue; fi
      (( _size_int *= 1024 )) || true;

      # Calc space, skip mount on error
      _space_int="$(awk '{ print $4 }' <<< "${_df_report_str}")";
      _space_int="$(_cm2EchoIntFn "${_space_int}")";
      if (( _space_int == 0 )); then continue; fi
      (( _space_int *= 1024 )) || true;

      # Calc unalloc percent, skip mount on error
      (( _unalloc_int = _size_int - _space_int )) || true;
      _calc_str="scale=4; ( ${_unalloc_int} / ${_size_int} ) * 100";
      _unalloc_pct_num="$(bc <<< "${_calc_str}")";

      _alert_pct_num='';
      if [ "${_mount_str}" = '/boot' ]; then
        _crit_int="${_otherBootCritInt}"; # was 200 MiB
      else
        _crit_int="${_otherMainCritInt}"; # was 7.5 GiB
      fi
    fi
    ## End Handle other fs types

    # Calc critical low disk percentages for this mount
    _calc_str="scale=4; ( ${_crit_int} / ${_size_int} ) * 100";
    _crit_pct_num="$(bc <<< "${_calc_str}")";

    # Calc alert low disk percentages for this mount if not already set
    if [ -z "${_alert_pct_num}" ]; then
      _calc_str="scale=4; ( ${_crit_pct_num} * 3.3 )";
      _alert_pct_num="$(bc <<< "${_calc_str}")";
      [ "$(bc <<< "${_alert_pct_num} > 100")" = '1' ] \
       && _alert_pct_num='100.00';
    fi

    # Store calculated values in aligned lists for this mount
    _alert_pct_list+=(   "${_alert_pct_num}"   );
    _crit_pct_list+=(    "${_crit_pct_num}"    );
    _fs_type_list+=(     "${_fs_type}"         );
    _size_list+=(        "${_size_int}"        );
    _space_list+=(       "${_space_int}"       );
    _unalloc_pct_list+=( "${_unalloc_pct_num}" );
  done

  _disk_advice_list=();
  for _idx in "${!_mount_list[@]}"; do
    _calc_str="${_unalloc_pct_list[_idx]} < ${_crit_pct_list[_idx]}";
    if [ "$(bc <<< "${_calc_str}")" = '1' ]; then
      _disk_advice_list+=( "$(
         _echoDiskCritAdviceFn "${_mount_list[_idx]}" \
         "${_fs_type_list[_idx]}" "${_unalloc_pct_list[_idx]}" \
         "${_crit_pct_list[_idx]}"
      )");
    fi
  done

  _was_btrfs_head_printed='n'
  for _idx in "${!_mount_list[@]}"; do
    _fs_type="${_fs_type_list[_idx]}"
    if [ "${_fs_type}" != 'btrfs' ]; then
      continue;
    fi

    if [ "${_was_btrfs_head_printed}" = 'n' ]; then
      _cm2EchoFn 'BTRFS: Mount  Size (GiB)  Remain (GiB) Unalloc %  Status';
      _was_btrfs_head_printed='y';
    fi

    _printDiskReportLineFn "${_mount_list[_idx]}" "${_size_list[_idx]}" \
      "${_space_list[_idx]}" "${_unalloc_pct_list[_idx]}" \
      "${_alert_pct_list[_idx]}" "${_crit_pct_list[_idx]}" \
      '       %-5s  %10.2f  %12.2f %9.2f  %s\n';
  done

  _cm2EchoFn;

  _was_ext4_head_printed='n';
  for _idx in "${!_mount_list[@]}"; do
    _fs_type="${_fs_type_list[_idx]}"
    if [ "${_fs_type}" != 'ext2/ext3' ]; then
      continue
    fi

    if [ "${_was_ext4_head_printed}" = 'n' ]; then
      _cm2EchoFn ' EXT4: Mount  Size (GiB)  Remain (GiB)  Unused %  Status';
      _was_ext4_head_printed='y';
    fi

    _printDiskReportLineFn "${_mount_list[_idx]}" "${_size_list[_idx]}" \
      "${_space_list[_idx]}" "${_unalloc_pct_list[_idx]}" \
      "${_alert_pct_list[_idx]}" "${_crit_pct_list[_idx]}" \
      '       %-5s  %10.2f  %12.2f  %8.2f  %s\n';
  done

  if (( "${#_disk_advice_list[@]}" > 0 )); then
    for _msg in "${_disk_advice_list[@]}"; do
      _cm2EchoFn "\n${_msg}\n";
    done
    return 1;
  else
    _cm2SucStrFn 'Disk space appears fine.';
    return 0;
  fi
}
## . END _displayDiskReportFn }

## BEGIN _mainFn {
_mainFn () {
  declare _config_code _is_nv_system _model_code _model_label \
    _nv_series_str _option_key _dup_pid _step_name _installed_nv_list \
    _sys_vers _tgt_vers _do_safe _do_pkg_warn _do_advise_reboot \
    _msg _prime_query_key _prime_set_key;

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

  # Process options
  while getopts ':ch' _option_key; do
    case "${_option_key}" in
      c) echo "
  <p>FocusRx PACKAGE-CHECK inspects libraries, configurations,<br>
  and other settings to ensure this ${_model_label}<br>
  system works properly.</p>";
          exit 0;;
      h) _echoHelpFn; exit 0;;
      *) _cm2EchoFn "\nInvalid option: -${OPTARG} \n";
          _echoHelpFn; exit 1;;
    esac
  done

  # Process arguments
  _sys_vers="${_cm2Arg01:=0.0.0-0}";
  _tgt_vers="${_cm2Arg02:=1.2.1-3}";
  [ $# -gt 2 ] && _do_safe='y' || _do_safe='n';

  # Trap interrupts in xterm exec env to prevent script crash message
  trap _cm2InterruptFn SIGINT SIGTERM;

  # Echo banner and prompt user
  _echoBannerFn "${_sys_vers}" "${_tgt_vers}";
  if [ "${_do_safe}" = 'y' ]; then
    _cm2WarnStrFn "${_alertStr} No changes will be made.";
  fi
  read -rp 'Press [Enter] to continue or [CTRL][C] to cancel. ';
  _cm2EchoFn;

  # This must be done AFTER option checking, as option
  #   'c' must be available without root.
  #
  if [ "$(id -u)" != '0' ]; then
    _cm2AskExitFn 7 "Please run as root. Press [Enter] to exit.";
  fi

  # Revert interrupt handling to default
  # trap - SIGINT SIGTERM;

  # Prevent concurrent runs
  # shellcheck disable=SC2119
  _dup_pid="$(_cm2ChkDupRunFn)";
  if [ -n "${_dup_pid}" ]; then
    _cm2WarnStrFn "${_baseName} is already running pid ${_dup_pid}";
    _cm2AskExitFn 3;
  fi

  _step_name='Check disk space';
  _nextStepFn "${_step_name}";
  while ! _displayDiskReportFn; do
    _msg="${_adviceStr} or more disks are low on space.";
    _msg+='Increase free space as discussed above.';
    _msg+=$'\n';
    _msg='Rerun disk scan (No continues)';
    _ans_str="$( _cm2ReadPromptYnFn "${_msg}" 'y' )";
    if [ "${_ans_str}" = 'n' ]; then break; fi
    _cm2EchoFn '\n\n\n\n\nRE-SCAN DISKS\n=============';
  done
  _cm2SucFn;

  _step_name='Check package installation';
  if [ "${_do_safe}" = 'y' ]; then
    _cm2WarnStrFn "${_alertStr} Skip: ${_step_name}";
  else
    _nextStepFn "${_step_name}";
    _msg='The following steps will check and repair packages.\n';
    _msg+='Please provide your user password when prompted.';
    _cm2EchoFn "${_msg}";

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
    apt-get reinstall kfocus-apt-source || _cm2WarnFn;
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
         _cm2BlockMsg="${_step_name}"; # reset to original banner name
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
        _msg='Shall we remove them';
        _ans_str="$( _cm2ReadPromptYnFn "${_msg}" 'n' )";
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
      _msg='Shall we remove this?';
      _ans_str="$( _cm2ReadPromptYnFn "${_msg}" 'y' )";
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
  _adviceStr _alertStr _btrfsBootCritInt _btrfsMainCritInt \
  _otherBootCritInt _otherMainCritInt \
  _stepNum _lspciExe _primeExe;

_adviceStr='FocusRx Advice:';
_alertStr='FocusRx SAFE MODE:';

# Set unallocated thresholds
_btrfsBootAlertPct='25';          # Recommended alert for BTRFS
_btrfsBootCritInt='314572800';    # 300.0 MiB
_btrfsMainAlertPct='15';          # Recommended alert for BTRFS
_btrfsMainCritInt='10737418240';  # 10.00 GiB
_otherBootCritInt='209715200';    # 200.0 MiB
_otherMainCritInt='8053063680';   #  7.50 GiB
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
