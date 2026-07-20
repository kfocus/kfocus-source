# This branch has all controls disabled.
# Do these steps to apply to your running system.
if sudo systemctl disable --now kfocus-kb-save; then
  echo 'kfocus-kb-save disabled.';
else
  echo 'kfocus-kb-save NOT disabled.';
  echo 'PLEASE FIX!';
fi

sudo meld \
  package-hw/usr/lib/kfocus/conf/usr_lib_systemd_system-sleep_zsleep-kfocus \
  /usr/lib/systemd/system-sleep/zsleep-kfocus;

git diff --name-only RR-2026-Q3 \
  |grep kfocus/bin \
  | while read _file; do
  _basename="$(basename "${_file}")";
  sudo meld "${_file}" \
    "/usr/lib/kfocus/bin/${_basename}";
done
