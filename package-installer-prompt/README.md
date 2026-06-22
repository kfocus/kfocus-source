# KFocus Installer Prompt
This is a lightly modified variant of the upstream kubuntu-installer-prompt.
The upstream repository is at
https://code.launchpad.net/~kubuntu-packagers/kubuntu-packaging/+git/kubuntu-installer-prompt.
As of 2026-06-23, the packaging file under debian/ are substantially
different, to correct minor upstream issues, adhere to our coding standards,
and pull in the `kfocus-calamares-settings` package. The only source code
change is in `src/installerprompt.cpp`, where we launch Calamares using
`calamares-launch-normal` rather than launching it directly. This allows our
multi-disk prompt to appear if the user clicks "Install Kubuntu" on the
installer prompt screen.

To compare with upstream:

```bash
cd /path/to/kfocus-source;
mkdir lp;
cd lp;
pull-lp-source kubuntu-installer-prompt;
cd ..;
meld lp/kubuntu-installer-prompt-* package-installer-prompt;
```
