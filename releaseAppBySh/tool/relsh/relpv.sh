#!/bin/sh


#############################################################################
#author       :    fushikai
#date         :    20190101
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Install pv tool
#    
#
#############################################################################



relDir=/usr/local/bin



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

pvPack="${srcDir}/pv-1.4.4-1.el5.rf.i386.rpm"
depPack1="${srcDir}/nss-softokn-freebl-3.14.3-22.el6_6.i686.rpm"
depPack2="${srcDir}/glibc-2.12-1.166.el6.i686.rpm"
#Determine if there is an pv tool
isPvFlag=$(which pv 2>/dev/null|wc -l)
if [[ ${isPvFlag} -lt 1 && -f ${pvPack} ]];then
    depnum1=$(ls /lib/libfreebl3.so 2>/dev/null|wc -l)
    depnum2=$(rpm -q glibc|egrep "^glibc-2.12-1.166.el6.i686$"|wc -l)
    if [[ ${depnum1} -lt 1 && ${depnum2} -lt 1 && -f ${depPack1} && -f ${depPack2} ]];then
        echo "rpm -ivh ${depPack1} ${depPack2} "
        rpm -ivh ${depPack1} ${depPack2} 
    elif [[ ${depnum1} -lt 1 && -f ${depPack1} ]];then
        echo "rpm -ivh ${depPack1}"
        rpm -ivh ${depPack1}
    elif [[ ${depnum2} -lt 1 && -f ${depPack2} ]];then
        echo "rpm -ivh ${depPack2} "
        rpm -ivh ${depPack2} 
    fi

    echo ""
    echo "rpm -ivh ${pvPack}" 
    rpm -ivh ${pvPack}
    echo ""
fi

echo ""
echo "script [$0] execution completed !!"
echo ""
