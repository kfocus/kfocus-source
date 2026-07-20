# This branch has all controls disabled.
# Do these steps to apply to your running system.
if sudo systemctl enable --now kfocus-kb-save; then
  echo 'kfocus-kb-save enabled.';
else
  echo 'kfocus-kb-save NOT enabled.';
  echo 'PLEASE FIX!';
fi

sudo meld \
  package-hw/usr/lib/kfocus/conf/usr_lib_systemd_system-sleep_zsleep-kfocus \
  /usr/lib/systemd/system-sleep/zsleep-kfocus;

while read _path; do
  sudo meld "${_path}" "/${_path#*/}";
done < <(
  git diff --name-only RR-2026-Q3 | grep kfocus/bin;
  echo package-tools/usr/lib/kfocus/bin/kfocus-kb-color-set;
  echo package-settings/usr/share/kfocus/kf5-settings;
);
