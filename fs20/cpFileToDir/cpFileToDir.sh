#!/bin/bash
#
################################################################################
#
#author: fushikai
#date  : 2022-10-25_08:45:39
#desc  :
#        根据脚本的同级目录下有配置文件cfg/cfg.cfg配置的条件将源文件拷贝到
#        目标目录
#        在脚本同级目录 tmp/back下会记录1天之内拷贝成功的文件，以防止重复拷贝
#        
#
#Precondition :
#       1. 在脚本的同级目录下有配置文件cfg/cfg.cfg，且配置文件已经按要求配置完成
#
#usage like:  
#         ./$0  
#
#Version change record:
#
#
################################################################################
#

versionNo="software version number: v20.01.000"

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
backDir="${tmpDir}/back"

logDir="${runDir}/log"
logFile="${logDir}/${onlyShPre}.log"

diyFuncFile="${runDir}/myDiyShFunction.sh"
cfgFile="${runDir}/cfg/cfg.cfg"


##################################################
#Define some global variables used by the script
##################################################
v_Minute=$(date +%M)
v_CfgSec=0
v_FuncSec=0


[ ! -d "${logDir}" ] && mkdir -p "${logDir}"
[ ! -d "${backDir}" ] && mkdir -p "${backDir}"


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
    [ ! -d "${backDir}" ] && mkdir -p "${backDir}"

    F_loadDiyFun

    F_checkSysCmd  "bc"  "cut" "touch"
    F_cfgFileCheck

    F_reduceFileSize "${logFile}" "6"

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

    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|doing [${backDir}]...!"

    #back file deletion
    F_rmExpiredFile "${backDir}" "1"


    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|do [${backDir}] complete!"

    return 0
}

function F_doCpOneDir()
{
    if [ $# -lt 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|input parameters number less than 1!"
        return 0
    fi
    local tIdx="$1"

    local tSrcDir="${g_src_dir[${tIdx}]}"
    local tDstDir="${g_dst_dir[${tIdx}]}"
    local tFils="${g_file_name[${tIdx}]}"
    local tBScds="${g_basicCondition_sec[${tIdx}]}"
    local logLevel="$DEBUG"

    if [ ! -d "${tSrcDir}" ];then
        local tMinute=$(date +%M)
        local tMod=$(echo "${tMinute} / 5"|bc)
        #每5分钟输出一个ERROR
        if [ "${g_nodir_flag[$tIdx]}x" != "${tMod}x" ];then
            g_nodir_flag[$tIdx]="${tMod}"
            logLevel="$ERROR"
        fi
        F_writeLog "$logLevel" "${LINENO}|${FUNCNAME}|dir [ ${tSrcDir} ] not exist!"
        return 1
    fi

    if [ ! -d "${tDstDir}" ];then
        mkdir -p "${tDstDir}"
    fi

    local tFileNames ; local it ; local tnum=0;
    local tnaa;  local tureFlag;
    local tmpFile; local tmpBackFile;
    local logLevel; local tDstDirs;
    local ttmpFile; local ik;
    local k=0;

    tFileNames=$(F_convertVLineToSpace "${tFils}") 

    for it in ${tFileNames}
    do
        tnum=$(ls -1 "${tSrcDir}"/${it} 2>/dev/null|wc -l)
        if [ ${tnum} -lt 1 ];then
            continue
        fi

        ls -1 "${tSrcDir}"/${it} 2>/dev/null|while read tnaa
        do
            tureFlag=$(F_judgeFileOlderXSec "${tnaa}" "${tBScds}")
            [ "${tureFlag}" != "1" ] && continue

            tmpFile=$(F_getFileName "${tnaa}");
            tmpBackFile="${backDir}/${tmpFile}"
            ttmpFile="${tmpFile}.tt"

            #判断文件是否已经copy过
            if [ -f "${tmpBackFile}" ];then
                F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|file [${tnaa}] has been copied before!"
                continue
            fi

            cp -a "${tnaa}"  "${tmpDir}"
            [ $? -eq 0 ] && { logLevel=$INFO; } || logLevel=$ERROR
            F_writeLog "$logLevel" "${LINENO}|${FUNCNAME}|cp -a ${tnaa} ${tmpDir}"
            [ ${logLevel} -eq $ERROR ] && continue

            local tFirstTmpFile="${tmpDir}/${tmpFile}"
            local tFirstTTmpFile="${tmpDir}/${ttmpFile}"

            #多个目标目录用|线分隔
            tDstDirs=$(F_convertVLineToSpace "${tDstDir}") 
            tnum=$(echo "${tDstDirs}"|awk '{print NF}')
            k=0
            if [ ${tnum} -gt 0 ];then
                F_writeLog "$INFO" "\n"
                F_writeLog "$INFO" "${LINENO}|${FUNCNAME}| cp [${tnaa}] --> [${tDstDir}] begine..."
            fi
            #echo "tDstDirs=[${tDstDirs}],tnum=[${tnum}]"
            for ik in ${tDstDirs}
            do
                [ ! -d "${ik}" ] && mkdir -p "${ik}"

                local ttDstFile="${ik}/${tmpFile}"

                let k++
                if [ ${k} -gt ${tnum} ];then
                    F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}| logic err: k=[$k],tnum=[${tnum}]"
                    break
                fi

                #多个目标目录,当前处于非最后一个目录
                if [ ${k} -lt ${tnum} ];then
                    #将临时文件再拷贝一份,以便移动到非最后一个目录
                    cp -a "${tFirstTmpFile}"  "${tFirstTTmpFile}"
                    [ $? -eq 0 ] && { logLevel=$INFO; } || logLevel=$ERROR
                    F_writeLog "$logLevel" "${LINENO}|${FUNCNAME}|cp -a ${tFirstTmpFile} ${tFirstTTmpFile}"
                    [ ${logLevel} -eq $ERROR ] && continue

                    #将拷贝的临时文件移动到目标目录
                    mv "${tFirstTTmpFile}" "${ttDstFile}"
                    [ $? -eq 0 ] && { logLevel=$INFO; } || logLevel=$ERROR
                    F_writeLog "$logLevel" "${LINENO}|${FUNCNAME}|mv ${tFirstTTmpFile} ${ttDstFile}"
                    [ ${logLevel} -eq $ERROR ] && continue

                else #多个目标目录,当前处于非最后一个目录

                    #将第1次拷贝的临时文件文件移动到目标目录
                    mv "${tFirstTmpFile}" "${ttDstFile}"
                    [ $? -eq 0 ] && { logLevel=$INFO; } || logLevel=$ERROR
                    F_writeLog "$logLevel" "${LINENO}|${FUNCNAME}|mv ${tFirstTmpFile} ${ttDstFile}"
                    [ ${logLevel} -eq $ERROR ] && continue

                fi

            done

            #成功移动文件后将记录当前拷贝过的文件到备份目录
            if [[ ${k} -gt 0 && ${k} -eq ${tnum} ]];then
                touch "${tmpBackFile}"
                [ $? -eq 0 ] && { logLevel=$INFO; } || logLevel=$ERROR
                F_writeLog "$logLevel" "${LINENO}|${FUNCNAME}|touch ${tmpBackFile}"
                if [ ${tnum} -gt 0 ];then
                    F_writeLog "$INFO" "${LINENO}|${FUNCNAME}| cp [${tnaa}] --> [${tDstDir}] end!"
                    F_writeLog "$INFO" "\n"
                fi
            else
                if [ ${tnum} -gt 0 ];then
                    F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}| cp [${tnaa}] --> [${tDstDir}] end!"
                    F_writeLog "$ERROR" "\n"
                fi
            fi
        done
    done

    return 0
}

function F_doCpAllDir()
{
    if [ ${g_do_nums} -lt 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|g_do_nums=[${g_do_nums}]!"
        return 0
    fi

    local i=0

    for((i=0;i<${g_do_nums};i++))
    do
        F_doCpOneDir "${i}"
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

    while :
    do
        F_check
        F_delSomeExpireFile
        F_doCpAllDir
        sleep 1
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|The program is in normal operation!"
    done

    return 0
}

main

exit 0



