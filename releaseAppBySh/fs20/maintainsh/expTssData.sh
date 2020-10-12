#!/bin/bash

#调试标识，1：只调试不执行; 0:正常执行
debugFlag=0
#写日志标识，1：把执行过程生成日志文件以备以后查询
writeLogFlag=1

#define database's  logon
tDbSource=mqzorcl        #connect_identifier
tUName=zfmd              #username
tUPwd=Hnmqzfdcdb_0402    #password

#define query tables
#tTables="tss_tbn_5mi"
tTables="tss_tbn_5mi,amt_wnd_5mi,int_frm_5mi,utf_frm" #需要有dd时间条件的表
begineDate="202008"  #define the start date format of the query as YYYYMM

#noDateTables=""  #不需要有dd时间条件的表

tDoPDir="/zfmd/wpfs20/tmp/RocGao/expTSSData"

tDoShName="$0"
tShName="${tDoShName##*/}"
tPreSh="${tShName%.*}"
logFile="${tDoPDir}/${tPreSh}_$(date +%Y%m%d).log"

tYMDHMS="$(date +%Y%m%d%H%M%S)"

tOutLName="${tPreSh}_from_${begineDate}_Data.dmp"
tOutNoDateLName="${tPreSh}_no_date_Data.dmp"

tOutFile="${tDoPDir}/${tOutLName}"
tOutNoDFile="${tDoPDir}/${tOutNoDateLName}"

tTarLName="${tPreSh}_${tYMDHMS}.tar.gz"
tOutTarFile="${tDoPDir}/${tTarLName}"

function F_echo_and_do()
{
    local cmd="$*"
    local ret=0
    local rFlag=0
    local tmpStr=""

    if [[ ! -z "${writeLogFlag}" && ${writeLogFlag} -eq 1 ]];then
        if [ -e "${logFile}" ];then
            rFlag=1
        fi
    fi

    local tnum=$(echo "${cmd}"|sed -n '/^\s*echo\b/p'|wc -l)

    if [ ${tnum} -eq 0 ];then
        if [ ${rFlag} -eq 1 ];then
            echo "${cmd}"|tee -a "${logFile}"
        else
            echo "${cmd}"
        fi
    fi

    if [[ -z "${debugFlag}" || ${debugFlag} -ne 1 ]];then
        if [ ${rFlag} -eq 1 ];then
            tmpStr=$(${cmd}  2>&1)
            ret=$?
            echo "${tmpStr}"|tee -a "${logFile}"
        else
            ${cmd}
            ret=$?
        fi
    fi

    return ${ret}
}


tBegineTm=$(date +%s)
ret=0

if [ ! -d "${tDoPDir}" ];then
    mkdir -p "${tDoPDir}"
    ret=$?
    [ ${ret} -ne 0 ] && exit 1
    if [[ ! -z "${writeLogFlag}" && ${writeLogFlag} -eq 1 ]];then
        echo "mkdir -p ${tDoPDir}"|tee -a ${logFile}
    else
        echo "mkdir -p ${tDoPDir}"
    fi
fi

if [[ ! -z "${writeLogFlag}" && ${writeLogFlag} -eq 1 ]];then
    [ ! -e "${logFile}" ] && >"${logFile}"
fi
F_echo_and_do echo ""
F_echo_and_do echo ""
F_echo_and_do echo "======================================================================begine:$(date +%Y-%m-%d_%H:%M:%S.%N)"
F_echo_and_do echo ""

have_time_flag=0
no_time_flag=0

#如果定义了不需要时间的表则对想着的表进行导出
if [ ! -z "${noDateTables}" ];then
    if [ -e "${tOutNoDFile}" ];then
        F_echo_and_do rm -rf "${tOutNoDFile}"
        ret=$?
        [ ${ret} -ne 0 ] && exit 1
    fi
    F_echo_and_do touch "${tOutNoDFile}"
    ret=$?
    [ ${ret} -ne 0 ] && exit 1
    F_echo_and_do chmod 666 "${tOutNoDFile}"
    ret=$?
    [ ${ret} -ne 0 ] && exit 1

    F_echo_and_do exp ${tUName}/${tUPwd}@${tDbSource} file=${tOutNoDFile} tables=${noDateTables} 

    no_time_flag=1
fi




#如果定义了要时间的表则对想着的表进行导出
if [ ! -z "${tTables}" ];then
    if [ -e "${tOutFile}" ];then
        F_echo_and_do rm -rf "${tOutFile}"
        ret=$?
        [ ${ret} -ne 0 ] && exit 1
    fi
    F_echo_and_do touch "${tOutFile}"
    ret=$?
    [ ${ret} -ne 0 ] && exit 1
    F_echo_and_do chmod 666 "${tOutFile}"
    ret=$?
    [ ${ret} -ne 0 ] && exit 1

    F_echo_and_do exp ${tUName}/${tUPwd}@${tDbSource} file=${tOutFile} tables=${tTables} query=\"where dd\>\=to_date\(\'${begineDate}\'\,\'yyyymm\'\)\"

    have_time_flag=1
fi

if [[ ${have_time_flag} -eq 0  && ${no_time_flag} -eq 0 ]];then
    F_echo_and_do echo -e "\n\t exp data failure:The data table to be exported is not defined!!\n"
    F_echo_and_do echo "======================================================================end:$(date +%Y-%m-%d_%H:%M:%S.%N)"
    F_echo_and_do echo ""
    exit 0
fi

F_echo_and_do echo -e "\n\t have_time_flag=[${have_time_flag}],no_time_flag=[${no_time_flag}]\n"

cd "${tDoPDir}"
F_echo_and_do cd "${tDoPDir}"
if [[ ${have_time_flag} -eq 1 && ${no_time_flag} -eq 1 ]];then
    F_echo_and_do tar -czvf "${tTarLName}" ${tOutLName} ${tOutNoDateLName}
elif [[ ${have_time_flag} -eq 1 ]];then
    F_echo_and_do tar -czvf "${tTarLName}" ${tOutLName} 
else
    F_echo_and_do tar -czvf "${tTarLName}" ${tOutNoDateLName} 
fi
ret=$?
if [ ${ret} -eq 0 ];then
    F_echo_and_do echo -e "\n\t outFile=[\e[1;31m${tOutTarFile}\e[0m]\n"
fi

if [ -e "${tOutNoDFile}" ];then
    F_echo_and_do rm -rf "${tOutNoDFile}"
    ret=$?
    [ ${ret} -ne 0 ] && exit 1
fi
if [ -e "${tOutFile}" ];then
    F_echo_and_do rm -rf "${tOutFile}"
    ret=$?
    [ ${ret} -ne 0 ] && exit 1
fi

tEndTm=$(date +%s)
tRunTm=$(echo "${tEndTm} - ${tBegineTm}"|bc) 
F_echo_and_do echo -e "\n\tElapsed time [\e[1;31m${tRunTm}\e[0m] seconds"

F_echo_and_do echo -e "\n\t exp data ok\n"
F_echo_and_do echo "======================================================================end:$(date +%Y-%m-%d_%H:%M:%S.%N)"
F_echo_and_do echo ""

exit 0

