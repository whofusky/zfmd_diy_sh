#!/bin/bash
. /root/.bash_profile

tmpDir=`pwd`
tNum=`/sbin/pidof -x tt.sh`
echo "time: `date +%Y/%m/%d-%H:%M:%S.%N` : tNum=$tNum" >>${tmpDir}/tt.log


exit 0
