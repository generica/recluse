#!/usr/bin/perl

# Make sure that the NFS mounts we have are not stale.
# Expected to be called locally on the box and state is communicated back
# to mon via a special snmp var.
# Augie Schwer <augie@corp.sonic.net>

use strict;
use warnings;
use English;

my $failed_dirs = 0;
my @nfs_mounts  = ();
my @mount_lines = ();
my ($line,$dir,$pid);
my $timeout	= 3;

# Get the list of currently mounted NFS mounts.
@mount_lines = `mount -t nfs`;

foreach $line (@mount_lines)
{
	push @nfs_mounts , (split / / , $line)[2];
}

chdir('/opt/nfsmonitor/');
umask(0022);
close(STDIN);
close(STDOUT);
close(STDERR);
open(STDIN, '/dev/null');
open(STDOUT, '>/dev/null');
open(STDERR, '>/dev/null');

# Do a readdir on all the mounts; if we don't come back within the timeout, then 
# alert to break the hanging proc..
foreach $dir (@nfs_mounts)
{
	$pid = fork;

	if ($pid)
	{	#parent
		sleep 1;
		exit 1 if -e '/tmp/nfs_monitor.lock';

		eval
		{
			local $SIG{'ALRM'} = sub { die 'Timeout Alarm' };
			alarm $timeout;

			waitpid($pid,0);
			alarm 0;
		};

		if ($EVAL_ERROR =~ 'Timeout Alarm')
		{
			$failed_dirs = 1;
		}
	}
	else
	{	#child
		# touch lock file here and don't continue of file exists so we don't pile up.
		exit if -e '/tmp/nfs_monitor.lock';
		`touch /tmp/nfs_monitor.lock`;
		opendir(DIR, $dir);
		readdir(DIR);
		closedir(DIR);
		`rm -f /tmp/nfs_monitor.lock`;
		exit;
	}
}

exit $failed_dirs;

