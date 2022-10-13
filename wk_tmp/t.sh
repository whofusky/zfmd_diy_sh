#!/bin/bash
#
##############################################################################
#
#
#
#
##############################################################################
#

NOOUT=0 ; levelName[0]="NOOUT";
ERROR=1 ; levelName[1]="ERROR";
INFO=2  ; levelName[2]="INFO" ;
DEBUG=3 ; levelName[3]="DEBUG";

OUT_LOG_LEVEL=${DEBUG}  #定义日志输出等级,大的等级包含小的等级日志输出

logDir="/home/fusky/mygit/zfmd_diy_sh/wk_tmp/log"
logFile="${logDir}/t.log"

thishSh="$0"
inpar1="$1"



#call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
function F_writeLog()
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
    local print_to_stdin_flag=1  # 0:可能输出到日志文件; 1: 输出到屏幕

    #input log level
    local i="$1"   
    

    ##debug to open this
    #[ $(echo "${i}"|sed -n '/^[0-9]*$/p' |wc -l) -eq 0 ] && i=${DEBUG}
    #[ $(echo "${NOOUT}<=${i} && ${i}<=${DEBUG}"|bc) -eq 0 ] && i=${DEBUG}


    [ ${i} -gt ${OUT_LOG_LEVEL} ] && return 0

    local puttxt="$2"

    # 1.换行符;2.空; 3.多个-;
    # 以上作一情况 则直接输出而不在输出内容之前添加日期等内容
    local tflag=$(echo "${puttxt}"|sed -n '/^\s*\(\(\\n\)\+\)*$\|^\s*-\+/p'|wc -l)

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


function F_rmFile() #call eg: F_rmFile "file1" "file2" ... "$filen"
{
    [ $# -lt 1 ] && return 0

    while [ $# -gt 0 ]
    do
        [ -e "$1" ] && rm -rf "$1"
        shift
    done

    return 0
}

function F_isDigital() # return 1: digital; 0: not a digital
{
    [ $# -ne 1 ] && echo "0" && return 0

    if [ $(echo "$1"|sed -n '/\(^[0-9]$\|^[1-9][0-9]\+$\)/p'|wc -l) -gt 0 ];then 
        echo "1" && return 1
    fi

    echo "0" && return 0
}



function F_test()
{
    #F_writeLog "$DEBUG"   "------------------------------"
    #F_writeLog "$DEBUG"   "\n\n"
    #F_writeLog "$INFO"   "haha"
    #F_writeLog "$INFO"   ""
    #F_writeLog "$DEBUG"   "------------------------------"

    #F_writeLog "aa"   "11haha"
    #F_writeLog "${ERROR}"   "haha"
    #F_writeLog "-2"   "11haha"

    #F_rmFile "/home/fusky/tmp/t/out_test.csv" "/home/fusky/tmp/t/out_test.1" "/home/fusky/tmp/t/out_test.csv.clr.bak"





    return 0
}


main()
{
    F_test
    return 0
}
main


