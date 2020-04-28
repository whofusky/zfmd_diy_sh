#!/bin/bash

#zcfg=/root/tmp/fusk/tt/startup/rcfg.cfg
#rcfg=/root/tmp/fusk/tt/startup/rcfgRoot.cfg
zcfg=/zfmd/wpfs20/startup/rcfg.cfg
rcfg=/zfmd/wpfs20/startup/rcfgRoot.cfg

if [ $(grep -w "^logMaxDay" ${zcfg} |wc -l) -eq 0 ];then
	echo "sed /^allLogDir=/a logMaxDay=10 -i ${zcfg}"
	sed "/^allLogDir=/a logMaxDay=10" -i ${zcfg}

fi
if [ $(grep -w "^logMaxSizeM" ${zcfg} |wc -l) -eq 0 ];then
	echo "sed /^allLogDir=/a logMaxSizeM=15 -i ${zcfg}"
	sed "/^allLogDir=/a logMaxSizeM=15" -i ${zcfg}
fi


if [ $(grep -w "^logMaxDay" ${rcfg} |wc -l) -eq 0 ];then
	echo "sed /^allLogDir=/a logMaxDay=10 -i ${rcfg}"
	sed "/^allLogDir=/a logMaxDay=10" -i ${rcfg}
fi
if [ $(grep -w "^logMaxSizeM" ${rcfg} |wc -l) -eq 0 ];then
	echo "sed /^allLogDir=/a logMaxSizeM=15 -i ${rcfg}"
	sed "/^allLogDir=/a logMaxSizeM=15" -i ${rcfg}
fi

echo ""
echo "script [$0] execution completed !!"
echo ""
