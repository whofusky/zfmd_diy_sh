#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20181026
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    excute this shell script to update the user's last password change time 
#    in the system,in order to solve the problem that the user password will
#    expire without changing the password
#revision history:
#       fushikai@20190828@created@v0.0.0.1
#       fushikai@2019-09-23@change the version number v0.0.0.1 to the release version number V20.01.000
#       
#
#############################################################################


#软件版本号
versionNo="software version number: V20.01.000"

#加载系统环境变量配置
if [ -f /etc/profile ]; then
    . /etc/profile >/dev/null 2>&1
fi
if [ -f /root/.bash_profile ];then
    . /root/.bash_profile >/dev/null 2>&1
fi

function doJudgeCrak()
{
    local tJudgeFile="$1"
    local diffSeconds="$2"

    local tDate="$(date +%Y%m%d)"

    if [ ! -e "${tJudgeFile}" ];then
        echo "${tDate}">"${tJudgeFile}"
        return 1
    fi
    local tnum=$(egrep "^$|\s+" "${tJudgeFile}"|wc -l)
    if [ ${tnum} -gt 0 ];then
        sed -i -e 's/\s\+//g;/^$/d' "${tJudgeFile}" 
    fi
    tnum=$(egrep "^[0-9]+$" "${tJudgeFile}"|wc -l)
    if [ ${tnum} -ne 1 ];then
        echo "${tDate}">"${tJudgeFile}"
        return 1
    fi
    local fileDate=$(egrep "^[0-9]+$" "${tJudgeFile}")
    local fileSeconds="$(date -d ${fileDate} +%s)"
    local curSeconds="$(date +%s)"
    local doFlag=$(echo "${curSeconds} - ${fileSeconds} > ${diffSeconds}"|bc)

    if [ ${doFlag} -gt 0 ];then
        echo "${tDate}">"${tJudgeFile}"
        return 1
    else
        return 0
    fi
}

function upPwdChgTm()
{
    local curYMD=$(date "+%Y-%m-%d")
    local curYMDF1=$(date "+%Y%m%d")
    
    
    local pwdFile=/etc/passwd
    local shadFile=/etc/shadow
    
    local uname=$1
    local unum
    local tdays
    local tchgdate
    unum=$(egrep "^${uname}" ${pwdFile}|wc -l)
    if [ ${unum} -gt 0 ]; then
        tdays=$(egrep "^${uname}" ${shadFile}|awk -F':' '{print $3}')
        tchgdate=$(date -d "1970-01-01  $(($tdays * 86400)) seconds" +"%Y%m%d")
        if [ "${tchgdate}" != "${curYMDF1}" ];then
            chage -d ${curYMD} ${uname} && echo "" && echo "chage -d ${curYMD} ${uname}" && echo ""
            return 0
        else
            return 1
        fi
    fi
    return 2
}

baseDir="$(dirname $0)"

cfgName="${baseDir}/crackUserPwdExp.cfg"
if [ ! -e "${cfgName}" ];then
    cfgName="/zfmd/wpfs20/pwdExtension/cfg/crackUserPwdExp.cfg"
fi

if [ ! -e "${cfgName}" ];then
    #echo -e "\n\tError: cfg file [${cfgName}] not exits!\n">>${logFile}
    exit 1
fi

#对配置文件的等号两边进行去空格处理使其配置最大限度的不出错
tnum=$(sed -n '/\s\+=/p' ${cfgName}|wc -l)
if [ ${tnum} -gt 0 ];then
    sed -i 's/\s\+=/=/g' ${cfgName}
fi
tnum=$(sed -n '/=\s\+/p' ${cfgName}|wc -l)
if [ ${tnum} -gt 0 ];then
    sed -i 's/=\s\+/=/g' ${cfgName}
fi

. ${cfgName}


logFNDate="$(date '+%Y%m%d')"
#cronLogDir
if [ ! -z "${cronLogDir}" ];then
    logDir="${cronLogDir}"
else
    logDir="${baseDir}/log"
fi

if [ ! -d "${logDir}" ];then
    mkdir -p "${logDir}"
fi

logFile="${logDir}/crackUserPwdExp${logFNDate}.log"
judgeFile="${logDir}/.crackUsrDate"


#已经有脚本在运行则退出
tmpShPid=$(pidof -x $0)
tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
if [ ${tmpShPNum} -gt 1 ]; then
    echo "+++${tmpShPid}+++++${tmpShPNum}+++">>${logFile}
    echo "script [$0] has been running,this run directly exits!">>${logFile}
    exit 0
fi


#judgeFile
if [ -z "${diffDays}" ];then
    diffDays=80
fi

diffSeconds=$(echo "${diffDays} * 24 * 60 * 60"|bc)
doJudgeCrak "${judgeFile}" "${diffSeconds}"
retStat=$?
if [ ${retStat} -eq 0 ];then
    #echo -e "\ndiffDays=[${diffDays}],diffSeconds=[${diffSeconds}],judgeFile=[${judgeFile}],Does not meet the execution conditions!\n">>${logFile}
    exit 0
fi


uNameNum="${#opSysUserName[*]}"

if [ ${uNameNum} -lt 1 ];then
    exit 0
fi
#echo "uNameNum=[${uNameNum}]"

for ((idx=0;idx<${uNameNum};idx++))
do
    tUsrName="${opSysUserName[${idx}]}"
    echo  -e "\n\t$(date +%Y/%m/%d-%H:%M:%S.%N): ---[${idx}]----:tUsrName=[${tUsrName}]">>${logFile}
    retMsg=$(upPwdChgTm "${tUsrName}")
    retStat=$?
    [ ${retStat} -eq 0 ] && echo -e "do result=[${retMsg}]">>${logFile}
    [ ${retStat} -eq 1 ] && echo -e "[${tUsrName}] password has been postponed today!">>${logFile}
done

echo -e "\t$(date +%Y/%m/%d-%H:%M:%S.%N): script [$0] runs complete!!\n\n">>${logFile}

exit 0

