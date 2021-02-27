#!/bin/bash


#############################################################################
#author       :    fushikai
#date         :    20181017
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Publish the startup script to the corresponding host
#    And configure the scheduled task of the startup script
#
#############################################################################

if [[ $# -lt 1 ]];then
    echo ""
	echo "please input like: $0 <[mete]/[scada]/[pre1]/[pre2]/[gzz]>"
	echo ""
	exit 1
fi

if [[ "$1" != "mete" && "$1" != "scada" && "$1" != "pre1" && "$1" != "pre2" && "$1" != "gzz" ]];then
    echo ""
	echo "parameter error,please input like: $0 <[mete]/[scada]/[pre1]/[pre2]/[gzz]>"
	echo ""
	exit 2
fi

echo ""
echo "====$1 server====="
echo ""

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

updateFile "${stSrcOpDir}/$1/rcfgRoot.cfg" "${toScriptDir}/rcfgRoot.cfg"
updateFile "${stSrcOpDir}/$1/rcfg.cfg" "${toScriptDir}/rcfg.cfg"

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
echo "Configuring cron tasks"
cronDir=/var/spool/cron
cronRoot=$cronDir/root
cronZfmd=$cronDir/zfmd

cronRNum=$(grep -v "^#" ${cronRoot} 2>/dev/null|grep -w proRunChkRoot.sh|wc -l)
cronZNum=$(grep -v "^#" ${cronZfmd} 2>/dev/null|grep -w proRunChk.sh|wc -l)
    
if [[ $cronRNum -lt 1 ]];then
    echo '* * * * * /zfmd/wpfs20/startup/proRunChkRoot.sh >>/zfmd/wpfs20/startup/log/cron_proRunChkRoot.log 2>&1'">>${cronRoot}"
    echo '* * * * * /zfmd/wpfs20/startup/proRunChkRoot.sh >>/zfmd/wpfs20/startup/log/cron_proRunChkRoot.log 2>&1'>>${cronRoot}
fi    
if [[ $cronZNum -lt 1 ]];then
    echo '* * * * * sleep 10 && /zfmd/wpfs20/startup/proRunChk.sh >>/zfmd/wpfs20/startup/log/cron_proRunChk.log 2>&1'">>${cronZfmd}"
    echo '* * * * * sleep 10 && /zfmd/wpfs20/startup/proRunChk.sh >>/zfmd/wpfs20/startup/log/cron_proRunChk.log 2>&1'>>${cronZfmd}
fi

if [[ "$1" = "mete" ]];then
    if [[ -f /zfmd/wpfs20/mete/bin/monitErr.sh ]];then
        cronZMNum=$(grep -v "^#" ${cronZfmd} 2>/dev/null|grep -w monitErr.sh|wc -l)
        if [[ $cronZMNum -lt 1 ]];then
            echo '* * * * * sleep 34 && /zfmd/wpfs20/mete/bin/monitErr.sh >>/zfmd/wpfs20/mete/log/monitErr_sh.log 2>&1'">>${cronZfmd}"
            echo '* * * * * sleep 34 && /zfmd/wpfs20/mete/bin/monitErr.sh >>/zfmd/wpfs20/mete/log/monitErr_sh.log 2>&1'>>${cronZfmd}
        fi
    fi
elif [[ "$1" = "scada" ]];then
    echo ""
elif [[ "$1" = "pre1" || "$1" = "pre2" ]];then
    echo ""
elif [[ "$1" = "gzz" ]];then
    echo ""
else
    echo "unrecognixable input parameters"
	echo ""
	exit 3
    
fi

chgUandGzfmd "${zUserN}" "${zGrpN}" "${cronZfmd}"
chgUandGzfmd "${rootUserN}" "${rootGrpN}" "${cronRoot}"


echo ""
echo "script [$0] execution completed !!"
echo ""
exit 0
