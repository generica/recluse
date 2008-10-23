#!/bin/bash

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

for dir in $(find -mindepth 1 -maxdepth 1 -type d)
do
	$dir/conditions && $dir/actions
done
