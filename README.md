# Kubuntu Focus Source
All files are governed by the licenses described in their headers. If no
license is described and the file has been created by the kfocus team, the
file is governed by the GPLv2. See COPYING for further details. Pull requests
are welcome!

## Purpose
This is the source for the Kubuntu Focus Suite of tools, curated apps, UX preferences, and hardware optimizations that work in harmony with standard Kubuntu 22.04 LTS. It is carefully designed to avoid reinventing the wheel and does not, for example, contain a variation of an entire operating system, or a shell on top of it. Many enhancements that started in this repository have since been contributed and accepted upstream. This adds unique value to an already vibrant and broadly supported ecosystem and community.

## Branches and Tags
Any and all development and changes go into a branch labeled `JJ-{YYYY}-{MM}`
which is then merged into the code-name branch, jammy. When released to the
public, tags are applied in the following format, where x is the numerical
release order:

```
{main|rest|apt-source|cuda-libs|hw|main|nvidia|settings|tools|wallpapers}/22.04.{x}
```

## Build and Distribution
Packages are built using standard PPA preparation and uploaded to the [Kubuntu Focus PPA repository][_0100]. The following packages are built using unique methods:

`package-linux-meta` contains the metapackage for our latest supported kernel.
This is merged from the corresponding source package as published by
Canonical. The version in the latest development branch is most up-to-date and
is likely to be the version currently in use.

`package-qwe` contains the latest qwe source. As it is a hybrid upstream and
kubuntu focus project, it is treated as an upstream project. Tarballs are
generated separately but packaged here using the .source file as the only
source.

[_0100]:https://launchpad.net/~kfocus-team/+archive/ubuntu/release.

## Contributing
Contributions and pull requests are welcome. See CONTRIBUTING.md for code
standards and quality checks.

## END
