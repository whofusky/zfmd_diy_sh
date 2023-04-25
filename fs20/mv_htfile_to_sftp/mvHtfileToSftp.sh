#!/bin/bash
#
################################################################################
#
#author: fushikai
#date  : 2023-04-24_10:52:39
#desc  : 将merge_windtower_htfile脚本生成的结果文件(文件名类似:
#        cft_001_010_20230307-20230307.csv 其中20230307表示日期),
#        非当天的数据移动到sftp上传文件夹
#
#Precondition :
#       1. 结果文件名需要满足格式: *-YYYYMMDD.* (其中YYYYMMDD表示时间)
#
#                 
#usage like:  
#         #自动根据配置文件配置去找相应的数据合成
#         ./$0  
#
#Deployment method:
#       此脚本运行后是长驻内存的
#
#
#Version change record:
#     2023-04-11 initial version  v20.01.000
#
################################################################################
#


g_version_no="v20.01.000"



thisShName="$0"
onlyShName=${thisShName##*/}
onlyShPre=${onlyShName%.*}
[ $# -ge 1 ] && manualEnterDate="$1"
inParNum=$#


#--------------------------------------------------
#
#        配置要拷贝的源目录与目标目录
#
#--------------------------------------------------
g_src_dir[0]="/zfmd/data_file/CFT_DST"
g_src_file[0]="*.csv"
g_dst_dir[0]="/zfmd/data_file/CFT_UP"









###############################################
#Load system environment variable configuration
###############################################
 [ -f /etc/profile ] && . /etc/profile >/dev/null 2>&1
 [ -f ${HOME}/.bash_profile ] && . ${HOME}/.bash_profile >/dev/null 2>&1
 [ -f ${HOME}/.profile ] && . ${HOME}/.profile >/dev/null 2>&1




###############################################
# Obtain time dependent variables
###############################################

NOOUT=0 ; levelName[0]="NOOUT";
ERROR=1 ; levelName[1]="ERROR";
INFO=2  ; levelName[2]="INFO" ;
DEBUG=3 ; levelName[3]="DEBUG";


#OUT_LOG_LEVEL=${DEBUG}
OUT_LOG_LEVEL=${INFO}




##################################################
#Define the files and paths required by the script
##################################################
runDir="$(dirname ${thisShName})"


logDir="${runDir}/log"
logFile="${logDir}/${onlyShPre}_$(date +%Y%m%d).log"
versionFile="${runDir}/version.txt"
logLevelFile="${runDir}/loglevel"





##################################################
#Define some global variables used by the script
##################################################
v_havedo=0
v_logcfgSec=0




function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
{

    [ $# -lt 2 ] && return 1

    #特殊调试时用
    local print_to_stdin_flag=0  # 0:可能输出到日志文件; 1: 输出到屏幕; 2可能同时输出到屏幕和日志文件

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


function F_isDigital() # return 1: digital; 0: not a digital
{
    [ $# -ne 1 ] && echo "0" && return 0

    if [ $(echo "$1"|sed -n '/\(^[0-9]$\|^[1-9][0-9]\+$\)/p'|wc -l) -gt 0 ];then 
        echo "1" && return 1
    fi

    echo "0" && return 0
}


function F_getFileName() #get the file name in the path string
{
    [ $# -ne 1 ] && return 0
    [  -z "$1" ] && return 0
    echo "${1##*/}" && return 0
}


function F_myExit()
{
    F_writeLog "$INFO" "\n"
    F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|[${onlyShName}] Exit normally after receiving the signal!"
    F_writeLog "$INFO" "\n"
    exit 0
}


function F_mkpDir() #call eg: F_mkpDir "tdir1" "tdir2" ... "tdirn"
{
    [ $# -lt 1 ] && return 0
    local tdir
    while [ $# -gt 0 ]
    do
        tdir=$(echo "$1"|sed 's/\(^\s\+\)\|\(\s\+$\)//g')
        [ ! -z "${tdir}" -a ! -d "${tdir}" ] && mkdir -p "${tdir}"
        shift
    done
    #return 0
}

function F_checkSysCmd() #call eg: F_checkSysCmd "cmd1" "cmd2" ... "cmdn"
{
    [ $# -lt 1 ] && return 0

    local errFlag=0
    while [ $# -gt 0 ]
    do
        which $1 >/dev/null 2>&1
        if [ $? -ne 0 ];then 
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|The system command \"$1\" does not exist in the current environment!"
            errFlag=1
        fi
        shift
    done

    [ ${errFlag} -eq 1 ] && exit 1

    #return 0
}

function F_rmExpiredFile() #call eg: F_rmExpiredFile "path" "days" OR F_rmExpiredFile "path" "days" "files"
{
    [ $# -ne 2 ] && [ $# -ne 3 ] && return 1

    local tpath="$1" ; local tdays="$2"
    [ ! -d "${tpath}" ] && return 2

    [ $(F_isDigital "${tdays}") = "0" ] && tdays=1

    local tname="*"
    [ $# -eq 3 ] && tname="$3"

    local tnum=0
    tnum=$(find "${tpath}" -name "${tname}" -type f -mtime +${tdays} -print 2>/dev/null|wc -l)
    [ ${tnum} -eq 0 ] && return 0

    local ret loglevel

    find "${tpath}" -name "${tname}" -type f -mtime +${tdays} -print0 2>/dev/null|xargs -0 rm -rf
    ret=$?
    [ $ret -eq 0 ] && loglevel=$INFO || loglevel=$ERROR
    F_writeLog "${loglevel}" "${LINENO}|${FUNCNAME}|delete [${tnum}] [${tname}] files in the [${tpath}] directory that have been modified for more than [${tdays}] days,  return[$ret]"

    #return 0
}



function F_shHaveRunThenExit()  #Exit if a script is already running
{
    if [ $# -lt 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|Function input arguments are less than 1!\n"
        exit 1
    fi
    
    local pname="$1"
    local tmpShPid tmpShPNum

    tmpShPid=$(pidof -x ${pname})
    tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
    if [ ${tmpShPNum} -gt 1 ]; then
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|script [${pname}] has been running this startup exit,pidNum=[$tmpShPNum],pid=[${tmpShPid}]!\n"
        exit 0
    fi

    #return 0
}


function F_writeVersion()
{
    [ $# -ne 1 ] && return 1

    local tverfile="$1"
    local dirName="$(dirname ${tverfile})"

    [ ! -d "${dirName}" ] && mkdir -p "${dirName}"

    echo -e "\n runtime:[$(date +%y-%m-%d_%H:%M:%S.%N)]\n version:[ ${g_version_no} ] \n">"${tverfile}"

    return 0
}


#加载日志输出控制文件
function F_loadLogLevel()
{
    [ -z "${logLevelFile}" ] && return 0
    [ ! -f "${logLevelFile}" ] && return 0
    local tlogsec=0;
    tlogsec=$(stat -c %Y ${logLevelFile})
    if [ "${tlogsec}" != "${v_logcfgSec}" ];then
        v_logcfgSec="${tlogsec}"
        . ${logLevelFile}

        F_writeLog "$INFO" "\n"
        F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|load ${logLevelFile}"
        F_writeLog "$INFO" "\n"
    else
        return 0
    fi
}

#Some checks that the program needs to run
#
function F_check()
{
    logFile="${logDir}/${onlyShPre}_$(date +%Y%m%d).log"
    F_loadLogLevel
    F_mkpDir "${logDir}"
    g_dir_num=${#g_src_dir[*]}

    F_checkSysCmd "mv"

    return 0
}







#Delete some expired files according to the configuration of the 
#configuration file
#
function F_delSomeExpireFile()
{

    #F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}| doing...!"

    #Log file deletion
    F_rmExpiredFile "${logDir}" "10" "*.log"

    #F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}| do complete!"
}




#获取当前时间的YYYMMDD格式值
function F_genCurYMD()
{
    g_cur_YMD=$(date +%Y%m%d)
}


#获取cft_001_010_20230307-20230307.csv格式文件的20230307时间
function F_getFileYMD()
{
    if [ $# -ne 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|Function input arguments not eq 1!\n"
        g_file_YMD=""
        return 1
    fi
    local tfile="$1"
    local tpart="${tfile##*-}"
    if [ -z "${tpart}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|文件名[${tfile}]格式错误,需要类似[*-YYYYMMDD.*]格式的文件!\n"
        g_file_YMD=""
        return 1
    fi

    local tYMD="${tpart%.*}"
    if [ -z "${tYMD}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|文件名[${tfile}]格式错误,需要类似[*-YYYYMMDD.*]格式的文件!\n"
        g_file_YMD=""
        return 1
    fi
    
    g_file_YMD="${tYMD}"

}


function F_doOneDir()
{
    if [ $# -ne 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|Function input arguments not eq 1!\n"
        return 1
    fi

    local idx="$1"
    if [ -z "${g_src_dir[$idx]}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|g_src_dir[$idx] is null!\n"
        return 1
    fi
    if [ -z "${g_src_file[$idx]}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|g_src_file[$idx] is null!\n"
        return 1
    fi
    if [ -z "${g_dst_dir[$idx]}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|g_dst_dir[$idx] is null!\n"
        return 1
    fi

    if [ ! -d "${g_src_dir[$idx]}" ];then
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|dir g_src_dir[$idx]=[${g_src_dir[$idx]}] not exist !"
        return 2
    fi

    F_mkpDir "${g_dst_dir[$idx]}"

    local tnum tnaa ret loglevel
    tnum=$(ls -1 "${g_src_dir[$idx]}"/${g_src_file[$idx]} 2>/dev/null|wc -l)
    if [ $tnum -eq 0 ];then
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}| dir[ ${g_src_dir[$idx]} ] files [ ${g_src_file[$idx]} ] tnum eq 0"
        return 0
    fi

    ls -1 "${g_src_dir[$idx]}"/${g_src_file[$idx]} 2>/dev/null|while read tnaa
    do
        F_getFileYMD "${tnaa}"
        [ $? -ne 0 ] && continue
        F_genCurYMD

        #当天的文件不处理
        if [ "x${g_cur_YMD}" = "x${g_file_YMD}" ];then
            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|the time of the file[ ${tnaa} ] is [ ${g_file_YMD} ] equal to the current date [ ${g_cur_YMD} ],so it will not be proccessed!"
            continue
        fi

        #将文件移动到目标目录
        mv "${tnaa}" "${g_dst_dir[$idx]}"
        ret=$?
        [ $ret -eq 0 ] && loglevel=$INFO || loglevel=$ERROR
        F_writeLog "${loglevel}" "${LINENO}|${FUNCNAME}| idx[$idx] mv ${tnaa} ${g_dst_dir[$idx]} return[$ret]"

    done



}


function F_doAllDir()
{
    local i=0
    for((i=0;i<${g_dir_num};i++));do
        F_doOneDir "$i"
    done
}



#Test function, abnormal logic
#
function F_printTest()
{

    return 0
}


trap "F_myExit"  1 2 3 9 11 13 15

#Main function logic
main()  
{
    local bgScds edScds diffScds

    F_shHaveRunThenExit "${thisShName}"
    F_check
    F_writeVersion "${versionFile}"

    #F_printTest
    #return 0

    while :
    do
        v_havedo=0
        F_check
        F_delSomeExpireFile
        F_doAllDir
        sleep 1
    done
}

main

exit 0



