#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20181104
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    ${inUser}
#    
#
#############################################################################

function pcfgErrMsg()
{
    if [ $# -lt 1 ];then
        echo "ERROR:input parameters less then 1"
        return 1
    fi

    doFlag=$1
    shift
    
    tmpStr=""
    [ ${doFlag} -eq 0 ] && tmpStr="没有找到，"
    [ ${doFlag} -eq 1 ] && tmpStr="【已经停止监视】，"
    [ ${doFlag} -eq 2 ] && tmpStr="【已经在监视中】，"

    echo ""
    echo -n " -------ERROR--------:"
    
    echo -n "你输入的程序"
    if [ $# -gt 0 ];then
        echo -n "在配置文件"
        for cfgName in $@;do
            echo -n "[${cfgName}]"
        done
        echo -n "中"
    fi
    echo -n "${tmpStr}
                 请重新输入,如果要终止输入退出程序请在程序名处输入数字[4]
    "
    echo ""
    return 0
}

baseDir=$(dirname $0)

fncFile=${baseDir}/shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "eror: [${fncFile}] file does not exist"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}

#pcfgErrMsg 2 "aa" "bb"


tstdir=${baseDir}/testdir

txfile=${tstdir}/locaCfg.xml
tAtrtChr=$(getlsattrI $txfile)
delattrI $txfile
ret=$?
echo "---ret=[${ret}]"
echo "----tAtrtChr=[${tAtrtChr}]"
exit 0

txfile1=${tstdir}/1/2/22/3/4
#mkdirFromXml ${txfile} "LocalDir"
#chgUandGRx "root" "root" "${txfile1}" 3
chgUandGRbyName "root" "root" "${txfile1}" "2"
retstat=$?
echo "--retstat=[${retstat}]"

#chgUPwd "fusk" '$1$etzH/AU.$s3a53oVt7jFt/CBGs/2v5.'

echo ""
echo "script [$0] execution completed !!"
echo ""
