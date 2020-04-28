#!/bin/sh


#############################################################################
#author       :    fushikai
#date         :    20180815
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Set the ntpd service in the  Linux system.(need to be able to connect
#    to the internet)
#modify history
#   20181227@add setEnvOneVal
#
#############################################################################


baseDir=$(dirname $0)

fncFile=${baseDir}/../../shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "eror: [${fncFile}] file does not exist"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}

chgFlag=0

snum=$(service ntpd status|awk -F'[() \t]' '{print $5}'|awk '/[0-9]+/{print $0}'|wc -l)
if [ ${snum} -eq 0 ];then
    echo '###########0>>>'
    echo 'open ntpd service'
    service ntpd start
    echo "$(service ntpd status)"
fi



echo '###########1>>>'
echo "#first use ntpdate to mannually synchronize the time"
echo 'ntpdate -u cn.pool.ntp.org'
ntpdate -u cn.pool.ntp.org
echo ""

echo '###########2>>>'
echo '#modify hardware time based on system time'
echo 'hwclock --systohc'
hwclock --systohc
echo ""

edCfName=/etc/ntp.conf
#edCfName=/root/tmp/fusk/ntp.conf
tip1="1.cn.pool.ntp.org"
tip2="2.cn.pool.ntp.org"
tip3="3.cn.pool.ntp.org"
tip4="0.cn.pool.ntp.org"
tip5="cn.pool.ntp.org"
tip6="202.112.10.36"
tip7="59.124.196.83"
tip8="127.127.1.0"
addsv1="server ${tip1}"
addsv2="server ${tip2}"
addsv3="server ${tip3}"
addsv4="server ${tip4}"
addsv5="server ${tip5}"
addsv6="server ${tip6}"
addsv7="server ${tip7}"
addsv8="server ${tip8}"

tfip1="127.127.1.0 stratum"
adfudge1="fudge ${tfip1} 10"

#comment the original ntp server configuration
tnum=$(sed -n "/^server\s\+[0-9]\.rhel\.pool\.ntp\.org iburst/p" $edCfName|wc -l)
[ ${tnum} -gt 0 ] && chgFlag=1
sed  "s/^server\s\+[0-9]\.rhel\.pool\.ntp\.org iburst/#&/" -i $edCfName

#add new ntp server configuration
setEnvOneVal "$edCfName" "server" "${tip1}" "${addsv1}" "#" '^\s*#\s*server'
[ $? -eq 9 ] && chgFlag=1
setEnvOneVal "$edCfName" "server" "${tip2}" "${addsv2}" "#" 
[ $? -eq 9 ] && chgFlag=1
setEnvOneVal "$edCfName" "server" "${tip3}" "${addsv3}" "#" 
[ $? -eq 9 ] && chgFlag=1
setEnvOneVal "$edCfName" "server" "${tip4}" "${addsv4}" "#" 
[ $? -eq 9 ] && chgFlag=1
setEnvOneVal "$edCfName" "server" "${tip5}" "${addsv5}" "#" 
[ $? -eq 9 ] && chgFlag=1
setEnvOneVal "$edCfName" "server" "${tip6}" "${addsv6}" "#" 
[ $? -eq 9 ] && chgFlag=1
setEnvOneVal "$edCfName" "server" "${tip7}" "${addsv7}" "#" 
[ $? -eq 9 ] && chgFlag=1
setEnvOneVal "$edCfName" "server" "${tip8}" "${addsv8}" "#" 
[ $? -eq 9 ] && chgFlag=1

setEnvOneVal "$edCfName" "fudge" "${tfip1}" "${adfudge1}" "#" '^server'
[ $? -eq 9 ] && chgFlag=1
[ ${chgFlag} -eq 1 ] && echo "<<<###########3" && echo ""

addLocalFlag=1
if [[ $addLocalFlag -eq 1 && -f $edCfName ]];then
    #addCf2='# Hosts on local network are less restricted.'
    addip1='192.168.0.0 mask 255.255.255.0'
    addcf1="restrict ${addip1} nomodify notrap"
    setEnvOneVal "$edCfName" "restrict" "${addip1}" "${addcf1}" "#" '^\s*#\s*restrict'
    [ $? -eq 9 ] && chgFlag=1
fi

edSyntpFN=/etc/sysconfig/ntpd
#edSyntpFN=/root/tmp/fusk/ntpd
addSyn="SYNC_HWCLOCK=yes"
#echo '#set synchronize hardware time with system time'
setEnvOneVal "${edSyntpFN}" "SYNC_HWCLOCK" "=" "${addSyn}" "#"
[ $? -eq 9 ] && chgFlag=1 && echo "<<<###########4" && echo ""

if [ ${chgFlag} -eq 1 ];then
    echo '###########5>>>'
    echo 'restart the  ntpd service'
    service ntpd restart
    echo "$(service ntpd status)"
    echo ""
fi

echo '###########6>>>'
echo 'set the ntpd service to boot'
chkconfig ntpd on
echo "$(chkconfig --list ntpd)"
echo ""

echo ""
echo "script [$0] execution completed !!"
echo ""
exit 0

