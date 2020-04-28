#!/bin/sh


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

mkpDir "${toDstDirBin}"
    chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDir}"
    chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDirBin}"


updateFile "${stSrcDir}/ThrMeteM" "${toDstDirBin}/ThrMeteM"
updateFile "${stSrcDir}/meteShFunc.sh" "${toDstDiSh}/meteShFunc.sh"
updateFile "${stSrcDir}/getFileFtp.sh" "${toDstDiSh}/getFileFtp.sh"

echo ""
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDirBin}/ThrMeteM"
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDiSh}/meteShFunc.sh"
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toDstDiSh}/getFileFtp.sh"


setPermission "${toDstDirBin}/ThrMeteM" "750"
setPermission "${toDstDiSh}/meteShFunc.sh" "750"
setPermission "${toDstDiSh}/getFileFtp.sh" "750"


echo ""
echo "script [$0] execution completed !!"
echo ""
exit 0
