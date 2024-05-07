# Kubuntu Focus Source
All files are governed by the licenses described in their headers. If no
license is described and the file has been created by the kfocus team, the
file is governed by the GPLv2. See COPYING for further details. Pull requests
are welcome!

## Purpose
This is the source for the Kubuntu Focus Suite of tools, curated apps, UX
preferences, and hardware optimizations that work in harmony with standard
Kubuntu 22.04 LTS. It is carefully designed to avoid reinventing the wheel and
does not, for example, contain a variation of an entire operating system, or a
shell on top of it. Many enhancements that started in this repository have
since been contributed and accepted upstream. This adds unique value to an
already vibrant and broadly supported ecosystem and community.

## Branches and Tags
Any and all development and changes go into a branch labeled `JJ-{YYYY}-{MM}`
which is then merged into the code-name branch, jammy. When released to the
public, tags are applied in the following format, where x is the numerical
release order:

```
# Tag Format
<name>/22.04.{x}

# Full Package Names
kfocus-<name>
```

## Package Table

| Name         | Directory            | Full Package Name   |
| ------------ + -------------------- + ------------------- |
| apt-source   | package-apt-source   | kfocus-apt-source   |
| firstrun-bin | package-firstrun-bin | kfocus-firstrun-bin |
| hw           | package-hw           | kfocus-hw           |
| linux-meta   | package-linux-meta   | kfocus-linux-meta   |
| main         | package-main         | kfocus-main         |
| nvidia       | package-nvidia       | kfocus-nvidia       |
| power-bin    | package-power-bin    | kfocus-power-bin    |
| qwe          | package-qwe          | kfocus-qwe          |
| rest         | package-rest         | kfocus-rest         |
| settings     | package-settings     | kfocus-settings     |
| tools        | package-tools        | kfocus-tools        |
| wallpapers   | package-wallpapers   | kfocus-wallpapers   |

As of 22.04, the following packages are deprecated

```
kfocus-cuda-lib  # Replaced kfocus kfocus-conda tool
kfocus-001-*     # 20.04 packages renamed to above
```

## Build and Distribution
Packages are built using standard PPA preparation and uploaded to the [Kubuntu
Focus PPA repository][_0100]. The following packages are built using unique
methods:

`package-linux-meta` contains the metapackage for our latest supported kernel.
This is merged from the corresponding source package as published by
Canonical. The version in the latest development branch is most up-to-date and
is likely to be the version currently in use.

`package-qwe` contains the latest qwe source. As it is a hybrid upstream and
kubuntu focus project, it is treated as a kfocus project. See the README for
the associated other repos.

[_0100]:https://launchpad.net/~kfocus-team/+archive/ubuntu/release.

## Dependencies
In general, avoid `Predepends` in packages and avoid changing any dependencies.
If you DO change a dependency, make sure one can install the full suite on top
of stock kubuntu like so:

```bash
sudo -i 

_rx_dir='/var/lib/kfocus/';
mkdir -p "${_rx_dir}" || exit;
echo '1.3.0-0' > "${_rx_dir}/focusrx_version";

dpkg --add-architecture i386
add-apt-repository multiverse
add-apt-repository ppa:kfocus-team/release
apt install kfocus-apt-source

apt update
apt install kfocus-main
apt purge google-chrome-unstable
apt update
# Retry if this fails due to https timeouts from launchpad or others.
apt full-upgrade

# Proceed only on successful completion of above steps.
reboot

# Sign in as user and complete hardware configuration
```

## Contributing
Contributions and pull requests are welcome. See CONTRIBUTING.md for code
standards and quality checks.

## END
