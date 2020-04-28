#!/bin/bash


#############################################################################
#author       :    fushikai
#date         :    20181017
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Publish custom tools to system paths
#    
#
#############################################################################



relDir=/usr/local/bin


echo ""
echo "====publish custom tools to ${relDir}====="
echo ""

if [[ ! -d ${relDir} ]];then
    echo "error:${relDir} path does not exist!"
    echo ""
    exit 1
fi

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

#echo "cd ${baseDir}"
#cd ${baseDir}

srcDir=${baseDir}/..
srcT1=${srcDir}/waitthreadof
srcT2=${srcDir}/waitpidof
srcT3=${srcDir}/getethname
dstT1=${relDir}/waitthreadof
dstT2=${relDir}/waitpidof
dstT3=${relDir}/getethname

updateFile "${srcT1}" "${dstT1}"
updateFile "${srcT2}" "${dstT2}"
updateFile "${srcT3}" "${dstT3}"

setPermission ${dstT1} 755
setPermission ${dstT2} 755
setPermission ${dstT3} 755

pvPack="${srcDir}/pv-1.4.4-1.el5.rf.i386.rpm"
#Determine if there is an ftp client
isPvFlag=$(which pv 2>/dev/null|wc -l)
if [[ ${isPvFlag} -lt 1 && -f ${pvPack} ]];then
    echo ""
    echo "rpm -ivh ${pvPack} --force --nodeps" 
    rpm -ivh ${pvPack} --force --nodeps
    echo ""
fi

echo ""
echo "script [$0] execution completed !!"
echo ""
