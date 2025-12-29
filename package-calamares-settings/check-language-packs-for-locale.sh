#!/bin/bash

# Checks which language pack packages exists for a given '$LOCALE'.

LOCALE="$1";

# List taken from
# https://git.launchpad.net/~ubuntu-qt-code/+git/calamares-settings-ubuntu/tree/kubuntu/modules/packages.conf
_pkg_list=(
  "language-pack-$LOCALE"
  "language-pack-gnome-$LOCALE"
  "language-pack-kde-$LOCALE"
  "hunspell-$LOCALE"
  "libreoffice-help-$LOCALE"
  "libreoffice-l10n-$LOCALE"
);

for _pkg in "${_pkg_list[@]}"; do
  if apt-cache show "${_pkg}" >/dev/null 2>&1; then
    echo "found  : ${_pkg}";
  else
    echo "MISSING: Package ${_pkg}";
  fi
done
