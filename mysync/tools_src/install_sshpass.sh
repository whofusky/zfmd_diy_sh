#!/bin/bash
#
################################################################################
#
#author: fushikai
#date  : 2023-03-01_10:19:40
#desc  :
#        在当前系统中安装sshpass工具
#
################################################################################
#



NOOUT=0 ; levelName[0]="NOOUT";
ERROR=1 ; levelName[1]="ERROR";
INFO=2  ; levelName[2]="INFO" ;
DEBUG=3 ; levelName[3]="DEBUG";


trap ""  1 2 3 9 11 13 15


thisShName="$0"
inTest="$1"
onlyShName=${thisShName##*/}
onlyShPre=${onlyShName%.*}
inParNum=$#


##################################################
#Define the files and paths required by the script
##################################################
runDir="$(dirname ${thisShName})"

logDir="${runDir}/log"
logFile="${logDir}/${onlyShPre}.log"

toolSubDir=tools_src
sshpassPack=sshpass-1.09.tar.gz
sshpassUnp=sshpass-1.09


##################################################
#Define some global variables used by the script
##################################################
curUser=$(whoami)

#[ ! -d "${logDir}" ] && mkdir -p "${logDir}"



function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
{

    [ -z "${OUT_LOG_LEVEL}" ] && OUT_LOG_LEVEL=${DEBUG}


    [ $# -lt 2 ] && return 1

    #特殊调试时用
    print_to_stdin_flag=1  # 0:可能输出到日志文件; 1: 输出到屏幕

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

function F_check()
{
    if [ "x${curUser}" != "xroot" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}| 请用root用户执行此脚本!\n"
        exit 1
    fi
    which sshpass >/dev/null 2>&1
    if [ $? -eq 0 ];then
        F_writeLog $INFO "${LINENO}|${FUNCNAME}|系统中已经有sshpass,不需要再安装!\n"
        exit 0
    fi
}

function F_installSshpass()
{
    local curPath tododir

    curPath="$(pwd)"
    
    cd ${runDir}
    if [ ! -f "${sshpassPack}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|file [${runDir}/${sshpassPack}] not exist!"
        exit 1
    fi

    tododir="${runDir}/${sshpassUnp}"
    [ -d "${tododir}" ] && rm -rf  "${tododir}"
    
    F_writeLog $INFO "${LINENO}|${FUNCNAME}| prepare to install sshpass..."
    tar -zxvf "${sshpassPack}"
    if [ ! -d "${tododir}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}| tar -zxvf ${sshpassPack}, result,dir [${tododir}] not exist!"
        cd "${curPath}"
        exit 2
    fi

    cd "${tododir}"
    ./configure
    make
    make install

    cd "${curPath}"
}


trap "F_myExit"  1 2 3 9 11 13 15


#Main function logic
main()  
{


    F_check
    F_installSshpass
}

main

exit 0



