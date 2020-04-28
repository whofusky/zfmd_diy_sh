#!/bin/sh

#sort -n -k 1,2 -t= DataAcquisition_sh_20181202.log |uniq -c >DataAcquisition_sh_20181202_fusky.log
#sort -r -n -k 1 DataAcquisition_sh_20181203_fusky.log >DataAcquisition_sh_20181203_fusky_r1.log;

if [ $# -ne 1 ];then
	echo ""
	echo "input Error!"
	echo "please like this:"
	echo "	$0 <searchName>"
	echo ""
	echo ""
	exit 0
fi


baseDir=$(dirname $0)

searchName=$1


ls -1 ${baseDir}/DataAcquisition_sh_201812*_fusky_r1.log|while read tnaa
do 
	echo ""; 
	echo "---${tnaa}---"
	grep -w  "${searchName}"  ${tnaa}
	echo ""
done

