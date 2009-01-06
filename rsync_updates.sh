#!/bin/bash

# rsync_updates.sh
#
# rsync centos tree to local disk
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

BASEDIR=/usr/local/recluse
CONFIG=$BASEDIR/config
[ -r "$CONFIG" ] || echo "Can't source $CONFIG"
[ -r "$CONFIG" ] || exit 0
source $CONFIG

LOGFILE=$BASEDIR/rsync_updates.sh.log
OPTS="-pvrDt --delete"

echo "Started update at" $(date) >> $LOGFILE 2>&1
logger -t rsync "re-rsyncing the centos core tree"
rsync ${OPTS} $mirror/$centosversion/os/x86_64/ $BASEDIR/centos/$centosversion/os  >> $LOGFILE 2>&1
rsync ${OPTS} $mirror/$centosversion/updates/x86_64/ $BASEDIR/centos/$centosversion/updates  >> $LOGFILE 2>&1
rsync ${OPTS} $mirror/$centosversion/addons/x86_64/ $BASEDIR/centos/$centosversion/addons >> $LOGFILE 2>&1
rsync ${OPTS} $mirror/$centosversion/extras/x86_64/ $BASEDIR/centos/$centosversion/extras >> $LOGFILE 2>&1
rsync ${OPTS} $mirror/$centosversion/centosplus/x86_64/ $BASEDIR/centos/$centosversion/centosplus >> $LOGFILE 2>&1
echo "End: " $(date) >> $LOGFILE 2>&1

