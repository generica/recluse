#!/bin/sh -x

if [ ! -d $HOME ]
then
	logger Creating new home-directory $HOME
	/usr/local/sbin/make_home_dir
	status=$?

	if [ $status -eq -1 ]
	then
		if [ ! -d $HOME ]; then
			echo '*** FAILED TO CREATE HOME DIRECTORY - PLEASE REPORT TO help@vpac.org'
			sleep 10
			exit 1
		fi
	elif [ $status -eq 0 ]
	then
		echo "Home directory created"

		cp -a /etc/skel/. $HOME/.
		test -x /usr/local/recluse/scripts/bin/mksshkey && /usr/local/recluse/scripts/bin/mksshkey

		cd $HOME
	elif [ $status -eq 3 ]
	then
		cd $HOME
	fi
fi
