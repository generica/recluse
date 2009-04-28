#!/usr/bin/perl -W
use strict;

# PBS Cluster Node Checking progam.
#
# Written by Damon Smith, damon@vpac.org
# Copyright (C) 2005 Victorian Partnership for Advanced Computing
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
									
# Description:

# Checks node processes, and reports any processes running on compute 
# nodes that are not owned by people running jobs on that node.

# Usage:

# First: change the prefix to match your node hostname prefix.
# Second: Ensure you have access to the commands that need to be called,
# which are:
# qstat and pbsnodes from PBS, as well as the custom script
# whosonnode, which will be run on every node by dsh.  whosonnode  
# should be bundled with this script.

#******************************************************
# C O N F I G U R A T I O N   O P T I O N S
#******************************************************
my $tempVal = `hostname`;
my @tempList = split(/[\.\-]/, $tempVal);
my $prefix = $tempList[0];

my $psCommand = "/usr/local/bin/dsh -f -N compute /usr/local/recluse/scripts/bin/whosonnode 2>&1;true";
#my $psCommand = "/usr/bin/pdsh -g compute /usr/local/recluse/scripts/bin/whosonnode 2>&1;true";
my $pbsNodesCommand = "/usr/local/bin/pbsnodes -a";
my $qstatCommand = "/usr/local/bin/qstat";
my $verbosity = "0";
#******************************************************
#
#******************************************************

my ( %jobOwners, %nodeJobs, %nodeStates, %nodeCPUs, @procOwners );
if ($#ARGV >= 0) {
	if ($ARGV[0] eq "-v") {
		$verbosity = 1;
	} elsif ($ARGV[0] =~ /^\-/) {
		print "\n*** VPAC Cluster process checker. ***\n";
		print "Checks whether there are any rogue processes on compute\n";
		print "nodes of the cluster.\n\n";
		print "Use -v for verbose output, or just run it with no args for\n";
		print "quiet mode.\n\n\n";
		exit 0;
	}
}

createJobMap( \%jobOwners );
createNodeInfo( \%nodeJobs, \%nodeStates, \%nodeCPUs );
createProcInfo( \@procOwners );
compareProcsWithJobs( \%jobOwners, \%nodeJobs, \%nodeStates, \@procOwners );

sub createJobMap 
{
	debugMessage("getting job info\n", 1);
	my ( $jobOwners ) = @_;
	my @q;	
	my @qstat = `$qstatCommand`;
	
	for ( @qstat ) {
		if ( /^[0-9]/ ){
			@q = split /[ ]+/;
			if ( $q[4] eq "R" ) {
				my @tempJobSplit = split(/\./,$q[0]);
				$jobOwners->{$tempJobSplit[0]} = $q[2];
				debugMessage("added job $tempJobSplit[0] : $q[2]\n", 1);
				
			}
		}
	}
}

sub createNodeInfo 
{
	debugMessage("getting node info:\n", 1);
	my ( $nodeJobs, $nodeStates ) = @_;

	my @pbs = `$pbsNodesCommand`;
	
	my ( $line, $name, $state, @jobs, @temp );
	do
	{
		$line = trim(shift(@pbs)); 
		if ($line =~ /^$prefix/) {
			$name = $line;
			$nodeJobs->{$name} = "";
		} else {
			@temp = split(/[\s=]+/,$line);
			if ($#temp > 0) {
				if ( $temp[0] eq 'state' ) {
					$nodeStates->{$name} = $temp[1];
					debugMessage("added state: $name -> $temp[1]\n",1);
				}
				if ( $temp[0] eq 'jobs' ) {
					shift(@temp);
					$nodeJobs->{$name} = join("",@temp);
					debugMessage("added jobs: $name -> @temp\n", 1);
				}
			}
		}
	} while ( $#pbs > 0 );
		
}

sub createProcInfo 
{
	
	debugMessage("getting process owners on nodes\n", 1);
	my ( $procOwners ) = @_;

	my @procs = `$psCommand`;

	for ( @procs ) {
		my @temp = split(/[\s.\:]/,$_);
		if ( $temp[0] =~ /^$prefix/) {
			push (@$procOwners, "$temp[0]:$temp[3]");
			debugMessage("added proc $temp[0] : $temp[3]\n", 1);
		}
	}
	
}

sub compareProcsWithJobs 
{
	my ( $jobOwners, $nodeJobs, $nodeStates, $procOwners ) = @_;
	my ( $node, $procOwner, $jobs, $jobNum );
	my ( @temp1, @temp2, $hasOwner );
	my $outputMessage = "";

	debugMessage("Comparing process owners with job owners:\n",1);
	
	#for each process on each node, see if it's got a valid owner.

	for ( @$procOwners ) {
		$hasOwner = 0;
		#get process node and owner
		($node, $procOwner) = split(/:/, $_);			
	
		#get jobs on the node
		$jobs = $nodeJobs->{$node};
		@temp1 = split(/,/, $jobs);
		for (@temp1 ) {
			@temp2 = split(/[\/\.]/);
			$jobNum = $temp2[1];
			debugMessage("node: $node, comparing: " . $jobOwners->{$jobNum} . " with $procOwner", 1);
			if ( $jobOwners->{$jobNum} eq $procOwner ) {
				debugMessage(" matching\n", 1);	
				$hasOwner = 1;
			} else {
				debugMessage("\n", 1);	
			}
		}
		debugMessage("\n", 1);	
		if (!$hasOwner) {
			$outputMessage .= "rogue process owned by: $procOwner on $node\n";

		}
	}
	debugMessage("Results: \n", 1);
	if ($outputMessage eq "") {
		debugMessage("No rogue processes found\n\n",1);
	} else {
		debugMessage($outputMessage,0);
		exit 1;
	}
}

sub debugMessage 
{
	my ( $message, $level ) = @_;
	if ($level <= $verbosity) {
		print $message;
	}
}

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
