#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20180107
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#   Foreword introduction:
#       Long long time ago ^-^,security demand: modify the user password 90
#       days expired,10 days before the expiration reminder
#   so:
#       Excute this script to modify user password without expiration
#
#############################################################################

deErrNo=100
baseDir=$(dirname $0)

function permfileRW()
{
	if [ $# -ne 1 ];then
		return ${deErrNo}
	fi

	fileName=$1
	if [ ! -f "${fileName}" ];then
		return $((${deErrNo}+1))
	fi
	if [ ! -r  "${fileName}" ];then
		return $((${deErrNo}+2))
	fi
	if [ ! -w  "${fileName}" ];then
		return $((${deErrNo}+3))
	fi

	return 0
}


function mOneUserPwdNoExp()
{
    if [ $# -ne 3 ];then
        echo "Error: input parameters num not eq 3!"
		return ${deErrNo}
    fi
    
    uname=$1
    dfile=$2
    mFlag=$3

    tcheck=$(echo "${mFlag}"|sed -n "/^[0-9]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && mFlag=0

    if [ ! -f "${dfile}" ];then
        echo "Error: the file [${dfile}] not exist!"
        return $((${deErrNo}+1))
    fi

    permfileRW ${dfile}
    retstat=$?
    if [ ${retstat} -ne 0 ];then
        echo "Error: user[$(whoami)] does not have read and write access to file [${dfile}]!"
        return $((${deErrNo}+2))
    fi

    
    unum=$(egrep "^\<${uname}\>.*0:90:10:::$" ${dfile}|wc -l)
    if [ ${unum} -gt 0 -a ${mFlag} -eq 1 ];then
        
        lineNum=$(sed -n "/^\<${uname}\>.*0:90:10:::$/=" ${dfile}|sed 1q)
        echo "[\"${uname}\"before modification]:"
        sed -n "${lineNum}p" ${dfile}
        sed  "${lineNum}s/0:90:10:::$/0:99999:7:::/g" -i ${dfile}
        echo "[\"${uname}\"after modification]:"
        sed -n "${lineNum}p" ${dfile}
        echo ""
    fi

    return ${unum}
    
}

edFile=/etc/shadow
#edFile=${baseDir}/../../testdir/shadow
backDir=/zfmd/wpfs20/backup
backName="shadow.$(date +%Y%m%d%H%M%S)"

mOneUserPwdNoExp "zfmd" "${edFile}" "0"
tnum1=$?
[ ${tnum1} -ge ${deErrNo} ] && exit ${tnum1}

mOneUserPwdNoExp "audit" "${edFile}" "0"
tnum2=$?
[ ${tnum2} -ge ${deErrNo} ] && exit ${tnum2}

mOneUserPwdNoExp "security" "${edFile}" "0"
tnum3=$?
[ ${tnum3} -ge ${deErrNo} ] && exit ${tnum3}

mOneUserPwdNoExp "root" "${edFile}" "0"
tnum3=$?
[ ${tnum3} -ge ${deErrNo} ] && exit ${tnum3}

mOneUserPwdNoExp "oracle" "${edFile}" "0"
tnum4=$?
[ ${tnum4} -ge ${deErrNo} ] && exit ${tnum4}

mOneUserPwdNoExp "gzz" "${edFile}" "0"
tnum6=$?
[ ${tnum6} -ge ${deErrNo} ] && exit ${tnum6}

if [[ ${tnum1} -eq 0 && ${tnum2} -eq 0 && ${tnum3} -eq 0 && ${tnum4} -eq 0 && ${tnum5} -eq 0 && ${tnum6} -eq 0 ]];then
    echo ""
    echo "  Tip: there is no content to modify!"
else
    if [ -d "${backDir}" ];then
        echo ""
        echo "\cp ${edFile} ${backDir}/${backName}"
        \cp ${edFile} ${backDir}/${backName}
        echo ""
    fi
    mOneUserPwdNoExp "zfmd" "${edFile}" "1"
    mOneUserPwdNoExp "audit" "${edFile}" "1"
    mOneUserPwdNoExp "security" "${edFile}" "1"
    mOneUserPwdNoExp "root" "${edFile}" "1"
    mOneUserPwdNoExp "oracle" "${edFile}" "1"
    mOneUserPwdNoExp "gzz" "${edFile}" "1"
fi


echo ""
echo "script [$0] execution completed !!"
echo ""
exit 0
