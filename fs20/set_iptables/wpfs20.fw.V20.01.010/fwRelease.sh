#!/bin/bash
#
########################################################################
#author       :    fushikai
#date         :    20211126
#dsc          :
#    Publish the firewall script to the directory: /zfmd/safe
#
########################################################################


thisShName="$0"
baseDir=$(dirname ${thisShName})
tDir0=$(echo $PWD|awk -F'/' '{print $2}')


function F_assignment()
{
    #toScriptDir=/zfmd/safe
    toScriptDir=/${tDir0}/safe
    tosptCfg="${toScriptDir}/fw/cfg/network.conf"
    tosptop="${toScriptDir}/fw/opfw"
    sucFlag=0

    return 0
}


function F_check()
{
    tuser=$(whoami)
    #tuser=zfmd
    uid=$(id -u ${tuser})
    #echo $uid
    if [ ${uid} -ne 0 ];then
        echo -e "\n\t\e[1;31mERROR:\e[0m Please execute this script as root user!\n"
        exit 0
    fi

    if [ -z "${tDir0}" ];then
        echo -e "\n\t\e[1;31mERROR:\e[0m Please do not run in the / director!\n"
        exit 1
    fi

    which iptables >/dev/null 2>&1
    local ret=$?
    if [ ${ret} -ne 0 ];then
        echo -e "\n\t\e[1;31mERROR:\e[0m 系统中没有iptables命令,请先安装iptables!\n"
        exit 2
    fi

    return 0
}


function F_mkDstDir()
{
    if [[ ! -d ${toScriptDir} ]];then
        echo -e "\n\tmkdir -p ${toScriptDir}"
        mkdir -p ${toScriptDir}
    fi

    return 0
}


function  F_backupOriginalCfg()
{
    if [ -e "${tosptCfg}" ];then
        backsptcfg="./network.conf$(date +%Y%m%d%H%S)"
        echo -e "\nbackup original cfg file:"
        echo -e "\tcp ${tosptCfg} ${backsptcfg}"
        cp ${tosptCfg} ${backsptcfg}
    fi

    return 0
}


function  F_restoreOriginalCfg()
{
    if [[ ! -z ${backsptcfg} && -e ${backsptcfg} ]];then
        echo -e "\nrestore original cfg file:"
        echo -e "\tcp ${backsptcfg} ${tosptCfg}"
        cp ${backsptcfg} ${tosptCfg}
        
        echo "delte backup file:"
        echo -e "\trm ${backsptcfg}"
        rm ${backsptcfg}
    fi

    return 0
}


function F_releaseCurPrg()
{
    echo -e "\nrelease the current script package:"
    echo -e "\tcp -Rf fw ${toScriptDir}"
    cp -Rf fw ${toScriptDir}
    [ $? -eq 0 ] && sucFlag=1

    return 0
}


function F_grantExePermissions()
{
    if [[ -e ${tosptop} && ! -x ${tosptop} ]];then
        echo -e "\n\tchmod u+x ${tosptop}"
        chmod u+x ${tosptop}
    fi

    return 0
}




main()
{
    F_check

    echo -e "\n\tcd ${baseDir}"
    cd ${baseDir}

    F_assignment
    F_mkDstDir
    F_backupOriginalCfg
    F_releaseCurPrg
    F_restoreOriginalCfg
    F_grantExePermissions

    echo "" 
    echo "  script [${thisShName}] execution completed !!"
    echo "" 

    if [ ${sucFlag} -eq 1 ];then
        echo -e "\n软件已经成功发布到目录:[${toScriptDir}]\n"
    fi

    return 0
}


main
exit 0 

