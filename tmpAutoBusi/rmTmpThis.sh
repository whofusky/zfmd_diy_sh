#!/bin/bash

readDir=`dirname $0`
mvTmp="${readDir}/tmp"

if [[ ! -d ${mvTmp} ]];then
	mkdir -p ${mvTmp}
fi

num1=$(cd ${readDir} && ls -1 qxsj* 2>/dev/null|wc -l)
num2=$(cd ${readDir} && ls -1 ycsj*  2>/dev/null|wc -l)
num3=$(cd ${readDir} && ls -1 busilist_*.tmp 2>/dev/null|wc -l)

echo "num1=$num1"
echo "num2=$num2"
echo "num3=$num3"

cd ${readDir}

if [[ ${num1} -gt 0 ]];then
	mv qxsj* ${mvTmp}	
fi

if [[ ${num2} -gt 0 ]];then
	mv ycsj* ${mvTmp}	

fi

if [[ ${num3} -gt 0 ]];then
	mv busilist_*.tmp ${mvTmp}	

fi

