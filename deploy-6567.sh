#!/usr/bin/bash
# Steps to test deploy branch 6567_/RR-2026-Q3/_keyboard_led_fixes
set -eu;

declare _msg _path _sys_path;

if sudo systemctl enable --now kfocus-kb-save; then
  echo 'kfocus-kb-save enabled.';
else
  echo 'kfocus-kb-save NOT enabled.';
  echo 'PLEASE FIX!';
fi

_path='package-hw/usr/lib/kfocus/conf/usr_lib_systemd_system-sleep_zsleep-kfocus';
_sys_path='/usr/lib/systemd/system-sleep/zsleep-kfocus';
if diff -r --brief "${_path}" "${_sys_path}"; then
  echo 'Paths match, continuing';
else
  sudo meld "${_path}" "${_sys_path}";
fi

while read _path; do
  _sys_path="/${_path#*/}";
  if [ -r "${_path}" ] && [ -r "${_sys_path}" ]; then
    if diff -r --brief "${_path}" "${_sys_path}"; then
      echo 'Paths match, continuing';
    else
      sudo meld "${_path}" "${_sys_path}";
    fi
  fi
done < <(git diff --name-only RR-2026-Q3 |grep -v '^test' );

read -rp 'Press enter to re-run kfocus-reset-effects -d as root';
sudo kfocus-reset-effects -d /usr/share/kfocus/kf5-settings;

_path=package-settings/usr/share/kfocus/kf5-settings;
_sys_path="/${_path#*/}";
read -rp 'Press enter to compare kf5-settings dir';
sudo meld "${_path}" "/${_sys_path}";


