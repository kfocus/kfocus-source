# Copyright 2019-2026 MindShare Inc.
# Unit test written for the Kubuntu Focus by
#   Michael Mikowski, Erich Eickmeyer, Aaron Rainbolt
#
# 00000_rtestBase.bash: EXAMPLE unit test file
# https://www.leadingagile.com/2018/10/unit-testing-shell-scriptspart-one/
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

## BEGIN _overwriteWithMocksFn {
_overwriteWithMocksFn () {
  declare _exe_file;
  # Set special variable _rootDir which is used by executable
  # bashsupport disable=BP2001
  _rootDir="${_t00RunDir}";

  # Source executable; shellcheck disable=SC2154
  _exe_file="${_t00TopDir}";
  _exe_file+='/package-main/usr/lib/kfocus/bin/kfocus-example-app';
  # shellcheck disable=SC1090,SC2154
  source "${_exe_file}" || exit 1;

  # Mock executables or functions
  ls () { echo 'abc'; }
}
## . END _overwriteWithMocksFn }

## BEGIN _unsetMocksFn {
# Purpose : Unset mocked functions and other globals to prevent
#   pollution of namespaces. Mocked functions from commons.2.source are not
#   reset here; instead they are re-source after every test in runUnitTests
#   (the test harness). See more notes in 00900.
_unsetMocksFn () {
  unset ls;
}
## . END _unsetMocksFn }

## BEGIN _getAbcIfExistsFn {
# Purpose: Example of a system under test.
#
_getAbcIfExistsFn () {
  if grep -qE 'abc' <<< "$(ls)"; then
    echo 'abc';
  fi
}
## . END _getAbcIfExistsFn }

## BEGIN _runTestFn {
# This MUST be called '_runTestFn' for use by ./runUnitTests
_runTestFn () {
  declare _assert_table _assert_count _assert_idx _fail_count \
    _assert_line _bit_list _assert_id _assert_str _result_str _count_str;

  # Clear out run dir
  if ! _t00ClearRunDirFn;    then return 1; fi
  # Enable the next line if you're using an initial state directory
  # if ! _t00CopyInitDirFn;    then return 1; fi
  # Enable the next line if you're using an expect directory
  # if ! _t00CheckExpectDirFn; then return 1; fi

  # WE DO NOT NEED TO IMPORT COMMON FOR sourced scripts, as the common lib
  #   is already imported by _runUnitTests.
  # _importCommonFn;

  # Mock functions and variables as needed
  _overwriteWithMocksFn;

  _assert_table=(
    'test1|abc'
    # Place asserts here, they should be iterated through in a loop
    # Note that it may be worthwhile to use expect files for more complicated
    # test results
  );

  ## Begin Iterate through assertions {
  _assert_count="${#_assert_table[@]}";
  _assert_idx=1;
  _fail_count=0;

  for _assert_line in "${_assert_table[@]}"; do
    IFS='|' read -r -d '' -a _bit_list < <(echo -n "${_assert_line}");
    _assert_id="${_bit_list[0]}";
    _assert_str="${_bit_list[1]}";
    # Place bits from _bit_list into variables

    # Run system under test here and extract results
    _result_str="$(_getAbcIfExistsFn)";

    # shellcheck disable=SC2154
    _count_str="$(_t00MakeCountStrFn "${_assert_idx}" "${_assert_count}")";

    ## Begin Check results
    if [ "${_assert_str}" = "${_result_str}" ]; then
      _cm2EchoFn "  ok  : ${_count_str} ${_assert_id}";
    else
      _cm2EchoFn "  fail: ${_count_str} ${_assert_id}";
      _cm2EchoFn "    expected : ${_assert_str}";
      _cm2EchoFn "    got      : ${_result_str}";
      (( _fail_count++ ));
    fi
    ## . End Check diffs }
      (( _assert_idx++ ));
  done
  ## End Iterate through assertions }

  _unsetMocksFn;
  if [ "${_fail_count}" -gt 0 ]; then
    _cm2EchoFn "FAIL: ${_fail_count} of ${_assert_count} asserts failed.";
  else
    _cm2EchoFn 'OK  : Results match expected';
  fi

  return "${_fail_count}";
}
## . END _runTestFn }
