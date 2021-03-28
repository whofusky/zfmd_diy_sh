#!/bin/bash
#
################################################################################
#
#author:fushikai
#date  :2021-03-27
#desc  :根据脚本的同级目录下有配置文件cfg/cfg.cfg配置的条件将源文件移动到目标目录
#
#Precondition :
#       1. 在脚本的同级目录下有配置文件cfg/cfg.cfg，且配置文件已经按要求配置完成
#
#usage like:  
#         ./$0  
#
#Version change record:
#     2021-03-28         version  v20.01.010 @ 将脚本添加长驻内存及退出信息处理
#     2021-03-27 initial version  v20.01.000
#
#
################################################################################
#

versionNo="software version number: v20.01.010"


trap ""  1 2 3 9 11 13 15


thisShName="$0"
onlyShName=${thisShName##*/}
onlyShPre=${onlyShName%.*}
[ $# -ge 1 ] && manualEnterDate="$1"
inParNum=$#




###############################################
#Load system environment variable configuration
###############################################
 [ -f /etc/profile ] && . /etc/profile >/dev/null 2>&1
 [ -f ${HOME}/.bash_profile ] && . ${HOME}/.bash_profile >/dev/null 2>&1
 [ -f ${HOME}/.profile ] && . ${HOME}/.profile >/dev/null 2>&1






##################################################
#Define the files and paths required by the script
##################################################
runDir="$(dirname ${thisShName})"

tmpDir="${runDir}/tmp"

logDir="${runDir}/log"
logFile="${logDir}/${onlyShPre}_$(date +%Y%m%d).log"

diyFuncFile="${runDir}/myDiyShFunction.sh"
cfgFile="${runDir}/cfg/cfg.cfg"


##################################################
#Define some global variables used by the script
##################################################
v_Minute=$(date +%M)
v_CfgSec=0
v_FuncSec=0




function F_myExit()
{
    echo "">>${logFile}
    echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:[${onlyShName}] Exit normally after receiving the signal!" >>${logFile}
    echo "">>${logFile}
    exit 0
}

#Some checks that the program needs to run
#
function F_check()
{
    local tFuncSec=0; 

    #load sh func
    if [ ! -f ${diyFuncFile} ];then
        echo "$(date +%Y/%m/%d-%H:%M:%S.%N):ERROR:file [${diyFuncFile}] not exits!"
        exit 1
    else
        tFuncSec=$(stat -c %Y ${diyFuncFile})
        if [ "${tFuncSec}" != "${v_FuncSec}" ];then
            local tpShPid=$(pidof -x ${onlyShName})
            local tpShPNum=$(echo ${tpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
            if [ ${tpShPNum} -gt 1 ]; then
                #echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:+++${tpShPid}+++++${tpShPNum}+++"
                #echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:${onlyShName} script has been running this startup exit!"
                exit 0
            else
                echo "$(date +%Y/%m/%d-%H:%M:%S.%N):load ${diyFuncFile}"
            fi
            v_FuncSec="${tFuncSec}"
            . ${diyFuncFile}
        fi
    fi


    #Exit if a script is already running
    #F_shHaveRunThenExit "${onlyShName}"


    if [ ! -d "${logDir}" ];then
        mkdir -p "${logDir}"
    fi

    F_checkSysCmd  "${logFile}"  
    F_cfgFileCheck "${logFile}"

    return 0
}




#Delete some expired files according to the configuration of the 
#configuration file
#
function F_delSomeExpireFile()
{
    [ -z "${v_Minute}" ] && return 0

    local trueFlag=0

    #Only perform the delete operation during the 15-25 minute period
    #
    trueFlag=$(echo "${v_Minute} >=15 && ${v_Minute} <=25"|bc)
    [ ${trueFlag} -ne 1 ] && return 0

    F_outShDebugMsg "${logFile}" ${g_debugL_value} 32 "${FUNCNAME}: doing...!"

    #Log file deletion
    F_delExpirlogFile "${logDir}"


    F_outShDebugMsg "${logFile}" ${g_debugL_value} 32 "${FUNCNAME}: do complete!"

    return 0
}

function F_doMvOneDir()
{
    if [ $# -lt 1 ];then
        F_outShDebugMsg "${logFile}" ${g_debugL_value} 32 "${FUNCNAME}: input parameters number less than 1!"
        return 0
    fi
    local tIdx="$1"

    local tSrcDir="${g_src_dir[${tIdx}]}"
    local tDstDir="${g_dst_dir[${tIdx}]}"
    local tFils="${g_file_name[${tIdx}]}"
    local tBScds="${g_basicCondition_sec[${tIdx}]}"

    if [ ! -d "${tSrcDir}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "${FUNCNAME}:ERROR:dir [ ${tSrcDir} ] not exist!"
        return 1
    fi

    if [ ! -d "${tDstDir}" ];then
        mkdir -p "${tDstDir}"
    fi

    local tFileNames ; local it ; local tnum=0;
    local tnaa;  local tureFlag;

    tFileNames=$(F_convertVLineToSpace "${tFils}") 

    for it in ${tFileNames}
    do
        tnum=$(ls -1 "${tSrcDir}"/${it} 2>/dev/null|wc -l)
        if [ ${tnum} -lt 1 ];then
            continue
        fi

        ls -1 "${tSrcDir}"/${it} 2>/dev/null|while read tnaa
        do
            F_judgeFileOlderXSec "${tnaa}" "${tBScds}"
            tureFlag=$?
            if [ ${tureFlag} -eq 1 ];then
                mv "${tnaa}" "${tDstDir}"
                F_outShDebugMsg "${logFile}" ${g_debugL_value} 1 "${FUNCNAME}:[ mv ${tnaa} ${tDstDir} ]!"
            fi
        done
    done

    return 0
}

function F_doMvAllDir()
{
    if [ ${g_do_nums} -lt 1 ];then
        F_outShDebugMsg "${logFile}" ${g_debugL_value} 32 "${FUNCNAME}: g_do_nums=[${g_do_nums}]!"
        return 0
    fi

    local i=0

    for((i=0;i<${g_do_nums};i++))
    do
        F_doMvOneDir "${i}"
    done

    return 0
}

#Test function, abnormal logic
#
function F_printTest()
{
    local i=0
    #F_fuskytest

    return 0
}



trap "F_myExit"  1 2 3 9 11 13 15

#Main function logic
main()  
{

    while :
    do
        F_check
        F_delSomeExpireFile
        F_doMvAllDir
        sleep 1
        #echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:g_log_delExpirDays=[${g_log_delExpirDays}]"
        F_outShDebugMsg "${logFile}" ${g_debugL_value} 32 "The program is in normal operation!"
    done

    return 0
}

main

exit 0



