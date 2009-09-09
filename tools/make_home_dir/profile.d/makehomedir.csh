#!/bin/csh

test -d $HOME && exit

logger Creating new home-directory $HOME
/usr/local/sbin/make_home_dir

if ($status == -1) then
 
	test -d $HOME then
	echo "*** FAILED TO CREATE HOME DIRECTORY - PLEASE REPORT TO help@vpac.org";
	sleep 10
	exit 1
	
endif


if ($status == 0) then
 	echo "Home directory created"
	cp -a /etc/skel/. $HOME/.
	/usr/local/recluse/scripts/bin/mksshkey
	cd $HOME
endif

if ($status == 3) then
 	
	cd $HOME
endif

