#!/bin/bash

for ((i=0;i<100;i++))
do
	for ((j=0;j<1000;j++))
	do
		echo "------i=[${i}]++++++j=[${j}]++++++++"
	done
	sleep 1
done
