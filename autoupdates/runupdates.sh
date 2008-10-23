#!/bin/bash

PATH=/usr/local/recluse/scripts:$PATH

immediate=0

if [ $# -eq 1 ]
then
	if [ $1 == "--immediate" ]
	then
		immediate=1
	fi
fi

if [ $immediate -eq 0 ]
then
	sleep $(( $RANDOM % 900 ))
fi

for dir in $(find /usr/local/recluse/autoupdates/ -mindepth 1 -maxdepth 1 -type d ! -name .svn)
do
	$dir/conditions && $dir/actions >> /usr/local/recluse/nodestatus/autoupdates/$HOSTNAME 2>&1
done
