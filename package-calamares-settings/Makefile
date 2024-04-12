#!/usr/bin/make -f

#SUBDIRS :=

all:
	# basicwallpaper
	(cd common/basicwallpaper && mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release && make)
	# kfocus OEM setup stuff
	(cd kfocus && mkdir oemconfig && cd oemconfig && mkdir -p usr/bin && mkdir -p etc/calamares && mkdir -p usr/share/xsessions && mkdir -p usr/libexec && mkdir -p etc && mkdir -p usr/share/applications)
	(cp kfocus/calamares-logs-helper kfocus/oemconfig/usr/bin/)
	(cp kfocus/kfocus-prep-user kfocus/oemconfig/usr/libexec/)
	(cp kfocus/oem/sddm.conf kfocus/oemconfig/etc/)
	(cp kfocus/oem/sudoers.oem kfocus/oemconfig/etc/ && chmod 400 kfocus/oemconfig/etc/sudoers.oem)
	(cp kfocus/oem/calamares-oemfinish.sh kfocus/oemconfig/usr/libexec/)
	(cp kfocus/oem/calamares-finish-oem kfocus/oemconfig/usr/bin/)
	(cp kfocus/oem/calamares-finish-oem.desktop kfocus/oemconfig/usr/share/applications/)
	(cp -r kfocus/branding kfocus/oemconfig/etc/calamares/)
	(cp -r kfocus/oem/modules/ kfocus/oemconfig/etc/calamares/)
	(cp kfocus/oem/settings.conf kfocus/oemconfig/etc/calamares/)
	(cp kfocus/oem/kubuntu-oem-env/kubuntu-oem-environment.desktop kfocus/oemconfig/usr/share/xsessions/)
	(cp kfocus/oem/kubuntu-oem-env/start-kubuntu-oem-env kfocus/oemconfig/usr/libexec/)
	(cp common/basicwallpaper/build/basicwallpaper kfocus/oemconfig/usr/bin/)
	(fakeroot bash -c "chown -R root:root kfocus/oemconfig && tar cvzf kfocus/oemconfig.tar.gz kfocus/oemconfig")
	# Get rid of the unnecessary files
	find kfocus/ -type f -iname "*.in" | xargs rm -f
	find kfocus/ -type f -iname "Makefile" | xargs rm -f
	rm -rf kfocus/oemconfig
	rm -rf common/basicwallpaper/build
# vim:ts=4
