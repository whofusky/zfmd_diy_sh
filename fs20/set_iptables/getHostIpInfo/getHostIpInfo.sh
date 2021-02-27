#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20190521
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#               Obtain the network configuration information of the host
#    
#
#############################################################################


baseDir=$(dirname $0)

tMYD=$(date +%Y%m%d)
outTmpFile="${baseDir}/${HOSTNAME}_ipinfo-${tMYD}.txt"

>${outTmpFile}

function writeFile()
{

    echo -e "$*" >>${outTmpFile}    
    return 0
}

writeFile "\n--------------------------------------------------------------------------------"
writeFile "\t\t HOSTNAME=[ ${HOSTNAME} ]  ip infos"
writeFile "\t\t op Time: $(date +%Y-%m-%d_%H:%M:%S.%N)"
writeFile "\n--------------------------------------------------------------------------------\n"

tgeteth="${baseDir}/getethname"
if [ -e "${tgeteth}" ];then

    if [ ! -x "${tgeteth}" ];then
        chmod +x "${tgeteth}"
    fi
    writeFile "\n--------------------------getethname------------------------------------------------------"
    retMsg=$(${tgeteth})
    writeFile "\t\t ${retMsg}"
    writeFile "\n--------------------------------------------------------------------------------\n"

fi


writeFile "\n--------------------------ifconfig------------------------------------------------------"
retMsg=$(ifconfig)
writeFile "\t\t ${retMsg}"
writeFile "\n--------------------------------------------------------------------------------\n"

#which getethname >/dev/null 2>&1
#retStat=$?
#if [ ${retStat} -eq 0 ];then
#    writeFile "\n--------------------------getethname------------------------------------------------------"
#    retMsg=$(getethname)
#    writeFile "\t\t ${retMsg}"
#    writeFile "\n--------------------------------------------------------------------------------\n"
#
#fi

if [ -e /etc/sysconfig/iptables ];then
    writeFile "\n--------------------------/etc/sysconfig/iptables------------------------------------------------------"
    retMsg=$(cat /etc/sysconfig/iptables)
    writeFile "\t\t ${retMsg}"
    writeFile "\n--------------------------------------------------------------------------------\n"

fi

writeFile "\n--------------------------service iptables status------------------------------------------------------"
retMsg=$(service iptables status)
writeFile "\t\t ${retMsg}"
writeFile "\n--------------------------------------------------------------------------------\n"

writeFile "\n--------------------------chkconfig --list iptables------------------------------------------------------"
retMsg=$(chkconfig --list iptables)
writeFile "\t\t ${retMsg}"
writeFile "\n--------------------------------------------------------------------------------\n"

writeFile "\n--------------------------ss -autnp------------------------------------------------------"
retMsg=$(ss -autnp)
writeFile "\t\t ${retMsg}"
writeFile "\n--------------------------------------------------------------------------------\n"


writeFile "\n--------------------------netstat -autnp------------------------------------------------------"
retMsg=$(netstat -autnp)
writeFile "\t\t ${retMsg}"
writeFile "\n--------------------------------------------------------------------------------\n"


writeFile "\n--------------------------route -n------------------------------------------------------"
retMsg=$(route -n)
writeFile "\t\t ${retMsg}"
writeFile "\n--------------------------------------------------------------------------------\n"


writeFile "\n--------------------------ip route------------------------------------------------------"
retMsg=$(ip route)
writeFile "\t\t ${retMsg}"
writeFile "\n--------------------------------------------------------------------------------\n"







