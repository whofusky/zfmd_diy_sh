#!/bin/bash


#############################################################################
#author       :    fushikai
#date         :    20181103
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    update the startup script to the corresponding host
#此脚本升级2.0自启动脚本的如下内容:
#   1.软件包中除配置文件外的其他文件(如脚本还工具)
#   2.调用modifycfg.sh在自启动脚本中没有添加logMaxDay和logMaxDay的配置选项自
#     动添加上
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

toScriptDir=/zfmd/wpfs20/startup
toScriptLog=${toScriptDir}/log

stSrcDir=${baseDir}/..
stSrcOpDir=${baseDir}/../optional

###user_name or group_name
zUserN=zfmd
zGrpN=manager
rootUserN=root
rootGrpN=root

mkpDir "${toScriptLog}"
    chgUandGzfmd "${zUserN}" "${zGrpN}" "${toScriptDir}"
    chgUandGzfmd "${zUserN}" "${zGrpN}" "${toScriptLog}"


updateFile "${stSrcDir}/proRunChkRoot.sh" "${toScriptDir}/proRunChkRoot.sh"
updateFile "${stSrcDir}/proRunChk.sh" "${toScriptDir}/proRunChk.sh"
updateFile "${stSrcDir}/stop.sh" "${toScriptDir}/stop.sh"
updateFile "${stSrcDir}/stopOrStartOne.sh" "${toScriptDir}/stopOrStartOne.sh"
updateFile "${stSrcDir}/judgeInCfg.sh" "${toScriptDir}/judgeInCfg.sh"
updateFile "${stSrcDir}/restore.sh" "${toScriptDir}/restore.sh"
updateFile "${stSrcDir}/software_version_description.txt" "${toScriptDir}/software_version_description.txt"

#updateFile "${stSrcDir}/$1/rcfgRoot.cfg" "${toScriptDir}/rcfgRoot.cfg"
#updateFile "${stSrcDir}/$1/rcfg.cfg" "${toScriptDir}/rcfg.cfg"
${baseDir}/modifycfg.sh

echo ""
chgUandGzfmd "${rootUserN}" "${rootGrpN}" "${toScriptDir}/proRunChkRoot.sh"
chgUandGzfmd "${rootUserN}" "${rootGrpN}" "${toScriptDir}/rcfgRoot.cfg"
chgUandGzfmd "${rootUserN}" "${rootGrpN}" "${toScriptDir}/stop.sh"
chgUandGzfmd "${rootUserN}" "${rootGrpN}" "${toScriptDir}/stopOrStartOne.sh"
chgUandGzfmd "${rootUserN}" "${rootGrpN}" "${toScriptDir}/judgeInCfg.sh"
chgUandGzfmd "${rootUserN}" "${rootGrpN}" "${toScriptDir}/restore.sh"

setPermission "${toScriptDir}/proRunChkRoot.sh" "750"
setPermission "${toScriptDir}/rcfgRoot.cfg" "754"


chgUandGzfmd "${zUserN}" "${zGrpN}" "${toScriptDir}/proRunChk.sh"
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toScriptDir}/rcfg.cfg"
chgUandGzfmd "${zUserN}" "${zGrpN}" "${toScriptDir}/software_version_description.txt"

setPermission "${toScriptDir}/proRunChk.sh" "750"
setPermission "${toScriptDir}/rcfg.cfg" "750"
setPermission "${toScriptDir}/stop.sh" "755"
setPermission "${toScriptDir}/stopOrStartOne.sh" "755"
setPermission "${toScriptDir}/judgeInCfg.sh" "755"
setPermission "${toScriptDir}/restore.sh" "755"

addattrI "${toScriptDir}/proRunChkRoot.sh"
addattrI "${toScriptDir}/proRunChk.sh"
addattrI "${toScriptDir}/stop.sh"
addattrI "${toScriptDir}/stopOrStartOne.sh"
addattrI "${toScriptDir}/judgeInCfg.sh"
addattrI "${toScriptDir}/restore.sh"
addattrI "${toScriptDir}/software_version_description.txt"

echo ""
echo "script [$0] execution completed !!"
echo ""
exit 0
