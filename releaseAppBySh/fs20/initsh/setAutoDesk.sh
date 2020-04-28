#!/bin/bash


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

fncFile=${baseDir}/../../shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "eror: [${fncFile}] file does not exist"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}


edFName='/etc/gdm/custom.conf'
#edFName='/root/tmp/fusk/custom.conf'
edARow1='AutomaticLoginEnable=true'
edARow2='AutomaticLogin=zfmd'

if [ ! -f ${edFName} ];then
    echo ""
    echo "eror: [${edFName}] file does not exist"
    echo ""
    exit 1

fi

rightFlag=$(egrep -w "^\[daemon" $edFName 2>/dev/null|wc -l)
if [[ $rightFlag -lt 1 ]];then
	echo "check file:$edFName is error"
	echo ""
	exit 2	
fi

setEnvOneVal "${edFName}" "AutomaticLoginEnable" "=" "${edARow1}" "#" 'daemon'
setEnvOneVal "${edFName}" "AutomaticLogin" "=" "${edARow2}" "#" 'AutomaticLoginEnable'

echo ""
echo "script [$0] execution completed !!"
echo ""
exit 0

