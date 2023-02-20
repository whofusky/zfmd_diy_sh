#!/bin/bash
#
########################################################################
#author        :    fushikai
#creation date :    2022-12-19
#linux_version :    Red Hat / UniKylin
#dsc           :
#       Initialize the system environment
#    
#revision history:
#
#   v20.000.001 2022-12-19: pvfs20 basic
#
########################################################################

#$0 serv_type 固定网卡号 授权文件(带路径)

thisObj="$0"; inOpType="$1"; inFile="$2"
inNumbs="$#"


shName="${thisObj##*/}"




baseDirM=$(dirname $0)


NOOUT=0 ; levelName[0]="NOOUT";
ERROR=1 ; levelName[1]="ERROR";
INFO=2  ; levelName[2]="INFO" ;
DEBUG=3 ; levelName[3]="DEBUG";

#all_levelName=$(declare -p levelName)

OUT_LOG_LEVEL=${DEBUG}

g_baseicDir="${baseDirM}"
#if [ "x${baseDirM}" == "x." ];then
if [ $(echo "${baseDirM}"|sed -n '/^\s*\//p'|wc -l) -eq 0 ];then
    g_baseicDir="${PWD}/${baseDirM}"
fi
export g_baseicDir

logDir="${g_baseicDir}/log"
[ ! -d "${logDir}" ] && mkdir -p "${logDir}"
logFile="${logDir}/${shName}.log"







function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
{

    [ $# -lt 2 ] && return 1

    #特殊调试时用
    local print_to_stdin_flag=2  # 0:可能输出到日志文件; 1: 输出到屏幕; 2可能同时输出到屏幕和日志文件

    #input log level
    local i="$1"   
    

    ##debug to open this
    #[ $(echo "${i}"|sed -n '/^[0-9]*$/p' |wc -l) -eq 0 ] && i=${DEBUG}
    #[ $(echo "${NOOUT}<=${i} && ${i}<=${DEBUG}"|bc) -eq 0 ] && i=${DEBUG}


    [ ${i} -gt ${OUT_LOG_LEVEL} ] && return 0

    local puttxt="$2"

    # 1.换行符;2.空; 3.多个-;
    # 以上作一情况 则直接输出而不在输出内容之前添加日期等内容
    local tflag=$(echo "${puttxt}"|sed -n '/^\s*\(\(\\n\)\+\)*$\|^\s*-\+$/p'|wc -l)

    #没有设置日志文件时默认也是输出到屏幕
    [ -z "${logFile}" ] && print_to_stdin_flag=1

    local timestring
    local timeSt
    if [ ${tflag} -eq 0 ];then
        timestring="$(date +%F_%T.%N)"
        timeSt="$(date +%T.%N)"
    fi
        

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
        if [ "${print_to_stdin_flag}x" = "2x" ];then
            echo -e "${puttxt}"|tee -a  "${logFile}"
        else
            echo -e "${puttxt}" >> "${logFile}"
        fi
    else
        if [ "${print_to_stdin_flag}x" = "2x" ];then
            echo -e "${timeSt}|${levelName[$i]}|${puttxt}"
            echo -e "${timestring}|${levelName[$i]}|${puttxt}" >>"${logFile}"
        else
            echo -e "${timestring}|${levelName[$i]}|${puttxt}" >> "${logFile}"
        fi
    fi


    return 0
}


function F_notFileExit() #call eg: notFileExit "file1" "file2" ... "filen"
{
    [ $# -lt 1 ] && return 0
    local tmpS
    while [ $# -gt 0 ]
    do
        tmpS="$1"
        if [ ! -f "${tmpS}" ];then
            F_writeLog "$ERROR" "file [${tmpS}] does not exist!"
            exit 1
        fi
        shift
    done
    return 0
}




function F_checkAndLoad()
{
    g_baseFunc="${g_baseicDir}/shfunclib.sh"
    g_localFunc="${g_baseicDir}/localfunc.sh"

    F_notFileExit "${g_baseFunc}" "${g_localFunc}"

    source "${g_baseFunc}"

    F_shHaveRunThenExit "${shName}"
    F_checkSysCmd "uname"

    source "${g_localFunc}"

    #fusktest 注释
    #F_needRootUser

    F_judgeOsSysType

    #echo "g_init_type=[${g_init_type}]"
    #echo "g_sys_name=[${g_sys_name}]"

    return 0
}





function F_ECHO_DO()
{
    local cmd="$*"
    F_writeLog $INFO "$USER@$HOSTNAME@${debugFlag}| ${cmd}"
    if [[ -z "${debugFlag}" || ${debugFlag} -ne 1 ]];then
        ${cmd} 2>&1|tee -a "${logFile}"
    fi
    return 0
}





main()
{
    F_checkAndLoad

    return 0
}


main

exit 0

