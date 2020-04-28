#!/bin/bash


#############################################################################
#author       :    fushikai
#date         :    20190723
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Publish firewall scripts to the /zfmd/safe directory
#    
#
#############################################################################

tuser=$(whoami)
#tuser=zfmd
uid=$(id -u ${tuser})
#echo $uid
if [ ${uid} -ne 0 ];then
    echo -e "\n\tERROR: Please use root user operation!\n"
    exit 0
fi


baseDir=$(dirname $0)

echo "cd ${baseDir}"
cd ${baseDir}


toScriptDir=/zfmd/safe
tosptCfg="${toScriptDir}/fw/cfg/network.conf"
tosptop="${toScriptDir}/fw/opfw"


if [[ ! -d ${toScriptDir} ]];then
    echo "mkdir -p ${toScriptDir}"
    mkdir -p ${toScriptDir}
fi

if [ -e "${tosptCfg}" ];then
    backsptcfg="./network.conf$(date +%Y%m%d%H%S)"
    echo "cp ${tosptCfg} ${backsptcfg}"
    cp ${tosptCfg} ${backsptcfg}
fi

echo "cp -Rf fw ${toScriptDir}"
cp -Rf fw ${toScriptDir}

if [[ ! -z ${backsptcfg} && -e ${backsptcfg} ]];then
    echo "cp ${backsptcfg} ${tosptCfg}"
    cp ${backsptcfg} ${tosptCfg}
    echo "rm ${backsptcfg}"
    rm ${backsptcfg}
fi

if [[ -e ${tosptop} && ! -x ${tosptop} ]];then
    echo "chmod u+x ${tosptop}"
    chmod u+x ${tosptop}
fi

echo ""                                                                          
echo "script [$0] execution completed !!"                                        
echo ""                                                                          
exit 0 
