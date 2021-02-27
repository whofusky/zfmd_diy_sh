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



baseDir=$(dirname $0)

fncFile=${baseDir}/../../../shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "eror: [${fncFile}] file does not exist"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}


ridata=/zfmd/wpfs20/ri3data
fgDir1=/zfmd/wpfs20/ri3data/fgfs
fgDir2=/zfmd/wpfs20/ri3data/fgfs2

dstDir=/zfmd/wpfs20
dstMete=/zfmd/wpfs20/mete
dstMetBin=/zfmd/wpfs20/mete/bin
meteTarF=${baseDir}/../mete.tar.gz
ftpPack=${baseDir}/../ftp-0.17-54.el6.x86_64.rpm

mkpDir ${dstDir}

mkpDir ${fgDir1}
chgUandGRbyName "zfmd" "manager" "${fgDir1}" "ri3data"
mkpDir ${fgDir2}
chgUandGRbyName "zfmd" "manager" "${fgDir2}" "ri3data"


#Determine if there is an ftp client
isFtpFlag=$(which ftp 2>/dev/null|wc -l)
if [[ ${isFtpFlag} -lt 1 && -f ${ftpPack} ]];then
    echo ""
    echo "rpm -ivh ${ftpPack}"
    rpm -ivh ${ftpPack}
    echo ""
fi

if [[ -d ${dstDir} && -f ${meteTarF} ]];then
    echo ""
    echo "tar -zxvf ${meteTarF} -C ${dstDir}"
    tar -zxvf ${meteTarF} -C ${dstDir}
    echo ""
fi


#Permission processing
setPermission "${dstMetBin}/ThrMeteM" 750
setPermission "${dstMetBin}/monitErr.sh" 750

for i in ${dstMete}/sh/*.sh
do
    setPermission "$i" 750
done

find ${dstMete} -type d|while read tnaa
do
    chgUandGRbyName zfmd manager "${tnaa}" "mete"
done

echo ""
echo "script [$0] execution completed !!"
echo ""

exit 0

