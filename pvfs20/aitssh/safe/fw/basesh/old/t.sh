#!/bin/bash


export NOOUT=0 ; levelName[0]="NOOUT";
export ERROR=1 ; levelName[1]="ERROR";
export INFO=2  ; levelName[2]="INFO" ;
export DEBUG=3 ; levelName[3]="DEBUG";

#export levelName
export all_levelName=$(declare -p levelName)


export OUT_LOG_LEVEL=${DEBUG}

#logDir="/home/fusky/mygit/zfmd_diy_sh/wk_tmp/log"
logDir="$(dirname $0)"
logFile="${logDir}/t.log"

export logDir
export logFile

#echo "logFile[${logFile}]"
#exit 0




function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
{

    #NOOUT=0 ; levelName[0]="NOOUT";
    #ERROR=1 ; levelName[1]="ERROR";
    #INFO=2  ; levelName[2]="INFO" ;
    #DEBUG=3 ; levelName[3]="DEBUG";
    #
    #OUT_LOG_LEVEL=${DEBUG}
    #
    #logDir="/home/fusky/mygit/zfmd_diy_sh/wk_tmp/log"
    #logFile="${logDir}/t.log"


    #    [ -z "${NOOUT}" ] && NOOUT=0               
    #    [ -z "${ERROR}" ] && ERROR=1               
    #    [ -z "${INFO}" ]  && INFO=2               
    #    [ -z "${DEBUG}" ] && DEBUG=3               
    #    [ -z "${levelName[0]}" ] && levelName[0]="NOOUT"               
    #    [ -z "${levelName[1]}" ] && levelName[1]="ERROR"               
    #    [ -z "${levelName[2]}" ] && levelName[2]="INFO"               
    #    [ -z "${levelName[3]}" ] && levelName[3]="DEBUG"               
    #
    #    [ -z "${OUT_LOG_LEVEL}" ] && OUT_LOG_LEVEL=${DEBUG}



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
        if [ "${print_to_stdin_flag}x" = "2x" ];then
            echo -e "${puttxt}"|tee -a  "${logFile}"
        else
            echo -e "${puttxt}" >> "${logFile}"
        fi
    else
        if [ "${print_to_stdin_flag}x" = "2x" ];then
            echo -e "${timestring}|${levelName[$i]}|${puttxt}" |tee -a "${logFile}"
        else
            echo -e "${timestring}|${levelName[$i]}|${puttxt}" >> "${logFile}"
        fi
    fi


    return 0
}

export -f F_writeLog

function F_test()
{
    F_writeLog "$DEBUG" "hahaha"
    F_writeLog "$DEBUG" "\n\tError:\e[1;31m Please execute as root!\e[0m the current user is ${USER}\n"

    ./k.sh
    return 0
}

main()
{
    F_test
    return 0
}

main


