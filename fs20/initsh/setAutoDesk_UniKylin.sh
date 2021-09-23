#!/bin/sh


#############################################################################
#author       :    fushikai
#date         :    20180817
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    set to automatically log in to the linux graphical desktop  
#    (no password required)
#
#############################################################################
baseDir=$(dirname $0)

fncFile=${baseDir}/shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "eror: [${fncFile}] file does not exist"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}

if [[ ${ZFMD_USER} == "" ]];then
    echo "环境变量错误"
    exit 1
fi

if [[ $# -lt 1 ]];then
    echo "please input like: $0 <[mete]/[scada]/[pre1]/[pre2]/[gzz]>"
    echo ""
    exit 1
fi

if [[ "$1" != "mete" && "$1" != "scada" && "$1" != "pre1" && "$1" != "pre2" && "$1" != "gzz" ]];then
    echo "parameter error,please input like: $0 <[mete]/[scada]/[pre1]/[pre2]/[gzz]>"
    echo ""
    exit 2
fi

edFName='/etc/lightdm/lightdm.conf'
edARow1='greeter-hide-users=true'
if [[ "$1" = "gzz" ]];then
    edARow2="autologin-user=gzz"
else
    edARow2="autologin-user=${ZFMD_USER}" 
fi

if [ ! -f ${edFName} ];then
    echo ""
    echo "eror: [${edFName}] file does not exist"
    echo ""
    exit 1
fi

rightFlag=$(egrep -w "^\[Seat" $edFName 2>/dev/null|wc -l)
if [[ $rightFlag -lt 1 ]];then
	echo "check file:$edFName is error"
	echo ""
	exit 2	
fi

sed -i '/^\s*autologin-user\s*=/d' "${edFName}"
#setEnvOneVal "${edFName}" "AutomaticLoginEnable" "=" "${edARow1}" "#" 'daemon'
setEnvOneVal "${edFName}" "autologin-user" "=" "${edARow2}" "" 'greeter-hide-users'

echo ""
echo "script [$0] execution completed !!"
echo ""
exit 0

