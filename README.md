# Kubuntu Focus Source
All files are governed by the licenses described in their headers. If no
license is described and the file has been created by the kfocus team, the
file is governed by the GPLv2. See COPYING for further details. Pull requests
are welcome!

## Purpose
This is the source for the Kubuntu Focus Suite of tools, curated apps, UX
preferences, and hardware optimizations that work in harmony with standard
Kubuntu 24.04 LTS. It is carefully designed to avoid reinventing the wheel and
does not, for example, contain a variation of an entire operating system, or a
shell on top of it. Many enhancements that started in this repository have
since been contributed and accepted upstream. This adds unique value to an
already vibrant and broadly supported ecosystem and community.

## Branches and Tags
Any and all development and changes go into a branch labeled `NN-{YYYY}-{MM}`
which is then merged into the code-name branch, noble. When released to the
public, tags are applied in the following format, where x is the numerical
release order:

```
# Tag Format
<name>/24.04.{x}

# Package directories
package-<name>

# Full Package Names
kfocus-<name>
```

## Source Package Table

All these are source packages. Many create multiple binary packages.

| Name                 |
| -------------------- |
| apt-source           |
| calamares-settings   |
| firstrun-bin         |
| hw                   |
| installer-prompt     |
| jetbrains-toolbox    |
| linux-meta           |
| main                 |
| nvidia               |
| power-bin            |
| qwe                  |
| rollback             |
| settings             |
| tools                |
| wallpapers           |

As of 24.04, the following packages are deprecated:
```
001-*     # 22.04 packages renamed above
cuda-lib  # Replaced kfocus kfocus-conda tool
rest      # Restricted packages, now offerred in kfocus-extra.
```

## Build and Distribution
Packages are built using standard PPA preparation and uploaded to the [Kubuntu
Focus PPA repository][_0100]. The following packages are built using unique
methods:

`package-linux-meta` contains the metapackage for our latest supported kernel.
This is merged from the corresponding source package as published by
Canonical. The version in the latest development branch is most up-to-date and
is likely to be the version currently in use.

## Dependencies
In general, avoid `Predepends` in packages and avoid changing any dependencies.
If you DO change a dependency, make sure one can install the full suite on top
of stock Kubuntu. For a full, pre-built ISO, see the [Kubuntu Focus
Suite](https://kfocus.org/try) OEM image.

## Contributing
Contributions and pull requests are welcome. See CONTRIBUTING.md for code
standards and quality checks.

## END
