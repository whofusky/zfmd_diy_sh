#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20181218
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    In the 2.0 project,check and create a directory that was not created
#    according to the path configured in the weather downloader configuration
#    file locaCfg xml
#    
#
#############################################################################

mname=mete
meteDir=/zfmd/wpfs20/${mname}

if [[ $# -lt 1 ]];then
    xmlFile=/zfmd/wpfs20/mete/cfg/locaCfg.xml
else
    xmlFile=$1
fi

if [ ! -f "${xmlFile}" ];then
    echo ""
    echo "  ERROR:  file[${xmlFile}]does not exist!"
    echo ""
    exit 1
fi

baseDir=$(dirname $0)

fncFile=${baseDir}/../../../shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "  ERROR: [${fncFile}] file does not exist!"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}

echo ""
echo "  xmlFile=[${xmlFile}]"
echo ""

#mkdir 
 mkdirFromXml "${xmlFile}" "LocalDir"
 mkdirFromXml "${xmlFile}" "srcList"
 mkdirFromXml "${xmlFile}" "toAnti"
 mkdirFromXml "${xmlFile}" "toAntiBak"
 mkdirFromXml "${xmlFile}" "staLisTrig"
 mkdirFromXml "${xmlFile}" "doStaPath"
 mkdirFromXml "${xmlFile}" "doWPlanPath"
 mkdirFromXml "${xmlFile}" "cmpWPlanPath"
 mkdirFromXml "${xmlFile}" "doHPath"
 mkdirFromXml "${xmlFile}" "yesHPath"
 mkdirFromXml "${xmlFile}" "frmIIHPath"
 mkdirFromXml "${xmlFile}" "integHPath"
 mkdirFromXml "${xmlFile}" "yesIntegHPath"
 mkdirFromXml "${xmlFile}" "upHPath"

###user_name or group_name
zUserN=zfmd
zGrpN=manager
oraUserN=oracle
oraGrpN=oinstall
find ${meteDir} -type d|while read tnaa
do
    chgUandGRbyName "${zUserN}" "${zGrpN}" "${tnaa}" "${mname}"
done

find /zfmd/wpfs20/ri3data -type d|while read tnaa
do
    chgUandGRbyName "${zUserN}" "${zGrpN}" "${tnaa}" "ri3data"
done


echo ""
echo "script [$0] execution completed !!"
echo ""
exit 0
