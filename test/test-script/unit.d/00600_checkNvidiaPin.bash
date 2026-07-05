# Copyright 2019-2026 MindShare Inc.
# Unit test written for the Kubuntu Focus by
#   Michael Mikowski, Erich Eickmeyer, Aaron Rainbolt
#
# 00600_checkNividiaPin.bash: Check pinning of nvidia packages
#  Used by: package-apt-source for Nvidia package (#1605)
#
# This code is designed to be sourced and run by
#   the test harness, runUnitTests.
#   DO NOT run this directly as that may imperil the host system.
#
# + All _t00-prefixed variables are from _runUnitTests.
# + All _cm2-prefixed variables are from common.2.source
# + All package for used to override a test package should be clearly noted.
# + See other tests for example use of the Expect files.
#
# set -u is applied in _runUnitTests

# NOTE: cuda-drivers-${_nvDriverVers} appear deprecated for 595+ drivers
#
_echoExtraNvPkgsFn () {
  cat << EOL
cuda-drivers
kfocus-nvidia
kfocus-nvidia-edge
kfocus-nvidia-pinning
kfocus-nvidia-pinning-edge
libxnvctrl0
nvidia-driver-${_nvDriverSuffix}
nvidia-modprobe
nvidia-settings
EOL
}

_checkNvidiaPinFn () {
  declare _pkg_list _loop_pkg_name \
    _loop_policy_str _loop_mark_idx _loop_candi_str;

  # Create package inspection list
  IFS=$'\n' read -r -d '' -a _pkg_list < <(
    apt-cache depends "nvidia-driver-${_nvDriverSuffix}" \
    | awk '/Depends|Recommends/ {print $2}' \
    | sed 's/[<>]//g' \
    | cat - <(_echoExtraNvPkgsFn) \
    | sort -u
  );

  # Show all package version
  # shellcheck disable=SC2154
  dpkg-query -W "${_pkg_list[@]}" > "${_t00RunDir}/package-versions";

  # Empty accumulator files
  true > "${_t00RunDir}/package-policies";
  true > "${_t00RunDir}/package-candidates";

  # Show all policies applied
  for _loop_pkg_name in "${_pkg_list[@]}"; do
    _loop_policy_str="$(apt-cache policy "${_loop_pkg_name}")";

    # This replaces sed '/^\s*\*\*\*/q'; we wanted
    # to show 7 lines after the matching ***
    _loop_mark_idx="$(
      echo "${_loop_policy_str}" \
      | grep -m 1 -n '^\s*\*\*\*\s' \
      | cut -f1 -d':'
    )";
    if [ -z "${_loop_mark_idx:-}" ]; then
      _loop_mark_idx=0;
    fi

    if [ "${_loop_mark_idx}" -lt 5 ]; then
      _loop_mark_idx=5;
    fi
    (( _loop_mark_idx+=7 ));

    # Output to package-policies
    echo "${_loop_policy_str}" | head -n"${_loop_mark_idx}" \
      >> "${_t00RunDir}/package-policies";

    # Output short-form package-candidates
    _loop_candi_str="$(echo "${_loop_policy_str}" | grep 'Candidate')";
    echo "${_loop_pkg_name} ${_loop_candi_str}" \
      >> "${_t00RunDir}/package-candidates";
  done
}
## . END _checkNvidiaPinFn }

declare _nvDriverVers _nvDriverSuffix _expectDir;

## BEGIN _runTestFn {
_runTestFn () {
  declare _return_int _check_str ;
  _return_int=0;

  # Use function from test harness: clear out run dir and check expect dir
  if ! _t00ClearRunDirFn;    then return 1; fi
  if ! _t00CheckExpectDirFn; then return 1; fi
  if [ "$(_cm2EchoModelStrFn 'is_nv_sys')" != 'y' ]; then
    _cm2EchoFn 'OK  : Skipped, not an Nvidia system';
    return 0;
  fi

  ## TODO: This is a bit of a hack. Better to define the kfocus-nvidia package
  #   to expect (e.g. kfocus-nvidia-edge), then get the nvidia-driver package
  #   depended on, then parse out the version. Then if that changes, this
  #   will automatically update.
  #
  if [[ "$(_cm2EchoModelStrFn 'config_code')" =~ ^(m2g6|zrg1)$ ]]; then
    _nvDriverVers='595'; _nvDriverSuffix='595-open';
    _expectDir="${_t00ExpectDir}/edge";
  else
    _nvDriverVers='595'; _nvDriverSuffix='595';
    _expectDir="${_t00ExpectDir}/base";
  fi

  if [ ! -d "${_expectDir}" ]; then
    if ! mkdir -p "${_expectDir}"; then
      _cm2ErrStrFn "Could not make dir ${_expectDir}";
      return 1;
    fi
  fi

  _checkNvidiaPinFn;

  # shellcheck disable=SC2154
  _check_str="$(diff -r --brief "${_expectDir}" "${_t00RunDir}")";

  if [ -n "${_check_str}" ]; then
    _cm2EchoFn "FAIL: ${_check_str}";
    meld "${_expectDir}" "${_t00RunDir}";
    _return_int=1;
  else
    _cm2EchoFn 'OK  : Results match expected';
  fi
  return "${_return_int}";
}
## . END _runTestFn }
