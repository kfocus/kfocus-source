#! /bin/bash
# Description: show dependency tree
# Author: damphat

if [ $# != 1 ]; then
	echo 'Usage: apt-rdepends-tree <package>'
	echo 'Required packages: apt-rdepends'
	exit 1  
fi

# tree template
T1="    ├─"
T2="    │    ├─"
T3="    │    └─"

# tree template for last node
T4="    └─"
T5="         ├─"
T6="         └─"

# mark '1' for parent node, '2' for child node
TEXT="$(apt-rdepends $1 | sed -e 's/^/1 /' -e 's/.*: /2 /'; echo '-')"
TOTAL=$(echo "$TEXT" | grep '^1' | wc -l) # total parent

COUNT=0
echo "$TEXT" | while read line; do
	tmp=$last
	[ "${line:0:1}" != "${last:0:1}" ] && tmp=$(echo $last | sed -e 's/^2/3/')

	[ "${tmp:0:1}" == "1" ] && ((COUNT++))

	if [ "$TOTAL" != "$COUNT" ]; then
		echo $tmp | sed -e "s/^1/$T1/" -e "s/^2/$T2/" -e "s/^3/$T3/"
	else
		echo $tmp | sed -e "s/^1/$T4/" -e "s/^2/$T5/" -e "s/^3/$T6/"
	fi

	last=$line
done
