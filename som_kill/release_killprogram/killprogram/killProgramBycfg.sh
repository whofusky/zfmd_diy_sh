#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20190818
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    根据与脚本同级目录下下的配置文件killByxxcfg.cfg的配置对程序进行kill
#    
#    
#       

#    
#revision history:
#       fushikai@20190818@crated@v0.0.0.1
#       
#      
#     
#       
#
#############################################################################

#软件版本号
versionNo="software version number: v0.0.0.5"

#正式版debugFlag=0,调试时debugFlag=1
debugFlag=1


#加载系统环境变量配置
if [ -f /etc/profile ]; then
    . /etc/profile >/dev/null 2>&1
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile >/dev/null 2>&1
fi

baseDir=$(dirname $0)

#fncFName=diyFuncBysky.func
#fncFile="${baseDir}/someFunc/${fncFName}"
#
#
#if [ ! -e "${fncFile}" ];then
#    for ((i=0;i<5;i++)) 
#    do
#        #echo "-----$i"
#        addParent=${addParent}../
#        findPrName="${baseDir}/${addParent}"
#        tfNum=$(find "${findPrName}" -name "${fncFName}" -type f -print|wc -l)
#        if [ ${tfNum} -eq 1 ];then
#            fncFile=$(find "${findPrName}" -name "${fncFName}" -type f -print)
#            break
#        fi
#    done
#    if [ ${tfNum} -ne 1 ];then
#       echo ""
#       echo "eror: [${fncFName}] file does not exist"
#       echo ""
#       exit 3
#    fi
#fi
#
#if [ ! -x "${fncFile}" ];then
#   chmod u+x "${fncFile}"
#   echo -e "\nchmod u+x ${fncFile}\n"
##fi
#
#
##Load shell function file
#. ${fncFile}


logFNDate="$(date '+%Y%m%d')"
logDir="${baseDir}/log"
if [ ! -d "${logDir}" ];then
    mkdir -p "${logDir}"
fi


begineStr="start running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"

inShName="$0"
shName="${inShName##*/}"
preShName="${shName%.*}"
logFile="${logDir}/${preShName}${logFNDate}.log"
logDebugFile="${logDir}/${preShName}_debug.log"
versionFile="${baseDir}/version_${preShName}.txt"




function convertVLineToSpace() #Convert vertical lines to spaces
{

    if [ $# -lt 1 ];then
        echo ""
        return 0
    fi

    echo $(echo "$1"|tr -d "[\040\t\r\n]"|tr -s "|" "\040")
    return 0
}


function F_writeLog()
{
    local fixInNum=3
    local thshName="F_writeLog"
    if [ $# -lt ${fixInNum} ];then
        echo -e "Error:function ${thshName} parameters less than ${fixInNum}\n"
        return 1
    fi

    local timeFlag="$1"
    local shName="$2"
    local versionNo="$3"

    if [[ ! -z "${timeFlag}" && ${timeFlag} -eq 3 ]];then

        if [ $# -lt 4 ];then
            if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                echo -e "\nERROR:function ${thshName} input parameters not less 4!\n">>${logDebugFile}
            fi
            echo -e "\nERROR:function ${thshName} input parameters not less 4!\n"
            return 1
        fi
        local versionFile="$4"

        echo -e "\n\n*--------------------------------------------------\n*">${versionFile}
        echo -e "*\n*\t${versionNo}\n*">>${versionFile}
        echo -e "*\tshell script name: ${shName}\n*">>${versionFile}
        echo -e "*--------------------------------------------------\n">>${versionFile}
       return 0
    fi

    if [ $# -lt 6 ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo -e "\nERROR:function ${thshName} input parameters not less 6!\n">>${logDebugFile}
        fi
        echo -e "\nERROR:function ${thshName} input parameters not less 6!\n"
        return 1
    fi
    local pName="$4"
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


#已经有脚本在运行则退出
tmpShPid=$(pidof -x $0)
tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
if [ ${tmpShPNum} -gt 1 ]; then
    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "shName=[${shName}] versionNo=[${versionNo}] logFile=[${logFile}] +++tmpShPid=[${tmpShPid}]+++++tmpShPNum=[${tmpShPNum}]+++">>${logDebugFile}
        echo "script [$0] has been running,this run directly exits!">>${logDebugFile}
    fi
    F_writeLog 0 "${shName}" "${versionNo}" "null" "${logFile}" "+++${tmpShPid}+++++${tmpShPNum}+++"
    F_writeLog 1 "${shName}" "${versionNo}" "null" "${logFile}" "script [$0] has been running,this run directly exits!"
    exit 0
fi



wtLogFlag=1
if [ -e "${versionFile}" ];then
    tvNum=$(sed -n "/${versionNo}/p" ${versionFile}|wc -l)
    if [ ${tvNum} -gt 0 ];then
        wtLogFlag=0
    fi
fi
[ ${wtLogFlag} -eq 1 ] && F_writeLog 3 "${shName}" "${versionNo}" "${versionFile}" "write versionNo"     



#判断文件的修改时间是否早于xxx秒之前，返回值：1为早于，0为不早于
function F_getIsModBeger() #判断文件的修改时间是否早于xxx秒之前，返回值：1为早于，0为不早于
{
    local fixInNum=2
    local thshName="F_getIsModBeger"
    if [ $# -ne ${fixInNum} ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "  Error: function ${thshName} input parameters not eq ${fixInNum}!">>${logDebugFile}
        fi
        echo "  Error: function ${thshName} input parameters not eq ${fixInNum}!"
        return 1
    fi

    local tmpFile=$1
    local maxCfgSecs=$2

    if [ ! -e ${tmpFile} ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo " Error: function ${thshName}:file[${tmpFile}] does not exist!">>${logDebugFile}
        fi
        echo " Error: function ${thshName}:file[${tmpFile}] does not exist!"
        return 2
    fi
    local tSecNum=$(echo "($(date +%s)-$(stat -c %Y ${tmpFile}))"|bc)
    local tIsBig=$(echo "${tSecNum}>=${maxCfgSecs}"|bc)

    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "in function ${thshName} tIsBig=[${tIsBig}]">>${logDebugFile}
    fi

    echo "${tIsBig}"
    return 0

}



#获取pid对应的程序运行时长（单位秒）
function F_getPidElapsedSec() #获取pid对应的程序运行时长（单位秒）
{
    local fixInNum=1
    local thshName="F_getPidElapsedSec"
    if [ $# -ne ${fixInNum} ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "Error:The number of input parameters of function ${thshName} if not equal ${fixInNum}">>${logDebugFile}
        fi
        echo "Error:The number of input parameters of function ${thshName} if not equal ${fixInNum}"
        return 1
    fi

    local tInPid=$1

    local tMinute=0
    local tSecond=0
    local tDHorH=0
    local tBarNum=0
    local tDay=0
    local tHour=0
    local tSumSec=0

    local tEtime=$(ps -p ${tInPid} -o etime|tail -1|awk '{print $NF}')
    if [ "${tEtime}" == "ELAPSED" ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "Error:in function ${thshName} pid=[${tInPid}] does not exist!">>${logDebugFile}
        fi
        echo "Error:pid=[${tInPid}] does not exist!"
        return 9
    fi

    #echo "---tEtime=[${tEtime}]----"
    local tColonNum=$(echo "${tEtime}"|awk -F':' '{print NF}')

    #echo "----tColonNum=[${tColonNum}]----"
    if [ ${tColonNum} -eq 2 ];then

        tMinute=$(echo "${tEtime}"|awk -F':' '{print $1}')
        tSecond=$(echo "${tEtime}"|awk -F':' '{print $2}')
        tSumSec=$(echo "(${tMinute} * 60 ) + ${tSecond}"|bc)

        #echo "---tMinute=[${tMinute}],tSecond=[${tSecond}]---"
        #echo "----tSumSec=[${tSumSec}]---tSumSec2=[${tSumSec2}]-----"

    elif [ ${tColonNum} -eq 3 ];then
        tMinute=$(echo "${tEtime}"|awk -F':' '{print $2}')
        tSecond=$(echo "${tEtime}"|awk -F':' '{print $3}')
        tDHorH=$(echo "${tEtime}"|awk -F':' '{print $1}')
        tBarNum=$(echo "${tDHorH}"|awk -F'-' '{print NF}')
        tDay=0
        tHour=0
        if [ ${tBarNum} -eq 1 ];then
            tDay=0
            tHour=${tDHorH}
        elif [ ${tBarNum} -eq 2 ];then
            tDay=$(echo "${tDHorH}"|awk -F'-' '{print $1}')
            tHour=$(echo "${tDHorH}"|awk -F'-' '{print $2}')
        else
            if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                echo "Error1:in function ${thshName} [${tEtime}] format Error">>${logDebugFile}
            fi
            echo "Error1:[${tEtime}] format Error"
            return 2
        fi
        tSumSec=$(echo "(${tDay} * 86400) + (${tHour} * 3600) + (${tMinute} * 60 ) + ${tSecond}"|bc)

        #echo "--tDay=[${tDay}],tHour=[${tHour}]---tMinute=[${tMinute}],tSecond=[${tSecond}]---"
        #echo "----tSumSec=[${tSumSec}]---tSumSec2=[${tSumSec2}]-----"

    else
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "Error2:in function ${thshName} [${tEtime}] format Error">>${logDebugFile}
        fi
        echo "Error2:[${tEtime}] format Error"
        return 3
        
    fi

    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "in function ${thshName} tSumSec=[${tSumSec}]">>${logDebugFile}
    fi

    echo "${tSumSec}"
    return 0

}


#DSC:找到某个字符串在某个文件中是否出现，如果出现则把出现字符串前的
#    19/08/04 15:23:59:161.617:CST]时间解析与1970-01-01的秒数返回
function F_fndRecntStmpByfixStr() #DSC:找到某个字符串在某个文件中是否出现，如果出现则把出现字符串前的19/08/04 15:23:59:161.617:CST]时间解析与1970-01-01的秒数返回
{
    local fixInNum=3
    local thshName="F_fndRecntStmpByfixStr"
    if [ $# -ne ${fixInNum} ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "Error:function ${thshName} parameters not eq ${fixInNum}">>${logDebugFile}
        fi
        echo "Error:function ${thshName} parameters not eq ${fixInNum}"
        return 1
    fi
    local tdoFile="$1"
    local tMaxLinNum="$2"
    local tSearchTxt="$3"

    if [ ! -e "${tdoFile}" ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "in function ${thshName} tdoFile=[${tdoFile}] not exits!">>${logDebugFile}
        fi
        echo "tdoFile not exits!"
        return 2
    fi

    local tFindTxt=$(tail -"${tMaxLinNum}" "${tdoFile}"|sed -n "/${tSearchTxt}/p" |tail -1)

    if [ -z "${tFindTxt}" ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "in function ${thshName} tFindTxt is null">>${logDebugFile}
        fi
        echo "tFindTxt is null"
        return 2
    fi

    local tFixTime=$(echo "${tFindTxt}"|awk -F']' '{if(NF>=2){print $1}}'|awk -F'[/:]' '{print $1"-"$2"-"$3":"$4":"$5}')
    if [ -z "${tFixTime}" ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "in function ${thshName} tFixTime is null">>${logDebugFile}
        fi
        echo "tFixTime is null"
        return 3
    fi

    local tFixTmstamp=$(date -d "${tFixTime}" +%s)
    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "in function ${thshName} tFixTmstamp=[${tFixTmstamp}]">>${logDebugFile}
    fi
    echo "${tFixTmstamp}"

    return 0
}



#judge kill by  fix sentence apear afer process start
function F_judgeKillByFSAPS() #Determine whether a specific statement appears after the process is started and whether a kill is required
{
    local fixInNum=4
    local thshName="F_judgeKillByFSAPS"
    if [ $# -ne ${fixInNum} ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "Error:fuction ${thshName} input parameters not eq ${fixInNum}">>${logDebugFile}
        fi
        echo "Error:fuction ${thshName} input parameters not eq ${fixInNum}"
        return 1
    fi
        
    local tdoFile="$1"
    local tMaxLinNum="$2"
    local tSearchTxt="$3"
    local pName="$4"

    local tPid=$(pidof -x ${pName}) 

    #killFlag 1:代表需要kill,0:代表不需要kill
    local killFlag=0

    local retMsg
    local retStat

    [ -z "${tPid}" ] && echo ${killFlag} && return 0

    #获取特定字样出现的时间
    #fndTmStmpByStrInFl "${tdoFile}" "${tMaxLinNum}" "${tSearchTxt}"
    retMsg=$(F_fndRecntStmpByfixStr "${tdoFile}" "${tMaxLinNum}" "${tSearchTxt}")
    retStat=$?
    #echo "--------retStat=[${retStat}]"
    if [ ${retStat} -eq 1 ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "in function ${thshName} [${retMsg}]">>${logDebugFile}
        fi
        echo ${retMsg}
        return 1
    elif [[ ${retStat} -eq 2 || ${retStat} -eq 3 ]];then
        echo "${killFlag}"
        return 0
    fi


    local ftmstmp=${retMsg}

    #获取pid对应的程序运行时长（单位秒）
    retMsg=$(F_getPidElapsedSec ${tPid})
    retStat=$?
    [ ${retStat} -ne 0 ] && echo ${retMsg} && return ${retStat}
    local prunSnds=${retMsg}

    local curTmStmp=$(date +%s)

    #killFlag 1:代表需要kill,0:代表不需要kill
    killFlag=$(echo "${curTmStmp} - ${prunSnds} < ${ftmstmp}"|bc)

    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "in function ${thshName} killFlag=[${killFlag}]">>${logDebugFile}
    fi

    echo ${killFlag}
    return 0
}



function F_killProgram() # $0 $pName $maxSeconds 
{
    #inpara:
    # 1 pName
    # 2 maxSeconds

    local fixInNum=2
    local thshName="F_killProgram"
    if [ $# -ne ${fixInNum} ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo -e "Error:function ${thshName} not eq ${fixInNum}\n">>${logDebugFile}
        fi
        echo -e "Error:function ${thshName} not eq ${fixInNum}\n"
        return 1
    fi

    #local logFile="$1"
    #local shName="$2"
    #local versionNo="$3"
    local pName="$1"
    local maxSeconds="$2"

    local waitFlag=0

    tcheck=$(echo "${maxSeconds}"|sed -n "/^[0-9][0-9]*$/p"|wc -l) 
    [ ${tcheck} -eq 0 ] && maxSeconds=5     

    [ ${maxSeconds} -gt 0 ] && waitFlag=1


    local tPid=$(pidof -x ${pName})
    if [ "" = "$tPid" ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo -e "in function ${thshName} Program [${pName}] is not running\n">>${logDebugFile}
        fi
        echo -e "Program [${pName}] is not running\n"
        return 0
    fi

    kill ${tPid}
    local ret=$?
    echo -e  "kill ${tPid} return[${ret}]\n"
    if [ ${ret} -ne 0 ];then
        kill -9 ${tPid}
        ret=$?
        if [ ${ret} -ne 0 ];then
            if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                echo -e  "in function ${thshName} kill -9 ${tPid} return[${ret}]\n">>${logDebugFile}
            fi
            echo -e  "kill -9 ${tPid} return[${ret}]\n"
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

    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo -e  "in function ${thshName} waiting for program [${pName}] to exit, waitSeconds=[${waitSeconds}] \n">>${logDebugFile}
    fi
    echo -e  "waiting for program [${pName}] to exit, waitSeconds=[${waitSeconds}] \n"

    if [ ${waitSeconds} -gt ${tmpwait} ];then
        kill -9 ${tPid}
        echo -e  "kill ${tPid} not success and use kill -9 ${tPid} \n"
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo -e  "in function ${thshName} kill ${tPid} not success and use kill -9 ${tPid} \n">>${logDebugFile}
        fi
    fi
 
    #不需要等待进程重启
    if [[ ${waitFlag} -eq 0 ]];then

        tNewPid=$(pidof -x ${pName}) 
        if [[  ! -z "${tNewPid}" && ${tNewPid} -eq ${tPid} ]];then
            echo -e  "kill ${tPid} not success!\n"
            if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                echo -e  "in function ${thshName} kill ${tPid} not success!\n">>${logDebugFile}
            fi
            return 0
        else  
            if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                echo -e  "in function ${thshName} kill ${tPid} success!\n">>${logDebugFile}
            fi
            echo -e  "kill ${tPid} success!\n"
            return 2
        fi 
    fi

    tNewPid=$(pidof -x ${pName})
    waitSeconds=0
    while [[  -z "${tNewPid}" || ${tNewPid} -eq ${tPid} ]]
    do
        sleep 1
        tNewPid=$(pidof -x ${pName})
        let waitSeconds++
        #echo -e  "oldPid=[${tPid}],newPid=[${tNewPid}],waitSeconds=[${waitSeconds}]\n"
        if [ ${waitSeconds} -gt ${maxSeconds} ];then
            break
        fi

    done

    echo -e  "waiting for program [${pName}] to start, waitSeconds=[${waitSeconds}]\n"
    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo -e  "in function ${thshName} waiting for program [${pName}] to start, waitSeconds=[${waitSeconds}]\n">>${logDebugFile}
    fi

    if [ ${waitSeconds} -gt ${maxSeconds} ];then
        if [[ ! -z ${tNewPid} && ${tNewPid} -eq ${tPid} ]];then
            kill -9 ${tPid}
            echo -e  "kill ${tPid} not success and use kill -9 ${tPid}  ---22222 \n"
            if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                echo -e  "in function ${thshName} kill ${tPid} not success and use kill -9 ${tPid}  ---22222 \n">>${logDebugFile}
            fi
        else
            if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                echo -e  "in function ${thshName} kill ${tPid} success and  restart ${pName} not success!\n">>${logDebugFile}
            fi
            echo -e  "kill ${tPid} success and  restart ${pName} not success!\n"
        fi
    else
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo -e  "in function ${thshName} kill ${pName} success and  restart ${pName} success,oldPid=[${tPid}],newPid=[${tNewPid}]\n">>${logDebugFile}
        fi
        echo -e  "kill ${pName} success and  restart ${pName} success,oldPid=[${tPid}],newPid=[${tNewPid}]\n"
    fi

    return 0
}



#DSC:在日志文件中查找两个时间段之单出现异常语句的条数
#    开始和结束时间格式为19/08/04 15:23:59
function F_fndSenctNumInLog()
{
    local fixInNum=4
    local thshName="F_fndSenctNumInLog"
    if [ $# -ne ${fixInNum} ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "Error:function ${thshName} parameters not eq ${fixInNum}">>${logDebugFile}
        fi
        echo "Error:function ${thshName} parameters not eq ${fixInNum}"
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
            echo "in function ${thshName} tdoFile not exits!">>${logDebugFile}
        fi
        echo "tdoFile not exits!"
        return 2
    fi

    

    local tnum=0
    #tnum=$(sed -n "/${tBgStr}/,/${tEdStr}/ {/${tSearTxt}/p}" ${tdoFile}|wc -l)
    tnum=$(sed -n "/${tBgStr}/,$ {/${tSearTxt}/p}" ${tdoFile}|awk -F'|' '{print $NF}'|sort|uniq -c|sort -n -k1|tail -1|awk '{print $1}')
    [ -z "${tnum}" ] && tnum=0

    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "in function ${thshName} fusk test :tnum=[${tnum}],tBgStr[${tBgStr}],tEdStr=[${tEdStr}],tSearTxt=[${tSearTxt}],tdoFile=[${tdoFile}]">>${logDebugFile}
    fi

    echo "${tnum}"


    return 0
}



#judge kill bye fix sentence number apear after process start
function F_judgeKillByFSNAPS() # Determine whether the number of occurrences of a specific statement in a certain period of time after the process is started needs to be killed
{
    local fixInNum=6
    local thshName="F_judgeKillByFSNAPS"
    if [ $# -ne ${fixInNum} ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "Error:function ${thshName} parameters not eq ${fixInNum}">>${logDebugFile}
        fi
        echo "Error:function ${thshName} parameters not eq ${fixInNum}"
        return 1
    fi

    local tdoFile="$1"
    local tFixSec="$2"
    local tFixNum="$3"
    local tSearTxt="$4"
    local pName="$5"
    local proStartFix="$6"

    if [ ! -e "${tdoFile}" ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "Error:function ${thshName} tdoFile=[${tdoFile}] not exist!">>${logDebugFile}
        fi
        echo "Error:function ${thshName}  tdoFile=[${tdoFile}] not exist!"
        return 1
    fi



    local tPid=$(pidof -x ${pName}) 

    #killFlag 1:代表需要kill,0:代表不需要kill
    local killFlag=0

    local retMsg
    local retStat

    [ -z "${tPid}" ] && echo ${killFlag} && return 0

    #获取pid对应的程序运行时长（单位秒）
    retMsg=$(F_getPidElapsedSec ${tPid})
    retStat=$?
    [ ${retStat} -ne 0 ] && echo ${retMsg} && return ${retStat}
    local prunSnds=${retMsg}

    if [[ ${prunSnds} -lt ${tFixSec} || ${prunSnds} -lt ${proStartFix} ]];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "in ${thshName}: killFlag=[${killFlag}],prunSnds=[${prunSnds}],proStartFix=[${proStartFix}],tFixSec=[${tFixSec}]">>${logDebugFile}
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
    

    local tTunTm=30
    #为了在日志中找到开始时间近似的时间点进行定位，对时间进行前后微调,最大微调${tTunTm}秒
    local tPreSecs=${tFixSec}
    local tAfterSecs=${tFixSec}
    local i


    if [ ${tnum} -lt 1 ];then
        for ((i=0;i<${tTunTm};i++))
        do
            let tAfterSecs--
            tBgSc=$(echo "${tCurSec} - ${tAfterSecs}"|bc)
            tBgTmStr=$(date -d "1970-01-01 ${tBgSc} seconds"  "+%y/%m/%d %H:%M:%S")  
            tBgStr=$(echo "${tBgTmStr}"|sed 's|/|\\/|g') 
            tnum=$(sed -n "/${tBgStr}/,$ {/${tSearTxt}/p}" ${tdoFile}|wc -l)
            if [ ${tnum} -gt 0 ];then
                break
            fi

            let tPreSecs++
            #如果微调的时间跨度超过了程序启动后运行的时间则放弃微调
            if [ ${tPreSecs} -gt ${prunSnds} ];then
                if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                    echo "in ${thshName}: killFlag=[${killFlag}],prunSnds=[${prunSnds}],tPreSecs=[${tPreSecs}],tAfterSecs=[${tAfterSecs}]">>${logDebugFile}
                fi
                echo ${killFlag}
                return 0
            fi
            tBgSc=$(echo "${tCurSec} - ${tPreSecs}"|bc)
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
            echo "in ${thshName}: killFlag=[${killFlag}],prunSnds=[${prunSnds}],tPreSecs=[${tPreSecs}],tFixSec=[${tFixSec}],tAfterSecs=[${tAfterSecs}]">>${logDebugFile}
        fi
        echo ${killFlag}
        return 0
    fi

    #在日志文件中查找两个时间段之单出现异常语句的条数
    #F_fndSenctNumInLog "${tdoFile}" "${tBgTmStr}" "${tEdTmStr}" "${tSearTxt}"
    retMsg=$(F_fndSenctNumInLog "${tdoFile}" "${tBgTmStr}" "${tEdTmStr}" "${tSearTxt}")
    retStat=$?
    if [ ${retStat} -eq 1 ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "in function ${thshName} [${retMsg}]">>${logDebugFile}
        fi
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
        echo "in ${thshName}: killFlag=[${killFlag}]">>${logDebugFile}
    fi

    echo ${killFlag}

    return 0
}




function F_killOnePFunc()
{
    local fixInNum=9
    local thshName="F_killOnePFunc"
    if [ $# -ne ${fixInNum} ];then
        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo -e "Error:function ${thshName} not eq ${fixInNum}\n">>${logDebugFile}
        fi
        echo -e "Error:function ${thshName} not eq ${fixInNum}\n"
        return 1
    fi

    local pName="$1"
    local tPid
    tPid=$(pidof -x ${pName}) 
    [ -z "${tPid}" ] && return 0

    local logdir="$2"
    local wtstMaxtm="$3"
    local toJudgeOth="$4"
    local toJudgeIf="$5"
    local tchoiceTy="$6"
    local tjgType="$7"
    local tPidRtm="$8"
    local toJudgeObj=($9)

    local toJugeNum=${#toJudgeObj[*]}



    local logFile=""
    logFile="${logdir}/${pName}_kill_${logFNDate}.log"

    local begineStr="start running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"


    local retMsg=""
    local ret=0
    local isOverFlag=1
    local tEtimeStr=""
    local tDoFile=""
    local killFlag=0

    [ -z "${tPidRtm}" ] && tPidRtm=0


    if [ ${tPidRtm} -gt 0 ];then
        tPid=$(pidof -x ${pName}) 
        [ -z "${tPid}" ] && return 9
        retMsg=$(F_getPidElapsedSec ${tPid})
        ret=$?
        if [ ${ret} -eq 0 ];then
            isOverFlag=$(echo "${tPidRtm}<=${retMsg}"|bc)
            tEtimeStr="--tPidRtm=[${tPidRtm}],pidof ${pName}=[${tPid}],elapsed time[${retMsg}] seconds"
            if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                echo "in function ${thshName} ${tEtimeStr}">>${logDebugFile}
            fi
        else
            F_writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "${retMsg}"
            if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                echo "in function ${thshName} retMsg=[${retMsg}]">>${logDebugFile}
            fi
        fi
    fi

    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "in function ${thshName} isOverFlag=[${isOverFlag}],toJugeNum=[${toJugeNum}]">>${logDebugFile}
    fi

    if [ ${isOverFlag} -ne 1 ];then
        killFlag=0
        return 0
    fi


    local tFixSec
    local tFixNum
    local tNum
    local i
    for ((i=0;i<${toJugeNum};i++))
    do
        tDoFile=${toJudgeObj[${i}]}
        if [ ! -e "${tDoFile}" ];then
            continue
        fi

        if [[ "${tjgType}" == "${jd_by_last_md_time}" ]];then
            retMsg=$(F_getIsModBeger ${tDoFile} ${toJudgeIf})
            ret=$? 
            if [ ${ret} -ne 0 ];then
                F_writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "F_getIsModBeger return error:[${retMsg}]\n"
                if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                    echo "in function ${thshName} F_getIsModBeger return error:[${retMsg}]">>${logDebugFile}
                fi
                continue
            fi
            if [[ ${retMsg} -eq 1 ]];then
                killFlag=1
                break
            fi
        elif [[ "${tjgType}" == "${jd_by_appear_snt}" ]];then
            retMsg=$(F_judgeKillByFSAPS "${tDoFile}" "${toJudgeOth}" "${toJudgeIf}" "${pName}")
            ret=$? 
            if [ ${ret} -eq 0 ];then
                if [[ ! -z "${retMsg}" && ${retMsg} -eq 1 ]];then
                    killFlag=1
                    break;
                fi
            fi
        elif [[ "${tjgType}" == "${jd_by_appear_xsnt}" ]];then
            tNum=$(echo "${toJudgeOth}"|awk -F'|' '{print NF}')
            if [ ${tNum} -ne 2 ];then
                F_writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "tjgType=[${tjgType}],toJudgeOth=[${toJudgeOth}] format error"
                if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                    echo "in function ${thshName} tjgType=[${tjgType}],toJudgeOth=[${toJudgeOth}] format error">>${logDebugFile}
                fi
                killFlag=0
                break
            fi
            tFixSec=$(echo "${toJudgeOth}"|awk -F'|' '{print $1}')
            tFixNum=$(echo "${toJudgeOth}"|awk -F'|' '{print $2}')

            retMsg=$(F_judgeKillByFSNAPS "${tDoFile}" "${tFixSec}" "${tFixNum}" "${toJudgeIf}" "${pName}" "${tPidRtm}")
            ret=$? 
            if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                echo "in function ${thshName} call F_judgeKillByFSNAPS  ret=[${ret}],retMsg=[${retMsg}]">>${logDebugFile}
            fi
            if [ ${ret} -eq 0 ];then
                if [[ ! -z "${retMsg}" && ${retMsg} -eq 1 ]];then
                    killFlag=1
                    break;
                    #retMsg=$(killProgram "${logFile}" "${shName}" "${versionNo}" "${pName}" "${maxSeconds}" "${waitFlag}")
                    #ret=$?
                fi
            fi

        else
            if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
                echo "in function ${thshName}:ERROR tjgType=[${tjgType}] does not recognize">>${logDebugFile}
            fi
        fi

    done

    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "in function ${thshName} killFlag=[${killFlag}]">>${logDebugFile}
    fi

    #echo "killFlag=[${killFlag}]"
    #kill 程序
    if [[ ! -z "${killFlag}" && ${killFlag} -eq 1 ]];then
        retMsg=$(F_killProgram ${pName} ${wtstMaxtm} )
        ret=$?
        local endStr="End running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"
        F_writeLog 0 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "${begineStr}"
        F_writeLog 0 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "${endStr}"
        F_writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "${tEtimeStr}"
        F_writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "${retMsg}"

        if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
            echo "in function ${thshName}:${begineStr}">>${logDebugFile}
            echo "in function ${thshName}:${endStr}">>${logDebugFile}
            echo "in function ${thshName}:${tEtimeStr}">>${logDebugFile}
            echo "in function ${thshName}:${retMsg}">>${logDebugFile}
        fi
        return 9

    fi

    return 0
}


cfgName="${baseDir}/killByxxcfg.cfg"
if [ ! -e "${cfgName}" ];then
    F_writeLog 1 "${shName}" "${versionNo}" "${pName[*]}" "${logFile}"  "ERROR: cfg file [${cfgName}] not exits!\n"
    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "ERROR: cfg file [${cfgName}] not exits!\n">>${logDebugFile}
    fi
    exit 1
fi

#对配置文件的等号两边进行去空格处理使其配置最大限度的不出错（即增加配置文件格式的兼容性）
tnum=$(sed -n '/\s\+=/p' ${cfgName}|wc -l)
if [ ${tnum} -gt 0 ];then
    sed -i 's/\s\+=/=/g' ${cfgName}
fi
tnum=$(sed -n '/=\s\+/p' ${cfgName}|wc -l)
if [ ${tnum} -gt 0 ];then
    sed -i 's/=\s\+/=/g' ${cfgName}
fi

. ${cfgName}

pNum=${#pName[*]}
if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
    echo -e "\n`date +%Y/%m/%d-%H:%M:%S.%N`:pNum=[${pNum}]">>${logDebugFile}
fi

if [ ${pNum} -lt 1 ];then
    exit 0
fi

ttNum[0]="${#toJudgeIf[*]}"
ttNum[1]="${#toJudgeOth[*]}"
ttNum[2]="${#toChoiceType[*]}"
ttNum[3]="${#toJudgeObj[*]}"
ttNum[4]="${#waitStartMaxSeconds[*]}"
ttNum[5]="${#logdir[*]}"
ttNum[6]="${#toJudeType[*]}"
ttNum[7]="${#toPidRTmBeJudge[*]}"

tts="${#ttNum[*]}"

if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
    echo "`date +%Y/%m/%d-%H:%M:%S.%N`:tts=[${tts}]">>${logDebugFile}
fi

for ((i=0;i<${tts};i++))
do
    
    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        if [ $i -eq 0 ];then
            echo -e "\n--------------------`date +%Y/%m/%d-%H:%M:%S.%N`:--------------------">>${logDebugFile}
        fi
        echo "i=[$i],pNum=[${pNum}],ttNum[$i]=[${ttNum[$i]}]">>${logDebugFile}
    fi

    if [[ ${pNum} -ne ${ttNum[$i]} ]];then
       F_writeLog 1 "${shName}" "${versionNo}" "${pName[*]}" "${logFile}"  "\ncfg file format error!!\n"
      exit 1
    fi

done



outFlag=0
outMsg="  do process is:"

for ((idxP=0;idxP<${pNum};idxP++))
do

    tpName="${pName[${idxP}]}"
    tjgType="${toJudeType[${idxP}]}"
    tjgIf="${toJudgeIf[${idxP}]}"
    tjdOther="${toJudgeOth[${idxP}]}"
    tchoiceTy="${toChoiceType[${idxP}]}"
    tmpjdObj="${toJudgeObj[${idxP}]}"
    twtstmxsc="${waitStartMaxSeconds[${idxP}]}"
    tlogdir="${logdir[${idxP}]}"
    tPidRtm="${toPidRTmBeJudge[${idxP}]}"


    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo -e "\n\n">>${logDebugFile}
        echo "-------------------------`date +%Y/%m/%d-%H:%M:%S.%N`------------------------------">>${logDebugFile}
        echo "idx=[${idxP}],pNum=[${pNum}]:tpName=[${tpName}]">>${logDebugFile}
        echo "idx=[${idxP}],pNum=[${pNum}]:tjgType=[${tjgType}]">>${logDebugFile}
        echo "idx=[${idxP}],pNum=[${pNum}]:tjgIf=[${tjgIf}]">>${logDebugFile}
        echo "idx=[${idxP}],pNum=[${pNum}]:tjdOther=[${tjdOther}]">>${logDebugFile}
        echo "idx=[${idxP}],pNum=[${pNum}]:tchoiceTy=[${tchoiceTy}]">>${logDebugFile}
        echo "idx=[${idxP}],pNum=[${pNum}]:tmpjdObj=[${tmpjdObj}]">>${logDebugFile}
        echo "idx=[${idxP}],pNum=[${pNum}]:twtstmxsc=[${twtstmxsc}]">>${logDebugFile}
        echo "idx=[${idxP}],pNum=[${pNum}]:tlogdir=[${tlogdir}]">>${logDebugFile}
        echo "idx=[${idxP}],pNum=[${pNum}]:tPidRtm=[${tPidRtm}]">>${logDebugFile}
    fi

    tcheck=$(echo "${tchoiceTy}"|sed -n "/^[0-9][0-9]*$/p"|wc -l)         
    [ ${tcheck} -eq 0 ] && tchoiceTy=0     
    if [[ ${tchoiceTy} -eq 0  ]];then
        tmptoFiles=$(convertVLineToSpace "${tmpjdObj}")
    else
        #找最新修改时间的文件
        tmptoFiles=$(find ${tmpjdObj} -type f|xargs ls -lrt|tail -1|awk '{print $NF}')

    fi
    toFiles=(${tmptoFiles})

    
    retMsg=$(F_killOnePFunc "${tpName}" "${tlogdir}" "${twtstmxsc}" "${tjdOther}" "${tjgIf}" "${tchoiceTy}" "${tjgType}" "${tPidRtm}" "${toFiles[*]}")
    ret=$?
    if [ ${ret} -eq 9 ];then
        outFlag=1
        outMsg="${outMsg} ${tpName}"
    fi  

    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "call F_killOnePFunc:ret=[${ret}],retMsg=[${retMsg}],outFlag=[${outFlag}]">>${logDebugFile}
    fi

done


if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
    echo -e "\n\n`date +%Y/%m/%d-%H:%M:%S.%N`:outFlag=[${outFlag}]\n">>${logDebugFile}
fi

if [[ ! -z "${outFlag}" && ${outFlag} -eq 1 ]];then
    endStr="End running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"
    F_writeLog 0 "${shName}" "${versionNo}" "${pName[*]}" "${logFile}" "${begineStr}"
    F_writeLog 0 "${shName}" "${versionNo}" "${pName[*]}" "${logFile}" "${outMsg}"
    F_writeLog 0 "${shName}" "${versionNo}" "${pName[*]}" "${logFile}" "${endStr}"
    F_writeLog 1 "${shName}" "${versionNo}" "${pName[*]}" "${logFile}"  "\tscript [ $0 ] runs complete!!\n\n"

    if [[ ! -z "${debugFlag}" && ${debugFlag} -eq 1 ]];then
        echo "begineStr=[${begineStr}]">>${logDebugFile}
        echo "outMsg=[${outMsg}]">>${logDebugFile}
        echo "endStr=[${endStr}]">>${logDebugFile}
        echo -e "script [ $0 ] runs complete!!\n\n">>${logDebugFile}
    fi
fi

exit 0

