#!/bin/bash

sleep $(( $RANDOM % 900 ))

for dir in $(find -mindepth 1 -maxdepth 1 -type d)
do
	$dir/conditions && $dir/actions
done
