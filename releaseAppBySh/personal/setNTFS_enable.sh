#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20181222
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Install the ntfs.ko module if there is no NTFS file system module in the
#    kernel module of the system
#    
#note:
#   The ntfs.ko module version is not very compatible with the system,bug can
#   be use   
#
#############################################################################


baseDir=$(dirname $0)

fncFile=${baseDir}/../shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "  ERROR: [${fncFile}] file does not exist!"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}

fsname=ntfs
dstFileN=${fsname}.ko
srNtfsDir=${baseDir}/lib_module_kernel/${fsname}
srNtfsFile=${srNtfsDir}/${dstFileN}
if [ ! -f "${srNtfsFile}" ];then
    echo ""
    echo "  ERROR: [${srNtfsFile}] file does not exist!"
    echo ""
    exit 4
fi

dstDir=/lib/modules/2.6.32-573.el6.x86_64/kernel/fs
if [ ! -d "${dstDir}" ];then
    echo ""
    echo "  ERROR: [${dstDir}] directory does not exist!"
    echo ""
    exit 5
fi

tnum=$(find ${dstDir} -name ${dstFileN} -print 2>/dev/null|wc -l)
if [ ${tnum} -gt 0 ];then
    echo ""
    echo "  TIPS: [${dstFileN}] already existed!"
    echo "$(find ${dstDir} -name ${dstFileN} -print 2>/dev/null)"
    echo ""
    exit 0

fi

echo ""
echo "cp -r ${srNtfsDir} ${dstDir}"
cp -r ${srNtfsDir} ${dstDir}

ttmpDir=${dstDir}/${fsname}
ttmpFile=${ttmpFile}/${dstFileN}
chgUandGzfmd "root" "root" "${ttmpDir}"
chgUandGzfmd "root" "root" "${ttmpFile}"
setPermission "${ttmpDir}" "755"
setPermission "${ttmpFile}" "744"

echo "depmod -a"
depmod -a

echo "modprobe -f ${fsname}"
modprobe -f ${fsname}

echo ""
echo "The setting is successful,it is recommended to use it after restarting."


echo ""
echo "script [$0] execution completed !!"
echo ""
