% KFOCUS-KCLEAN(1) kfocus-kclean 24.04
% Michael Mikowski, Erich Eickmeyer, Aaron Rainbolt
% June 2024

# NAME
kfocus-kclean - Detect and uninstall unused/excessive Linux kernels

# SYNOPSIS
**/usr/lib/kfocus/bin/kfocus-kclean** [-f|-h]

# DESCRIPTION
kfocus-kclean helps with cleaning up unneeded Linux kernels. It detects when
space for kernels is getting low, determines which kernels are most likely to
be unused based on their type and version, and offers to uninstall those older
kernels. By default, kfocus-kclean will exit and do nothing if free boot space
is sufficient. It will only scan for and offer to remove kernels is space is
low.

# OPTIONS
-f
: Forces a full kernel scan. Kernels that can reasonably be purged are offered
for uninstallation even if they don't need to be removed yet. If no kernels
can reasonably be purged, a summary of installed kernel packages is shown
along with a message that no kernels are to be removed.

-h
: Displays help.
