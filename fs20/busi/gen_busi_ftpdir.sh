#!/bin/bash
##############################################################################
# author  :  fusky
# date    :  2023-03-09_09:03:39
# dsc     :
#            根据2.0业务清单合成的配文件自动提取云平台的生成业务清单需要的文件夹一级目录结果文件
#
##############################################################################

shName="${0##*/}"
runDir="$(cd "$(dirname "$0")" >/dev/null 2>&1 || exit; pwd -P)"

NOOUT=0 ; levelName[0]="NOOUT";
ERROR=1 ; levelName[1]="ERROR";
INFO=2  ; levelName[2]="INFO" ;
DEBUG=3 ; levelName[3]="DEBUG";

#all_levelName=$(declare -p levelName)

OUT_LOG_LEVEL=${DEBUG}

logDir="${runDir}/log"
[ ! -d "${logDir}" ] && mkdir -p "${logDir}"
logFile="${logDir}/${shName}.log"



function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
{

    [ $# -lt 2 ] && return 1

    #特殊调试时用
    local print_to_stdin_flag=1  # 0:可能输出到日志文件; 1: 输出到屏幕; 2可能同时输出到屏幕和日志文件

    #input log level
    local i="${1-3}"   
    

    ##debug to open this
    #[ $(echo "${i}"|sed -n '/^[0-9]*$/p' |wc -l) -eq 0 ] && i=${DEBUG}
    #[ $(echo "${NOOUT}<=${i} && ${i}<=${DEBUG}"|bc) -eq 0 ] && i=${DEBUG}


    [ ${i} -gt ${OUT_LOG_LEVEL:=3} ] && return 0

    local puttxt="$2"

    #echo "fusktest:puttxt=[${puttxt}]"

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



function F_check()
{
    edFile="${runDir}/config.xml"
    resultDir="${runDir}/result"
    [ ! -d "${resultDir}" ] && mkdir -p "${resultDir}"
    resultFile="${resultDir}/genbusi_ftp_first_dir.txt"

    F_notFileExit "${edFile}"
    if [ -f "${resultFile}" ];then
        cp -a "${resultFile}" "${resultFile}.$(date +%s)"
    fi
    
}

function F_genDirByCfgfile()
{
    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}| edFile=[${edFile}]"
    sed -n '/^\s*<\s*downFile\s\+/p' "${edFile}"|awk '{for(i=1;i<=NF;i++){if($i ~/downDir=/){print $i;break;}}}'|awk -F'["/]' '{print $3}'|sort|uniq >"${resultFile}"
    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}| result file = [${resultFile}]"
}

main()
{
    F_check
    F_genDirByCfgfile
}

main
