#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20191112
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#   本脚本实现功能为:查看日志文件中某语句在一段时间内出现的的条数
#       如果一段时间内出现的数据条数超过配置值则Kill
#    
#    
#revision history:
#       fushikai@20191112@created@v0.0.0.1       
#
#############################################################################


#正式版debugFlag=0,调试时debugFlag=1
debugFlag=0

#软件版本号
versionNo="software version number: v0.0.0.1"

#加载系统环境变量配置
if [ -f /etc/profile ]; then
        . /etc/profile >/dev/null 2>&1
fi
if [ -f ~/.bash_profile ];then
        . ~/.bash_profile >/dev/null 2>&1
fi


#已经有脚本在运行则退出
tmpShPid=$(pidof -x $0)
tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
if [ ${tmpShPNum} -gt 1 ]; then
    exit 0
fi


baseDir=$(dirname $0)
logFNDate="$(date '+%Y%m%d')"
logDir="${baseDir}/log"
if [ ! -d "${logDir}" ];then
        mkdir -p "${logDir}"
fi

allPathName="$0"
shName="${allPathName##*/}"
#shName=$(getFnameOnPath $0)
preShName="${shName%.*}"
logFile="${logDir}/${preShName}${logFNDate}.log"
logDebugFile="${logDir}/${preShName}_debug.log"
versionFile="${baseDir}/version_${preShName}.txt"
#pName="ftmptest.sh"
pName="CommSubsystem"

#waitFlag是否等待杀死的进程重启,0:不等等,1:等待
waitFlag=1
#如果等待杀死的进程重启最多等待的时间（单位秒)
maxSeconds=300


#tdoFile="${baseDir}/scada.txt"
tdoFile="/zfmd/wpfs20/scada/trylog/apdu.txt"
tFixSec="60"  #查看日志多少秒的时间
tFixNum="35"   #查看在上面时间跨度内出现多少条语句
proStartFix="60" #要求进程必重启多长时间才查看

#tSearchTxt="popQ() CAN'T pop data from Queue, ErrorCode"
tSearchTxt='r::Buf 68 04 07 00 00 00'


#DSC:在日志文件中查找两个时间段之单出现异常语句的条数
#    开始和结束时间格式为19/08/04 15:23:59
function fndSenctNumInLog()
{
    local inFixNum=4
    if [ $# -ne ${inFixNum} ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "Error:function fndSenctNumInLog parameters not eq ${inFixNum}">>${logDebugFile}
        fi
        echo "Error:function fndSenctNumInLog parameters not eq ${inFixNum}"
        return 1
    fi
    local tdoFile="$1"
    local tBgTmStr="$2"
    local tEdTmStr="$3"
    local tSearTxt="$4"

    local tBgStr=$(echo "${tBgTmStr}"|sed 's|/|\\/|g')
    #local tEdStr=$(echo "${tEdTmStr}"|sed 's|/|\\/|g')

    if [ ! -e "${tdoFile}" ];then

        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "in function fndSenctNumInLog tdoFile not exits!">>${logDebugFile}
        fi
        echo "tdoFile not exits!"
        return 2
    fi

    

    local tnum=0
    #tnum=$(sed -n "/${tBgStr}/,/${tEdStr}/ {/${tSearTxt}/p}" ${tdoFile}|wc -l)
    tnum=$(sed -n "/${tBgStr}/,$ {/${tSearTxt}/p}" ${tdoFile}|wc -l)

    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "in function fndSenctNumInLog fusk test :tnum=[${tnum}],tBgStr[${tBgStr}],tEdStr=[${tEdStr}],tSearTxt=[${tSearTxt}],tdoFile=[${tdoFile}]">>${logDebugFile}
    fi

    echo "${tnum}"


    return 0
}




#获取pid对应的程序运行时长（单位秒）
function getPidElapsedSec()
{
    if [ $# -ne 1 ];then
        echo "Error:The number of input parameters of function getPidElapsedSec if not equal 1"
        return 1
    fi

    local tInPid=$1

    local tEtime=$(ps -p ${tInPid} -o etime|tail -1|awk '{print $NF}')
    if [ "${tEtime}" == "ELAPSED" ];then
        echo "Error:pid=[${tInPid}] does not exist!"
        return 9
    fi

    #echo "---tEtime=[${tEtime}]----"
    local tColonNum=$(echo "${tEtime}"|awk -F':' '{print NF}')

    #echo "----tColonNum=[${tColonNum}]----"
    if [ ${tColonNum} -eq 2 ];then

        local tMinute=$(echo "${tEtime}"|awk -F':' '{print $1}')
        local tSecond=$(echo "${tEtime}"|awk -F':' '{print $2}')
        local tSumSec=$(echo "(${tMinute} * 60 ) + ${tSecond}"|bc)

        #echo "---tMinute=[${tMinute}],tSecond=[${tSecond}]---"
        #echo "----tSumSec=[${tSumSec}]---tSumSec2=[${tSumSec2}]-----"

    elif [ ${tColonNum} -eq 3 ];then
        local tMinute=$(echo "${tEtime}"|awk -F':' '{print $2}')
        local tSecond=$(echo "${tEtime}"|awk -F':' '{print $3}')
        local tDHorH=$(echo "${tEtime}"|awk -F':' '{print $1}')
        local tBarNum=$(echo "${tDHorH}"|awk -F'-' '{print NF}')
        local tDay=0
        local tHour=0
        if [ ${tBarNum} -eq 1 ];then
            tDay=0
            tHour=${tDHorH}
        elif [ ${tBarNum} -eq 2 ];then
            tDay=$(echo "${tDHorH}"|awk -F'-' '{print $1}')
            tHour=$(echo "${tDHorH}"|awk -F'-' '{print $2}')
        else
            echo "Error1:[${tEtime}] format Error"
            return 2
        fi
        tSumSec=$(echo "(${tDay} * 86400) + (${tHour} * 3600) + (${tMinute} * 60 ) + ${tSecond}"|bc)

        #echo "--tDay=[${tDay}],tHour=[${tHour}]---tMinute=[${tMinute}],tSecond=[${tSecond}]---"
        #echo "----tSumSec=[${tSumSec}]---tSumSec2=[${tSumSec2}]-----"

    else
        echo "Error2:[${tEtime}] format Error"
        return 3
        
    fi

    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "in getPidElapsedSec:tSumSec=[${tSumSec}]">>${logDebugFile}
    fi

    echo "${tSumSec}"
    return 0

}



function writeLog()
{
    local timeFlag="$1"
    local shName="$2"
    local versionNo="$3"
    local pName="$4"

    if [[ ! -z "${timeFlag}" && ${timeFlag} -eq 3 ]];then

        local versionFile="$5"

        echo -e "\n\n*--------------------------------------------------\n*">${versionFile}
        echo -e "*\n*\t${versionNo}\n*">>${versionFile}
        echo -e "*\tshell script name: ${shName}\n*">>${versionFile}
        echo -e "*\tThe name of the program that the script will\n*\tprocess is: ${pName} \n*">>${versionFile}
        echo -e "*--------------------------------------------------\n">>${versionFile}
       return 0
    fi

    local logFile="$5"
    local outMsg="$6"

    if [ ! -e ${logFile} ];then
        echo -e "\n\n*--------------------------------------------------\n*">>${logFile}
        echo -e "*\n*\t${versionNo}\n*">>${logFile}
        echo -e "*\tshell script name: ${shName}\n*">>${logFile}
        echo -e "*\tThe name of the program that the script will\n*\tprocess is: ${pName} \n*">>${logFile}
        echo -e "*--------------------------------------------------\n">>${logFile}
    fi
    if [ ${timeFlag} -eq 1 ];then
        echo -e "`date +%Y/%m/%d-%H:%M:%S.%N`:${shName}:${outMsg}">>${logFile}
    else
        echo -e "${shName}:${outMsg}">>${logFile}
    fi
    return 0
}


function killProgram()
{
    local logFile="$1"
    local shName="$2"
    local versionNo="$3"
    local pName="$4"
    local maxSeconds="$5"
    local waitFlag="$6"

    local tPid=$(pidof -x ${pName})
    if [ "" = "$tPid" ];then
        writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}" "Program [${pName}] is not running\n"
        return 0
    fi

    kill ${tPid}
    local ret=$?
    writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} return[${ret}]\n"
    if [ ${ret} -ne 0 ];then
        kill -9 ${tPid}
        ret=$?
        if [ ${ret} -ne 0 ];then
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill -9 ${tPid} return[${ret}]\n"
        fi
    fi

    local tNewPid=$(pidof -x ${pName})
    local waitSeconds=0
    local tmpwait=30

    while [[ ! -z "${tNewPid}" && ${tNewPid} -eq ${tPid} ]]
    do
        sleep 1
        tNewPid=$(pidof -x ${pName})
        let waitSeconds++
        if [ ${waitSeconds} -gt ${tmpwait} ];then
            break
        fi
    done

    writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "waiting for program [${pName}] to exit, waitSeconds=[${waitSeconds}] \n"

    if [ ${waitSeconds} -gt ${tmpwait} ];then
            kill -9 ${tPid}
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} not success and use kill -9 ${tPid} \n"
    fi
 
    #不需要等待进程重启
    if [[ ${waitFlag} -eq 0 ]];then

        tNewPid=$(pidof -x ${pName}) 
        if [[  ! -z "${tNewPid}" && ${tNewPid} -eq ${tPid} ]];then
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} not success!\n"
            return 0
        else  
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} success!\n"
            return 2
        fi 
    fi

    tNewPid=$(pidof -x ${pName})
    waitSeconds=0
    while [[ -z "${tNewPid}" || ${tNewPid} -eq ${tPid} ]]
    do
        sleep 1
        tNewPid=$(pidof -x ${pName})
        let waitSeconds++
        #writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "oldPid=[${tPid}],newPid=[${tNewPid}],waitSeconds=[${waitSeconds}]\n"
        if [ ${waitSeconds} -gt ${maxSeconds} ];then
            break
        fi

    done

    writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "waiting for program [${pName}] to start, waitSeconds=[${waitSeconds}]\n"

    if [ ${waitSeconds} -gt ${maxSeconds} ];then
        if [[ ! -z ${tNewPid} && ${tNewPid} -eq ${tPid} ]];then
            kill -9 ${tPid}
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} not success and use kill -9 ${tPid}  ---22222 \n"
        else
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} success and  restart ${pName} not success!\n"
        fi
    else
        writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${pName} success and  restart ${pName} success,oldPid=[${tPid}],newPid=[${tNewPid}]\n"
    fi

    return 0
}

function myjudgeKill()
{
    local inFixNum=6
    if [ $# -ne ${inFixNum} ];then
        echo "Error:function myjudgeKill parameters not eq ${inFixNum}"
        return 1
    fi

    local tdoFile="$1"
    local tFixSec="$2"
    local tFixNum="$3"
    local tSearTxt="$4"
    local pName="$5"
    local proStartFix="$6"


    local tPid=$(pidof -x ${pName}) 

    #killFlag 1:代表需要kill,0:代表不需要kill
    local killFlag=0

    local retMsg
    local retStat

    [ -z "${tPid}" ] && echo ${killFlag} && return 0

    #获取pid对应的程序运行时长（单位秒）
    retMsg=$(getPidElapsedSec ${tPid})
    retStat=$?
    [ ${retStat} -ne 0 ] && echo ${retMsg} && return ${retStat}
    local prunSnds=${retMsg}

    if [[ ${prunSnds} -lt ${tFixSec} || ${prunSnds} -lt ${proStartFix} ]];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "in myjudgeKill: killFlag=[${killFlag}],prunSnds=[${prunSnds}],proStartFix=[${proStartFix}],tFixSec=[${tFixSec}]">>${logDebugFile}
        fi

        echo ${killFlag}

        return 0

    fi


    # 8h = 8 * 60 * 60 seconds
    local tUtcDfSec=28800
    
    local tCurSec=$(date +%s)
    tCurSec=$(echo "${tCurSec} + ${tUtcDfSec}"|bc)

    #local tEdSc=$(echo "${tCurSec} - 5"|bc)

    local tBgSc=$(echo "${tCurSec} - ${tFixSec}"|bc)

    local tBgTmStr=$(date -d "1970-01-01 ${tBgSc} seconds"  "+%y/%m/%d %H:%M:%S")
    #local tEdTmStr=$(date -d "1970-01-01 ${tEdSc} seconds"  "+%y/%m/%d %H:%M:%S")
    local tEdTmStr=" "

    local tBgStr=$(echo "${tBgTmStr}"|sed 's|/|\\/|g') 
    local tnum=0 
    tnum=$(sed -n "/${tBgStr}/,$ {/${tSearTxt}/p}" ${tdoFile}|wc -l)

    local tmpSecs=${tFixSec}
    if [ ${tnum} -lt 1 ];then
        for ((i=0;i<60;i++))
        do
            let tmpSecs++
            if [ ${tmpSecs} -gt ${prunSnds} ];then
                if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                    echo "in myjudgeKill: killFlag=[${killFlag}],prunSnds=[${prunSnds}],tmpSecs=[${tmpSecs}]">>${logDebugFile}
                fi
                echo ${killFlag}
                return 0
            fi
            tBgSc=$(echo "${tCurSec} - ${tmpSecs}"|bc)
            tBgTmStr=$(date -d "1970-01-01 ${tBgSc} seconds"  "+%y/%m/%d %H:%M:%S")  
            tBgStr=$(echo "${tBgTmStr}"|sed 's|/|\\/|g') 
            tnum=$(sed -n "/${tBgStr}/,$ {/${tSearTxt}/p}" ${tdoFile}|wc -l)
            if [ ${tnum} -gt 0 ];then
                break
            fi
        done
    fi

    if [ ${tnum} -lt 1 ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "in myjudgeKill: killFlag=[${killFlag}],prunSnds=[${prunSnds}],tmpSecs=[${tmpSecs}],tFixSec=[${tFixSec}]">>${logDebugFile}
        fi
        echo ${killFlag}
        return 0
    fi

    #在日志文件中查找两个时间段之单出现异常语句的条数
    #fndSenctNumInLog "${tdoFile}" "${tBgTmStr}" "${tEdTmStr}" "${tSearTxt}"
    retMsg=$(fndSenctNumInLog "${tdoFile}" "${tBgTmStr}" "${tEdTmStr}" "${tSearTxt}")
    retStat=$?
    #echo "fusk test retMsg=[${retMsg}],tBgTmStr=[${tBgTmStr}],tEdTmStr=[${tEdTmStr}]"
    #echo "fusk test--------retStat=[${retStat}]"
    if [ ${retStat} -eq 1 ];then
        echo ${retMsg}
        return ${retStat}
    elif [[ ${retStat} -ne 0 ]];then
        echo "${killFlag}"
        return 0
    fi

    local tFdNum=${retMsg}



    if [[ ${prunSnds} -gt ${proStartFix} && ${tFdNum} -gt ${tFixNum} ]];then
       #killFlag 1:代表需要kill,0:代表不需要kill
       killFlag=1
    fi 


    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "in myjudgeKill: killFlag=[${killFlag}]">>${logDebugFile}
    fi

    echo ${killFlag}

    return 0
}


wtLogFlag=1                                                
if [ -e "${versionFile}" ];then                            
    tvNum=$(sed -n "/${versionNo}/p" ${versionFile}|wc -l) 
    if [ ${tvNum} -gt 0 ];then                             
        wtLogFlag=0                                        
    fi                                                     
fi                                                         
[ ${wtLogFlag} -eq 1 ] && writeLog 3 "${shName}" "${versionNo}" "${pName}" "${versionFile}" "write versionNo"     

tPid=$(pidof -x ${pName})                                                                                                                                     
[ -z "${tPid}" ] && exit 9 

retMsg=$(myjudgeKill "${tdoFile}" "${tFixSec}" "${tFixNum}" "${tSearchTxt}" "${pName}" "${proStartFix}")
retStat=$?
if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
    echo "fusk test retStat=[${retStat}],retMsg=[${retMsg}]">>${logDebugFile}
fi
if [ ${retStat} -eq 0 ];then
    if [[ ! -z "${retMsg}" && ${retMsg} -eq 1 ]];then
        retMsg=$(killProgram "${logFile}" "${shName}" "${versionNo}" "${pName}" "${maxSeconds}" "${waitFlag}")
        retStat=$?
    fi
fi


exit 0


