# kfocus-suite-manager

Installs KFocus enhancements on supported versions of Kubuntu LTS.

## Overview

The `kfocus-suite-manager` app can be used to add or remove the Kubuntu Focus
Suite of tools and enhancements to a stock Kubuntu 22.04 LTS systems.
It adds repositories and installs packages to provide the following benefits:

* Automatic delivery of enhancements and bug fixes with normal software
  upgrades.
* Curated kernel that can mitigate hardware issues
* Focus theming and widgets, including the famous Quick Hint widget
* A collection of handy tools including ... (get full list from website)
* Curated apps which are installable with a single click (website)
* Guided solutions available with a single click
* Feature guide ...

If the user elects to uninstall the Suite, all repos and packages previously 
installed are retained, while those added exclusively during the addition of
the suite are removed.

## Debugging

1. Install stock kubuntu in VM
2. Store list of packages in a file
   apt list --installed > pre-kfs.txt
3. Install KFS
   apt list --installed > with-kfs.txt
4. Remove KFS
   apt list --installed > post-kfs.txt

The diff the files to confirm desired behavior.


## Development Ideas

- Provide the Overview details above on demand from the manager
  (e.g. if the user asks for more detail)
- Read the stat BEFORE presenting the first actionable window. For example, 
  if the suite is already installed, offer to remove it. Otherwise, offer to
  add it.
- Consider using QML, Xuu, and very small system calls. For example, use
  `_echoPkgRecDepsFn` to get the package recommends and dependency lists, but
  after that, run everything through JS. One might even use JS for 
  the filtering from the native apt-cache depends call.
  


## Definitions

KFS = Kubuntu Focus Suite.
The 'Manager' allows users to 'Add' or 'Remove' the KFS.
DO NOT use other terms. Examples to avoid:

- *Install* KFS (NO, use ADD)
- *Purge* or *Uninstall* or *Delete* KFS (NO, use REMOVE)
- Others?


