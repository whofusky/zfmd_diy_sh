#!/bin/sh


#############################################################################
#author       :    fushikai
#date         :    20180815
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Set the ntpd service in the  Linux system.(need to be able to connect
#    to the internet)
#
#############################################################################


echo '###########0'
echo 'open ntpd service'
service ntpd start
echo "$(service ntpd status)"



echo '###########1'
echo "#first use ntpdate to mannually synchronize the time"
echo 'ntpdate -u cn.pool.ntp.org'
ntpdate -u cn.pool.ntp.org
echo ""

echo '###########2'
echo '#modify hardware time based on system time'
echo 'hwclock --systohc'
hwclock --systohc
echo ""

echo '###########3'
edCfName=/etc/ntp.conf
#edCfName=tmp/ntp.conf
addsv1="server 1.cn.pool.ntp.org"
addsv2="server 2.cn.pool.ntp.org"
addsv3="server 3.cn.pool.ntp.org"
addsv4="server 0.cn.pool.ntp.org"
addsv5="server cn.pool.ntp.org"
addsv6="server 202.112.10.36"
addsv7="server 59.124.196.83"
addsv8="server 127.127.1.0"
addsv9="fudge 127.127.1.0 stratum 10"
addCf1="$addsv1
$addsv2
$addsv3
$addsv4
$addsv5
$addsv6
$addsv7
$addsv8
$addsv9"

numAdd1=$(egrep "^$addCf1" $edCfName 2>/dev/null|wc -l)
echo "edit file=[$edCfName]"
if [[ $numAdd1 -lt 1 && -f $edCfName ]];then

	#comment the original ntp server configuration
	sed  "s/^server/#&/" -i $edCfName

	#add new tnp server configuration
	sed "$(sed  -n "/^#server/=" $edCfName|sed -n '$p')a$addsv1" -i $edCfName
	sed "$(sed  -n "/^server/=" $edCfName|sed -n '$p')a$addsv2" -i $edCfName
	sed "$(sed  -n "/^server/=" $edCfName|sed -n '$p')a$addsv3" -i $edCfName
	sed "$(sed  -n "/^server/=" $edCfName|sed -n '$p')a$addsv4" -i $edCfName
	sed "$(sed  -n "/^server/=" $edCfName|sed -n '$p')a$addsv5" -i $edCfName
	sed "$(sed  -n "/^server/=" $edCfName|sed -n '$p')a$addsv6" -i $edCfName
	sed "$(sed  -n "/^server/=" $edCfName|sed -n '$p')a$addsv7" -i $edCfName
	sed "$(sed  -n "/^server/=" $edCfName|sed -n '$p')a$addsv8" -i $edCfName
	sed "$(sed  -n "/^server/=" $edCfName|sed -n '$p')a$addsv9" -i $edCfName

	echo "addCf1=[$addCf1]"
fi
echo ""

addLocalFlag=0
if [[ $addLocalFlag -eq 1 && -f $edCfName ]];then
	addCf2='# Hosts on local network are less restricted.'
	addCf3='restrict 192.168.0.0 mask 255.255.255.0 nomodify notrap'
	numTmp=$(egrep "^$addCf3" $edCfName 2>/dev/null|wc -l)
	if [[ $numTmp -lt 1 ]];then
		sed "$(sed -n "/^restrict/=" $edCfName|sed -n '$p')a$addCf2" -i $edCfName
		sed "$(sed -n "/^$addCf2/=" $edCfName|sed -n '$p')a$addCf3" -i $edCfName
		echo "add=[$addCf2],[$addCf3]"
		echo ""
	fi
fi

echo '###########4'
edSyntpFN=/etc/sysconfig/ntpd
#edSyntpFN=tmp/ntpd
addSyn="SYNC_HWCLOCK=yes"
addSyNum=$(egrep "^SYNC_HWCLOCK" $edSyntpFN 2>/dev/null|wc -l)
echo '#set synchronize hardware time with system time'
echo "edit file=[$edSyntpFN]"
if [[ $addSyNum -lt 1 && -f $edSyntpFN ]];then

	addSyNum1=$(egrep "^#SYNC_HWCLOCK" $edSyntpFN 2>/dev/null|wc -l)
	if [[ $addSyNum1 -lt 1 ]];then
		sed "$(sed -n /?*/= $edSyntpFN|sed -n '$p')a$addSyn" -i $edSyntpFN	
		echo 'SYNC_HWCLOCK=yes'
	else
		sed "$(sed -n /^#SYNC_HWCLOCK/= $edSyntpFN|sed -n '$p')a$addSyn" -i $edSyntpFN
		echo 'SYNC_HWCLOCK=yes'
	fi

elif [[ $addSyNum -gt 0 && -f $edSyntpFN ]];then

	sed "/^SYNC_HWCLOCK/ c$addSyn"  -i $edSyntpFN
	echo 'SYNC_HWCLOCK=yes'

fi
echo ""


echo '###########5'
echo 'restart the  ntpd service'
service ntpd restart
echo "$(service ntpd status)"
echo ""

echo '###########6'
echo 'set the ntpd service to boot'
chkconfig ntpd on
echo "$(chkconfig --list ntpd)"
echo ""


