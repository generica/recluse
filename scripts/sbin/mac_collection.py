#!/usr/bin/python

# mac_collection.py
#
# grab mac addresses of compute nodes
#
# Written by Matthew Wallis, mattw@vpac.org
# Copyright (C) 2006 Victorian Partnership for Advanced Computing

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

import sys
import os
import string
import time
from optparse import OptionParser


def main():
    parser = OptionParser()
    parser.add_option("-s", "--sys-nodes", action="store", type="int", dest="sys",
        default=0, help="Specify the number of system (management, login, storage) nodes [default: %default]")
    parser.add_option("-S", "--sys-node-start", action="store", type="int", dest="sys_start",
        default=1, help="Specify the first system (management, login, storage) node number [default: %default]")
    parser.add_option("-c", "--comp-nodes", action="store", type="int", dest="comp",
        default=8, help="Specify the number of compute nodes [default: %default]")
    parser.add_option("-C", "--comp-node-start", action="store", type="int", dest="comp_start",
        default=1, help="Specify the first compute node number [default: %default]")
    parser.add_option("-l", "--log-file", action="store", type="string", dest="log",
        default="/var/log/messages", help="Specify the log file that DHCP logs to [default: %default")
    parser.add_option("-d", "--dhcp-conf", action="store", type="string", dest="conf",
        default="/etc/dhcpd.conf", help="Specify the file you want to write the hosts to [default: %default")
    parser.add_option("-n", "--network", action="store", type="string", dest="network",
        default="172.17", help="Specify the private network (Class B) for the cluster [default: %default")
    parser.add_option("-N", "--name", action="store", type="string", dest="name",
        default="beowulf", help="Specify the cluster name [default: %default")
    (options, args) = parser.parse_args()
    dhcp_mac(options.sys, options.sys_start, options.comp, options.comp_start, options.log, options.conf, options.network, options.name)


def dhcp_mac(system, system_start, compute, compute_start, logfile, conffile, network, name):
    readlog = open(logfile, "r")
    readlog.seek(0, 2)
    if system > 0:
        print "Please turn on the system nodes one at a time in order."
        for x in range(system_start, system + system_start):
            write_system_mac(x, get_mac(readlog), conffile, network, name)
    else:
        print "No system nodes specified, skipping..."
    if compute > 0:
        print "Please turn on the compute nodes, one at a time in order."
        for y in range(compute_start, compute + compute_start):
            write_compute_mac(y, get_mac(readlog), conffile, network, name)
    else:
        print "No compute nodes specified, skipping..."


def get_mac(log):
    current_position = 0
    while 1:
        line = log.readline()
        if current_position != log.tell():
            if line.find("DHCPDISCOVER") > -1:
                print "Got %s" % (line.split(' ')[8])
                return line.split(' ')[8]
            current_position = log.tell()
            time.sleep(1)
    log.close()


def write_system_mac(count, mac, config, net, id):
    conf = open(config, "a")
    conf.write("\n")
    if count == 1:
        conf.write("host %s-m { \n\thardware ethernet %s; \n\tfixed-address %s.0.1; \n} \n" % (id, mac, net))
    if count == 2:
        conf.write("host %s { \n\thardware ethernet %s; \n\tfixed-address %s.0.2; \n} \n" % (id, mac, net))
    if count == 3:
        conf.write("host %s2 { \n\thardware ethernet %s; \n\tfixed-address %s.0.3; \n} \n" % (id, mac, net))
    conf.close()


def write_compute_mac(count, mac, config, net, id):
    conf = open(config, "a")
    conf.write("\n")
    m = count / 255
    n = count - (m * 255)
    conf.write("host %s%03d { \n\thardware ethernet %s; \n\tfixed-address %s.%d.%d; \n} \n" % (id, count, mac, net, m, n))
    conf.close()


if __name__ == "__main__":
    main()
