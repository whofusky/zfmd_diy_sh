#!/bin/bash


#############################################################################
#author       :    fushikai
#date         :    20181207
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    update the Weather downloader program to the corresponding host
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

#echo "cd ${baseDir}"
#cd ${baseDir}




toDstDir=/zfmd/wpfs20/mete
toDstDirBin=${toDstDir}/bin
toDstDiSh=${toDstDir}/sh

stSrcDir=${baseDir}/../updatedir

###user_name or group_name
zUserN=zfmd
zGrpN=manager
rootUserN=root
rootGrpN=root

bakdir=/zfmd/wpfs20/backup
if [ -d ${bakdir} ];then
    mebakdir=${bakdir}/mete
    mkpDir "${mebakdir}"
    chgUandGzfmd "${zUserN}" "${zGrpN}" "${mebakdir}"
fi
if [ -z "${mebakdir}" ];then
    mebakdir=${toDstDir}
fi

[ -f "${stSrcDir}/addFtpModeToCfg.sh" ] && ${stSrcDir}/addFtpModeToCfg.sh

mkpDir "${toDstDirBin}"
    chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDir}"
    chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDirBin}"


updateFile "${stSrcDir}/ThrMeteM" "${toDstDirBin}/ThrMeteM" "${mebakdir}"
updateFile "${stSrcDir}/meteShFunc.sh" "${toDstDiSh}/meteShFunc.sh" "${mebakdir}"
updateFile "${stSrcDir}/getFileFtp.sh" "${toDstDiSh}/getFileFtp.sh" "${mebakdir}"
updateFile "${stSrcDir}/getFserStas.sh" "${toDstDiSh}/getFserStas.sh" "${mebakdir}"
updateFile "${stSrcDir}/putFserStas.sh" "${toDstDiSh}/putFserStas.sh" "${mebakdir}"
updateFile "${stSrcDir}/putFileFtp.sh" "${toDstDiSh}/putFileFtp.sh" "${mebakdir}"
updateFile "${stSrcDir}/getPidNum.sh" "${toDstDiSh}/getPidNum.sh" "${mebakdir}"
updateFile "${stSrcDir}/shWriteLog.sh" "${toDstDiSh}/shWriteLog.sh" "${mebakdir}"

echo ""
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDirBin}/ThrMeteM"
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDiSh}/meteShFunc.sh"
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDiSh}/getFileFtp.sh"
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDiSh}/getFserStas.sh"
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDiSh}/putFserStas.sh"
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDiSh}/putFileFtp.sh"
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDiSh}/getPidNum.sh"
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDiSh}/shWriteLog.sh"


setPermission "${toDstDirBin}/ThrMeteM" "750"
setPermission "${toDstDiSh}/meteShFunc.sh" "750"
setPermission "${toDstDiSh}/getFileFtp.sh" "750"
setPermission "${toDstDiSh}/getFserStas.sh" "750"
setPermission "${toDstDiSh}/putFserStas.sh" "750"
setPermission "${toDstDiSh}/putFileFtp.sh" "750"
setPermission "${toDstDiSh}/getPidNum.sh" "750"
setPermission "${toDstDiSh}/shWriteLog.sh" "750"



echo ""
echo "script [$0] execution completed !!"
echo ""
exit 0
