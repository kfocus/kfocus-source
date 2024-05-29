% KFOCUS-EXTRA(1) kfocus-qwe 24.04
% Michael Mikowski
% May 2024

# NAME
kfocus-qwe - Command line bookmarks with autocomplete.

# SYNOPSIS
**qwe [OPTION] [TAG]**

# DESCRIPTION
This the kfocus packaging of the `qwe` utility. Upstream is
git@github.com:kfocus/qwe.git which is a fork of git@github.com/olafurw/qwe.

The original concept and code was provided by Ólafur Waage. This was
refactored and enhanced by Michael Mikowski.

`qwe` has been adopted as a standard CLI utility for Kubuntu Focus systems and
is available with the kfocus-qwe package from their ppa.

# EXAMPLES

## Add a tag
Change to the  `/home/username/my_project` directory and add the qwe
tag `work`:

```bash
cd /home/username/my_project
qwe -a work
```

## Return to prior directory
Return to the prior working directory and print the location:

```bash
qwe ~
pwd
```

## Change to a dir by tag
Return to the directory tagged as `word` and create a `build` subdirectory.

```bash
qwe work
mkdir -p  build
```

## Use tag with autocomplete
Return to the prior working directory, print it, then return to the
`build` directory. Type `qwe w/<tab>/b<tab>` to see the full path:

```bash
qwe ~
pwd
qwe work/build
```

Actions that take a `<tag>[/path]` support tab completion.

## Print a tag

```bash
qwe -p work
#> /home/johndoe/work
```

## Rename a tag

```bash
qwe -r work labor
```

## Show tag of current dir

```bash
cd ~/work
qwe -s
#> labor
```

## Delete a tag

```bash
qwe -d labor
```

## Help

Type `qwe -h` to get the help dialog:

```text
qwe Bookmarks: HELP
===================
qwe                 Interactive select directory
qwe    <tag>[/path] Change to directory identified by <tag>[/path]
qwe ~               Change to user HOME directory
qwe -               Change to last 'qwe' directory
qwe -a <tag>        Add a <tag> pointing to current directory
qwe -d <tag>        Delete <tag>
qwe -h or -?        Show this help message
qwe -l              Show sorted list of tags
qwe -p <tag>[/path] Print the directory identified by <tag>[/path]
qwe -r <tag> <new>  Rename <tag> with <new> name
qwe -s              Show tag of current directory

Use <TAB> to autocomplete <tag>[/<path>].
```

## Interactive Use

Type `qwe` alone to interactively select a directory.

# OTHER NOTES
This kfocus-qwe package automatically installs a symlink from
`/usr/share/qwe/qwe.source` to `/etc/bash_completion.d/qwe`.
If qwe is not desired system-wide, one may delete this symlink and
add `source /usr/share/qwe/qwe.source` in .bashrc.

One can add qwe system-wide by adding a symlink from `qwe.source` to
`/etc/bash_completion.d/qwe`.

Bookmarks are stored in a tab-delimited file called `/.qwe.data`.
The `$HOME` directory is parameterized so this file can be shared by
multiple users.


