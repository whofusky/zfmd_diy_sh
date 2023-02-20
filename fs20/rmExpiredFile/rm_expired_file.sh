#!/bin/bash
#
################################################################################
#
#author: fushikai
#date  : 2023-02-09_08:23:17
#desc  :
#        根据配置删除过期文件
#        
#
#Precondition :
#       1. 在脚本的同级目录下有配置文件cfg.cfg，且配置文件已经按要求配置完成
#
#usage like:  
#         ./$0  
#
#
#
################################################################################
#

#software version number
versionNo="v20.01.000"

NOOUT=0 ; levelName[0]="NOOUT";
ERROR=1 ; levelName[1]="ERROR";
INFO=2  ; levelName[2]="INFO" ;
DEBUG=3 ; levelName[3]="DEBUG";


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

verFile="${runDir}/version.txt"

logDir="${runDir}/log"
logFile="${logDir}/${onlyShPre}.log"

diyFuncFile="${runDir}/myDiyShFunction.sh"
cfgFile="${runDir}/cfg.cfg"


##################################################
#Define some global variables used by the script
##################################################
v_Minute=$(date +%M)
v_CfgSec=0
v_FuncSec=0


[ ! -d "${logDir}" ] && mkdir -p "${logDir}"






function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
{

    [ -z "${OUT_LOG_LEVEL}" ] && OUT_LOG_LEVEL=${DEBUG}


    [ $# -lt 2 ] && return 1

    #特殊调试时用
    local print_to_stdin_flag=0  # 0:可能输出到日志文件; 1: 输出到屏幕

    #input log level
    local i="$1"   
    

    ##debug to open this
    #[ $(echo "${i}"|sed -n '/^[0-9]*$/p' |wc -l) -eq 0 ] && i=${DEBUG}
    #[ $(echo "${NOOUT}<=${i} && ${i}<=${DEBUG}"|bc) -eq 0 ] && i=${DEBUG}


    [ ${i} -gt ${OUT_LOG_LEVEL} ] && return 0

    local puttxt="$2"

    # 1.换行符;2.空; 3.多个-;
    # 以上任一情况 则直接输出而不在输出内容之前添加日期等内容
    local tflag=$(echo "${puttxt}"|sed -n '/^\s*\(\(\\n\)\+\)*$\|^\s*-\+$/p'|wc -l)

    #没有设置日志文件时默认也是输出到屏幕
    [ -z "${logFile}" ] && print_to_stdin_flag=1

    local timestring
    [ ${tflag} -eq 0 ] && timestring="$(date +%F_%T.%N)"

    if [ ${print_to_stdin_flag} -eq 1 ];then
        if [ ${tflag} -gt 0 ];then
            echo -e "${puttxt}"
        else
            echo -e "${timestring}|${levelName[$i]}|${puttxt}"
        fi
        return 0
    fi


    [ -z "${logDir}" ] &&  logDir="${logFile%/*}"
    if [ "${logDir}" = "${logFile}" ];then
        logDir="./"
    elif [ ! -d "${logDir}" ];then
        mkdir -p "${logDir}"
    fi

    if [ ${tflag} -gt 0 ];then
        echo -e "${puttxt}" >> "${logFile}"
    else
        echo -e "${timestring}|${levelName[$i]}|${puttxt}" >> "${logFile}"
    fi


    return 0
}



function F_myExit()
{
    F_writeLog "$INFO" "\n"
    F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|[${onlyShName}] Exit normally after receiving the signal!"
    F_writeLog "$INFO" "\n"
    exit 0
}

function F_writeVersion()
{
    local tmpStr="

    version no : ${versionNo}
    runing time: $(date +%F_%T.%N)

    "
    echo -e "${tmpStr}">"${verFile}"
    return 0
}

#locad diy shell functions
function F_loadDiyFun()
{
    local tFuncSec=0; 

    #load sh func
    if [ ! -f ${diyFuncFile} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|file [${diyFuncFile}] not exits!"
        exit 1
    else
        tFuncSec=$(stat -c %Y ${diyFuncFile})
        if [ "${tFuncSec}" != "${v_FuncSec}" ];then
            F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|load ${diyFuncFile}"
            v_FuncSec="${tFuncSec}"
            . ${diyFuncFile}
        fi
    fi

    return 0
}




#Some checks that the program needs to run
#
function F_check()
{
    [ ! -d "${logDir}" ] && mkdir -p "${logDir}"

    F_loadDiyFun

    F_checkSysCmd  "bc"  "cut" "touch"
    F_cfgFileCheck

    F_reduceFileSize "${logFile}" "6"

    return 0
}

function F_doRmOneDir()
{
    if [ $# -lt 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|input parameters number less than 1!"
        return 0
    fi
    local tIdx="$1"

    local tDstDir="${g_del_dir[${tIdx}]}"
    local tFils="${g_file_name[${tIdx}]}"
    local tBScds="${g_expired_day[${tIdx}]}"

    if [ ! -d "${tDstDir}" ];then
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|dir [ ${tDstDir} ] not exist!"
        return 1
    fi


    local tFileNames ; local it ; 

    tFileNames=$(F_convertVLineToSpace "${tFils}") 

    for it in ${tFileNames}
    do
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|F_rmExpiredFile ${tDstDir} ${tBScds} ${it}"
        F_rmExpiredFile "${tDstDir}" "${tBScds}" "${it}"
    done

    return 0
}



#Delete some expired files according to the configuration of the 
#configuration file
#
function F_delSomeExpireFile()
{
    #[ -z "${v_Minute}" ] && return 0

    #local trueFlag=0

    ##Only perform the delete operation during the 15-25 minute period
    ##
    #trueFlag=$(echo "${v_Minute} >=15 && ${v_Minute} <=25"|bc)
    #[ ${trueFlag} -ne 1 ] && return 0

    if [ ${g_do_nums} -lt 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|g_do_nums=[${g_do_nums}]!"
        return 0
    fi

    local i=0

    for((i=0;i<${g_do_nums};i++))
    do
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|F_doRmOneDir ${i}"
        F_doRmOneDir "${i}"
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

    F_loadDiyFun
    #Exit if a script is already running
    F_shHaveRunThenExit "${onlyShName}"

    F_check
    F_writeVersion

    while :
    do
        F_check
        F_delSomeExpireFile

        if [ ! -z "${g_chek_file_refresh_rate}" ];then
            sleep "${g_chek_file_refresh_rate}"
        else
            sleep 5
        fi
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|The program is in normal operation!"
    done

    return 0
}

main

exit 0



