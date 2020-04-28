#!/bin/bash

basedir=$(dirname $0)

ls -1 otherLog*.log|while read tnaa
do
	echo ""
	echo "---------------[${tnaa}]-------------------"
	awk -F'|' '{printf "%s|%s|%s\n",$2,$3,$4}' ${tnaa}|sort|uniq -c
	echo ""
	echo ""

done
