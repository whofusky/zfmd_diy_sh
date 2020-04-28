#!/bin/sh

#ip addr flush dev eth0
ip addr add 192.168.0.132/24 brd + dev eth0
#ip addr add 192.168.1.158/24 brd + dev eth0 valid_lft forever preferred_lft forever
ip addr list

