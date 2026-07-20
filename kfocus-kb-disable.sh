# This branch has all controls disabled.
# Do these steps to apply to your running system.
sudo systemctl disable --now kfocus-kb-save
git diff --name-only RR-2026-Q3 \
  |grep kfocus/bin \
  | while read _file; do
  _basename="$(basename "${_file}")";
  meld "${_file}" \
    "/usr/lib/kfocus/bin/${_basename}";
done
