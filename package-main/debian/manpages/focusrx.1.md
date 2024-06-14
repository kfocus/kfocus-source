% FOCUSRX(1) focusrx 24.04
% Michael Mikowski, Erich Eickmeyer, Aaron Rainbolt
% June 2024

# NAME
focusrx - Runs system checks on login

# SYNOPSIS
**focusrx** [-f|-h]

# DESCRIPTION
FocusRx is an all-in-one system integrity checker and maintenance tool. It
runs on user login, checking for (and offering fixes for) a large number of
common system issues, including but not limited to:

* Out-of-date BIOS
* Improperly set-up hardware
* NVIDIA driver issues
* Conflicts between IBus and Plasma
* Too many old kernels installed

Additionally, it helps with system maintenance tasks, for instance ensuring
that setup requirements for apps such as BackInTime are met properly.

# OPTIONS

-f 
: Enables fixup mode. Maintenance features that are not usually offered are
offered interactively.

-h
: Displays help.
