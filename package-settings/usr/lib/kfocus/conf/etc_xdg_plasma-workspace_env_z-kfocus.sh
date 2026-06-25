# Added a path to put KFocus Settings
# We kept the “kf5-settings” directory name instead of renaming to
# “kf6-settings” for consistency with upstream, and to allow upgrades to
# function.
XDG_CONFIG_DIRS="/usr/share/kfocus/kf5-settings:$XDG_CONFIG_DIRS"
