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

CONFIG=/usr/local/recluse/config
[ -r "$CONFIG" ] || echo "Can't source $CONFIG"
[ -r "$CONFIG" ] || exit 0
source $CONFIG

hostname=$(hostname | sed -e 's/\..*//')

if [ "$hostname" == "$cluster" ]
then
	node="head"
elif [ "$hostname" == "${cluster}-m" ]
then
	node="mgt"
else
	node="compute"
fi

# perform tests here

if [ $myrinet -eq 1 ]
then
	count=$(/sbin/lspci -v -d "14c1:" | grep "Memory" | sed 's/.*(\(.*\),.*/\1/')
	# should be 64-bit

	if [ "$count" != "64-bit" ]
	then
		echo "ERROR myrinet card is not in 64bit mode"
		exit 1
	fi

	gm_board_info=/sbin/gm_board_info

	if [ ! -x $gm_board_info ]
	then
		echo "ERROR gm_board_info not found"
		exit 1
	fi

	count=$($gm_board_info | wc -l)

	# We want at least 5 lines, otherwise the board may not have been initialised

	if [ $count -lt 5 ]
	then
		echo "ERROR myrinet board not initialised"
		exit 1
	fi

	count=$($gm_board_info | grep -c "Could not get host name: ")

	# 20 is an arbitrary number.
	# there is generally one timeout for every port on the switch that _was_ once active but now isn't
	# so around 0-3 is acceptable
	# if the board on this machine has died, then it will generally have over 100 matches

	if [ $count -gt 20 ]
	then
		echo "ERROR myrinet board timing out on hosts"
		exit 1
	fi

	count=$($gm_board_info | wc -l)

	# try to make sure it sees other nodes

	if [ $count -lt 50 ]
	then
		echo "ERROR myrinet board not seeing other hosts"
		exit 1
	fi

fi

if [ "$node" == "head" ]
then
	drives=$head_node_smart_drives
elif [ "$node" == "mgt" ]
then
	drives=$mgt_node_smart_drives
else
	drives=$compute_node_smart_drives
fi

count=0

for drive in $drives
do
	count=$[$count+$(/usr/sbin/smartctl -a -d ata $drive | grep "^198" | awk '{print $10}')]
	/usr/sbin/smartctl -d ata -H $drive > /dev/null
	count=$[$count+$?]
done

if [ $count -ne 0 ]
then
	echo "ERROR SMART has detected a hard drive problem"
	exit 1
fi

if [ $infiniband -eq 1 ]
then
#
# This could be a software issue rather than hardware..
#
#	count=$(dmesg | grep -c "HW2SW_MPT failed")
#
#	if [ $count -ne 0 ]
#	then
#		echo "ERROR infiniband board failures"
#		exit 1
#	fi

	count=$(dmesg | grep -c "INFO: task mthca_catas")

	if [ $count -ne 0 ]
	then
		echo "ERROR infiniband board warnings"
		exit 1
	fi
fi


count=$(dmesg | grep -c "IPMI message handler: Event queue full, discarding an incoming event")

if [ $count -ne 0 ]
then
	echo "ERROR ipmi card failures"
	exit 1
fi

count=$(grep -c "^$storage_server" /proc/mounts)

if [ $count -lt 1 ]
then
	echo "ERROR nfs user store not mounted"
	exit 1
fi

count=$(dmesg | grep -Eci "SCSI Error|I/O Error")

if [ $count -ne 0 ]
then
	echo "ERROR scsi errors"
	exit 1
fi

count=$(dmesg | grep -Eci "BUG: soft lockup")

if [ $count -ne 0 ]
then
	echo "ERROR kernel soft lockup errors"
	exit 1
fi

count=$(dmesg | grep -Eci "kernel BUG at lib/list_debug.c:72")

if [ $count -ne 0 ]
then
	echo "ERROR known pre-2.6.25 kernel bug in list_debug.c"
	exit 1
fi

# taking this out, seems to be just storage problems - bp july 10 2008
#
#count=$(dmesg | grep -Eci "INFO: task .* blocked")
#
#if [ $count -ne 0 ]
#then
#	echo "ERROR kernel task blocked"
#	exit 1
#fi

count=$(dmesg | grep -Ec "BUG:")

if [ $count -ne 0 ]
then
	echo "ERROR uncaught kernel BUG report"
	exit 1
fi

count=$(dmesg | grep -Ec "kernel BUG")

if [ $count -ne 0 ]
then
	echo "ERROR uncaught kernel BUG report"
	exit 1
fi

count=$(dmesg | grep -Eci "invalid opcode:")

if [ $count -ne 0 ]
then
	echo "ERROR kernel invalid opcode report"
	exit 1
fi

# have to take this out too to stop blocked jobs being reported
# bp - july 10 2008
#
#count=$(dmesg | grep -Eci "Call Trace:")
#
#if [ $count -ne 0 ]
#then
#	echo "ERROR uncaught kernel report"
#	exit 1
#fi

if [ "$node" == "compute" -a $compute_runs_xvfb -eq 1 ]
then
	search=Xvfb

	count=$(ps ax | awk '{print $5}' | grep -c "$search$")

	if [ $count -eq 0 ]
	then
		echo "ERROR xvfb not running"
		exit 1
	fi
fi

id $user_lookup &>/dev/null;
count=$?

if [ $count -ne 0 ]
then
	echo "ERROR user lookup failed"
	exit 1
fi

tmp=$(df -lP | grep /tmp | awk '{print $5}' | awk -F% '{print $1}')

if [ x"$tmp" != "x" ]
then
	if [ $tmp -gt 90 ]
	then
		echo "ERROR tmp is almost full"
		exit 1
	fi
fi

usr=$(df -lP | grep /usr/spool | awk '{print $5}' | awk -F% '{print $1}')

if [ x"$usr" != "x" ]
then
	if [ $usr -gt 90 ]
	then
		echo "ERROR spool partition is almost full"
		exit 1
	fi
fi

test -s /var/log/mcelog
count=$?

if [ $count -eq 0 ]
then
	echo "ERROR mcelog errors"
	exit 1
fi

exit 0
