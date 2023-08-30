#!/bin/bash

echo 'This script checks if the assets listed in qml.qrc '
echo 'to ensure they are in main.qml. '
echo
echo 'This must be run in its own dirctory to work.'
echo
echo 'There are currently 4 _light and _dark images that are themed, '
echo 'so these will be shown as false negatives.'
echo
_check_str="$(
  grep -E '^\s*<file>assets/images/' ./qml.qrc \
    | sed 's?^\s*<file>assets/images/??g' \
    | sed 's?<.*$??g'
)";

while read _str; do
  if grep -q "${_str}" ./main.qml; then
    echo "  ok: ${_str} found in main.qml";
  else
    echo "FAIL: ${_str} NOT found in main.qml";
  fi
done <<<"${_check_str}"

echo
echo 'Now to check the files in assets/images.'
echo 'This will highlight any that are NOT in qml.qrc.'
echo
read;

while read _file; do
  _str="$(basename "${_file}")";
  if grep -q "${_str}" <<< "${_check_str}"; then
    echo "  ok: ${_file} found in qml.qrc";
  else
    echo "FAIL: ${_file} NOT found in qml.qrc";
  fi
done < <(find ./assets/images/ -mindepth 1 -maxdepth 1 -type f)

