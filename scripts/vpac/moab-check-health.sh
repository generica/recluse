#!/bin/bash

# moab-check-health.sh
#
# A series of tests for the health of a node
#
# Written by Brett Pemberton, brett@vpac.org
# Copyright (C) 2008 Victorian Partnership for Advanced Computing

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# Moab health check script

MOAB_CHECK_HEALTH_DIR=/usr/local/recluse/scripts/vpac/moab-check-health

tmpout_temp=$(mktemp -q)
if [ $? -ne 0 ]
then
	echo "ERROR Could not mktemp, filesystem failures"
	exit 1
fi
tmpout=$(mktemp)

failed=0
verbose=0

if [ $# -gt 0 ]
then
	if [ $1 == "-v" ]
	then
		verbose=1
	fi
fi

eval ls $MOAB_CHECK_HEALTH_DIR/enabled/* > /dev/null 2>&1
if [ $? -ne 0 ]
then
	exit 0
fi

for script in $MOAB_CHECK_HEALTH_DIR/enabled/*
do
	if [ $verbose -eq 1 ]
	then
		echo "testing $script"
	fi
	$script > $tmpout_temp
	if [ $? -eq 1 ]
	then
		failed=$[$failed+1]
		if [ $verbose -eq 1 ]
		then
			echo "Failure: "
			cat $tmpout_temp
		fi
	fi
	cat $tmpout_temp >> $tmpout
done

if [ $failed -eq 1 ]
then
	cat $tmpout
	rm -f $tmpout $tmpout_temp
	exit 1
elif [ $failed -gt 1 ]
then
	firsterror="$(head -n1 $tmpout) [$failed failures in total]"
	echo $firsterror
	tail -n $[$(wc -l $tmpout | awk '{print $1}')-1] $tmpout
	rm -f $tmpout $tmpout_temp
	exit 1
else
	rm -f $tmpout $tmpout_temp
	exit 0
fi
