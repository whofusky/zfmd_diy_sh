#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20190827
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    根据crackOraPwdExp.cfg文件中配置的用户名及密码登录oracle数据库
#    对密码进行延期
#    
#revision history:
#       fushikai@20190827@created@v0.0.0.1
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
if [ -f /home/oracle/.bash_profile ];then
    . /home/oracle/.bash_profile 2>&1
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

function crackOneUser()
{
    if [ $# -ne 3 ];then
        echo "Error:function crackOneUser input parameter not eq 3"
        return 1
    fi
    local usrName="$1"
    local usrPwd="$2"
    local conIdentifier="$3"
    #export ORACLE_SID="${conIdentifier}"
    sqlplus -S " / as sysdba"<<EOF
    alter user ${usrName} identified by "${usrPwd}";
    alter user ${usrName} account unlock;
    commit;
    SELECT to_char(ptime,'yyyy-mm-dd HH24:MI:SS') as op_time from user$ where name=upper('${usrName}');
    exit;
EOF

    return 0
}


baseDir="$(dirname $0)"
cfgName="${baseDir}/crackOraPwdExp.cfg"
if [ ! -e "${cfgName}" ];then
    cfgName="/zfmd/wpfs20/pwdExtension/cfg/crackOraPwdExp.cfg"
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
#cronLogDir="./log"
if [ ! -z "${cronLogDir}" ];then
    logDir="${cronLogDir}"
else
    logDir="${baseDir}/log"
fi

if [ ! -d "${logDir}" ];then
    mkdir -p "${logDir}"
fi

logFile="${logDir}/crackOraPwdExp${logFNDate}.log"
judgeFile="${logDir}/.crackOraDate"





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

echo -e "\ndiffDays=[${diffDays}],diffSeconds=[${diffSeconds}],judgeFile=[${judgeFile}],meet the execution conditions!\n">>${logFile}

uNameNum="${#userName[*]}"
uPwdNum="${#userPwd[*]}"
uCnIdNum="${#connectIdentifier[*]}"

if [ ${uNameNum} -lt 1 ];then
    exit 0
fi
if [[ ${uNameNum} -ne ${uPwdNum} || ${uNameNum} -ne ${uCnIdNum} ]];then
    echo "Error:uNameNum=[${uNameNum}];uPwdNum=[${uPwdNum}],uCnIdNum=[${uCnIdNum};They are not equal to each other!">>${logFile}
    exit 2
fi

if [ ${uNameNum} -gt 0 ];then
    echo  -e "\n\t$(date +%Y/%m/%d-%H:%M:%S.%N): Configure the number of users to process as [${uNameNum}]!">>${logFile}
fi

for ((idx=0;idx<${uNameNum};idx++))
do
    tUsrName="${userName[${idx}]}"
    tUsrPwd="${userPwd[${idx}]}"
    tConStr="${connectIdentifier[${idx}]}"
    echo  -e "\n\t$(date +%Y/%m/%d-%H:%M:%S.%N): ---[${idx}]----:tUsrName=[${tUsrName}],tUsrPwd=[${tUsrPwd}],tConStr=[${tConStr}]">>${logFile}
    export ORACLE_SID="${tConStr}"
    retMsg=$(crackOneUser "${tUsrName}" "${tUsrPwd}" "${tConStr}")
    echo -e "do result=[\n${retMsg}\n]">>${logFile}
done

#echo "${logFNDate}"

#crackOneUser "zfmd" "0796-Gls" "glsorcl"

echo -e "\t$(date +%Y/%m/%d-%H:%M:%S.%N): script [$0] runs complete!!\n\n">>${logFile}

exit 0
