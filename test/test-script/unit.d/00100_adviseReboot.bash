# Copyright 2019-2026 MindShare Inc.
# Unit test written for the Kubuntu Focus by
#   Michael Mikowski, Erich Eickmeyer, Aaron Rainbolt
#
# 00100_adviseReboot.bash: Test advise reboot function
#
# This code is designed to be sourced and run by
#   the test harness, runUnitTests.
#   DO NOT this run directly as that may imperil the host system.
#
# + All _t00-prefixed variables are from _runUnitTests.
# + All _cm2-prefixed variables are from common.2.source
# + All package for used to override a test package should be clearly noted.
# + See other tests for example use of the Expect files.
#
# set -u is applied in _runUnitTests

# See https://askubuntu.com/questions/993570/
#   how-to-force-a-system-restart-is-needed-to-complete-the-update-process-message
_adviseRebootFn () {
  declare _lib_dir _update_dir _rbt_file _touch_file;
  _lib_dir="${_rootDir}/var/lib/update-notifier";
  _update_dir="${_lib_dir}/user.d";

  _touch_file="${_lib_dir}/dpkg-run-stamp";
  _rbt_file="${_rootDir}/var/run/reboot-required"

  _cm2SetMsgFn 'Advise reboot';

  if touch "${_rbt_file}"; then
    _cm2SucStrFn "Wrote ${_rbt_file}";
    _cm2SucFn; return;
  else
    _cm2WarnStrFn "Could not write ${_rbt_file}";
    _cm2WarnFn; return;
  fi

  if touch "${_touch_file}"; then
    _cm2SucStrFn "Touched ${_touch_file}";
    _cm2SucFn; return;
  else
    _cm2WarnStrFn "Could not touch ${_touch_file}";
    _cm2WarnFn; return;
  fi
}
## . END _adviseRebootFn }

## BEGIN _runTestFn {
_runTestFn () {
  declare _check_str _return_int;

  _return_int=0;

  # Use function from test harness: clear out run dir,
  #   copy init data dir, and check expect dir
  if ! _t00ClearRunDirFn;    then return 1; fi
  if ! _t00CopyInitDirFn;    then return 1; fi
  if ! _t00CheckExpectDirFn; then return 1; fi

  _rootDir="${_t00RunDir}";
  mkdir -p "${_rootDir}/var/run";
  _adviseRebootFn;

  _check_str="$( diff -r --brief "${_t00ExpectDir}" "${_t00RunDir}" )";

  if [ -n "${_check_str}" ]; then
    _cm2EchoFn ">> ${_check_str} <<"
    _return_int=1;
  fi

  return "${_return_int}";
}
## . END _runTestFn }
