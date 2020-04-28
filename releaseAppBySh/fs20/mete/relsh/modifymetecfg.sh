#!/bin/sh


#############################################################################
#author       :    fushikai
#date         :    20181017
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Modify the wind farm name in the configuration 
#    file of the weather download program
#
#############################################################################

if [[ $# -lt 2 ]];then
    echo ""
	echo "Error:please input like: $0 <old_wind_farm_name> <new_wind_farm_name>"
	echo ""
	exit 1
fi

oldFarName=$1
newFarName=$2

baseDir=$(dirname $0)


dstCfgF=/zfmd/wpfs20/mete/cfg/locaCfg.xml
#dstCfgF=/root/tmp/tt/locaCfg.xml

if [[ -f ${dstCfgF} && -w ${dstCfgF} ]];then
    echo "sed s/\/${oldFarName}\//\/${newFarName}\//g -i ${dstCfgF}"
    sed "s/\/${oldFarName}\//\/${newFarName}\//g" -i ${dstCfgF}
fi

echo ""
echo "script [$0] execution completed !!"
echo ""
exit 0

