#!/bin/csh

test -d $HOME && exit

logger Creating new home-directory $HOME
/usr/local/sbin/make_home_dir
cd $HOME
test -d $HOME/.ssh && exit
/usr/local/recluse/scripts/bin/mksshkey
cp -a /etc/skel/. $HOME/.
echo Home directory created
