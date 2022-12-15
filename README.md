# Kubuntu Focus Source
All files are governed by the licenses described in their headers. If no license is described, the file is governed by the GPL-2, or (at your option) any later version. See COPYING for further details. Pull requests are welcome!

## Purpose
This is the source for the Kubuntu Focus Suite of tools, curated apps, UX preferences, and hardware optimizations that work in harmony with standard Kubuntu 22.04 LTS. It is carefully designed to avoid reinventing the wheel and does not, for example, contain a variation of an entire operating system, or a shell on top of it. Many enhancements that started in this repository have since been contributed and accepted upstream. This adds unique value to an already vibrant and broadly supported ecosystem and community.

## Development
Any and all development and changes go into a branch labeled `JJ-{YYYY}-{MM}` which is then merged into the default (currently jammy) branch.  When released to the public, tags will be made in the following format:

```
{main|rest|apt-source|cuda-libs|hw|main|nvidia|settings|tools|wallpapers}/22.04.{x}
```

Where x is the numerical release order.

When built, the packages are uploaded to the Kubuntu Focus repository, a PPA at https://launchpad.net/~kfocus-team/+archive/ubuntu/release.

Packages are built normally in this fashion except for the following packages:

`package-linux-meta` contains the metapackage for our latest supported kernel. This is merged from the corresponding source package as published by Canonical. The version in the latest development branch is most up-to-date and is likely to be the version currently in use.

`package-qwe` contains the latest qwe source. As it is a hybrid upstream and kubuntu focus project, it is treated as an upstream project. Tarballs are generated separately but packaged here using the .source file as the only source.
