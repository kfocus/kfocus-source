# qwe
Command line bookmarks with autocomplete.

## Packaging Details

This the kfocus packaging of the `qwe` utility.
Upstream is git@github.com:kfocus/qwe.git 
which is a fork of git@github.com/olafurw/qwe.

## Overview
The original concept and code was provided by Ólafur Waage.
This was refactored and enhanced by Michael Mikowski.

`qwe` has been adopted as a standard CLI utility for Kubuntu Focus systems
and is available with the kfocus-qwe package from their ppa.

## Current Version
The current version is tested, stable, and has been marked as 1.0-0.

## Install
Add `qwe.source` to a folder and call `source qwe.source` or add `source
/your/favorite/folder/qwe.source` to a file like `.bashrc`. This was
previously named `qwe.sh`, so if you are upgrading, please adjust or use
the included symlink.

One can add qwe system-wide by adding a symlink from `qwe.source` to 
`/etc/bash_completion.d/qwe`.

## Usage Example
Change to the  `/home/username/my_project` directory and add the qwe 
tag `work`:

```bash
cd /home/username/my_project
qwe -a work
```

Return to the prior working directory and print the location:

```bash
qwe ~
pwd
```

Use qwe to return to the work tag. Type `qwe w<tab>` to autocomplete.
Then create a `build` subdirectory.

```bash
qwe work
mkdir -p  build
```

Again return to the prior working directory, print it, then return to the
build directory. Type `qwe w/<tab>/b<tab>` to see the full path:

```bash
qwe ~
pwd
qwe work/build
```

Actions that take a `<tag>[/path]` support tab completion.

## Help

Type `qwe -h` to get the help dialog:

```text
qwe Bookmarks: HELP
===================
qwe                 : Interactive select directory
qwe    <tag>[/path] : Change to directory identified by <tag>[/path]
qwe ~               : Change to user HOME directory
qwe -               : Change to last 'qwe' directory
qwe -a <tag>        : Add a <tag> pointing to current directory
qwe -d <tag>        : Delete <tag>
qwe -h or -?        : Show this help message
qwe -l              : Show sorted list of tags
qwe -p <tag>[/path] : Print the directory identified by <tag>[/path]
qwe -r <tag> <new>  : Rename <tag> with <new> name
qwe -s              : Show tag of current directory

Use <TAB> to autocomplete <tag>[/<path>].
```

## Other Notes

Type `qwe` alone to interactively select a directory.

Bookmarks are stored in a tab-delimited file called `/.qwe.data`.
The $HOME directory is parameterized so this file can be shared by
multiple users.

## END

