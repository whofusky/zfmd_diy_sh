#!/bin/bash
#
##############################################################################
#
#
#
#
##############################################################################
#




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

function F_getFileName() #get the file name in the path string
{
    [ $# -ne 1 ] && return 0
    [  -z "$1" ] && return 0
    echo "${1##*/}" && return 0
}

function F_getPathName() #get the path value in the path string(the path does not have / at the end)
{
    [ $# -ne 1 ] && return 0
    [  -z "$1" ] && return 0

    local tpath="${1%/*}"
    [ "${tpath}" = "$1" ] && tpath="."
    echo "${tpath}" && return 0
}



function F_reduceFileSize() #call eg: F_reduceFileSize "/zfmd/out_test.csv" "4"
{
    if [ $# -ne 2 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|imput parameters not eq 2!\n"
        return 1
    fi

    local backFlag=0 #是否备份越大文件并把原文件清空: 0 不备份,不缩减原文件; 1备份

    local tfile="$1"
    local tsizem="$2"
    local tonecedelete=100
    local tfileback="${tfile}"
    [ ${backFlag} -eq 1 ] && tfileback="${tfile}.clr.bak"


    local tbegineseconds=$(date +%s)

    if [ ! -f "${tfile}" ];then
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|The file [${tfile}] not exist,so it does not need to be processed!"
        return 0
    fi
    if [ ! -w "${tfile}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|user [$(whoami)] 对文件[${tfile}]没有写权限,因此不能对文件进行缩小操作!"
        return 1
    fi

    #The unit is MB
    local cursizem=$(echo "scale=3;$(stat -c %s ${tfile})/(1024*1024)"|bc)
    local initsizem="${cursizem}"


    [ $(echo "${tsizem} <= 0"|bc) -eq 1 ] && tsizem="0.001"

    local judgesize=$(echo "${tsizem} - 0.1"|bc)
    [ $(echo "(${tsizem} -1) > 0"|bc) -eq 0 ] && judgesize="${tsizem}"

    local needDoFlag=$(echo "${cursizem} > ${judgesize}"|bc)
    local initFlag="${needDoFlag}"

    local ret;

    if [ ${needDoFlag} -eq 1 -a ${backFlag} -eq 1 ];then
        cp -a "${tfile}" "${tfileback}"
        ret=$?
        if [ ${ret} -eq 0 ];then
            >"${tfile}"
            F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|[ cp -a ${tfile} ${tfileback} ] and [ >${tfile} ] sucess!"
        else
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|[ cp -a ${tfile} ${tfileback} ] return error!"
            return 2
        fi
    fi

    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|file[${tfileback}] cur_size_m=[${cursizem}M],tsizem=[${tsizem}M],judgesize=[${judgesize}M],needDoFlag=[${needDoFlag}]!"

    local curcolnums
    local startonedel="${tonecedelete}"
    local i=0
    while [ ${needDoFlag} -eq 1 ]
    do
        if [ ${i} -eq 0 ];then
            F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|in while loop file[${tfileback}],init_size_m=[${initsizem}M],tsizem=[${tsizem}M],judgesize=[${judgesize}M],needDoFlag=[${needDoFlag}]!"
            i=1
        fi
        curcolnums=$(wc -l "${tfileback}" 2>/dev/null |awk '{print $1}' 2>/dev/null)
        [ -z "${curcolnums}" ] && curcolnums=0
        tonecedelete=$(echo "scale=3;((${cursizem} - ${judgesize})/${cursizem}) * ${curcolnums}"|bc|sed 's/\.[0-9]*$//g')
        [ -z "${tonecedelete}" ] && tonecedelete=0

        [ ${tonecedelete} -lt ${startonedel} ] && tonecedelete=${startonedel}

        sed -i "1,${tonecedelete} d" "${tfileback}"
        ret=$?
        if [ ${ret} -ne 0 ];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|[ sed -i 1,${tonecedelete} d ${tfileback} ] return  error!"
            return 1
        fi

        cursizem=$(echo "scale=3;$(stat -c %s ${tfileback})/(1024*1024)"|bc)
        needDoFlag=$(echo "${cursizem} > ${judgesize}"|bc)
        F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|in while loop file[${tfileback}],init_size_m=[${initsizem}M],cur_size_m=[${cursizem}M],needDoFlag=[${needDoFlag}]!"
    done

    if [ ${initFlag} -eq 1 ];then
        local tendseconds=$(date +%s)
        local runseconds=$(echo "${tendseconds} - ${tbegineseconds}"|bc)
        F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|delete file [ ${tfileback} ] init_size_m=[${initsizem}M],cur_size_m=[${cursizem}M] elapsed time [ ${runseconds} ] seconds!\n\n"
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


function F_shHaveRunThenExit()  #Exit if a script is already running
{
    if [ $# -lt 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|Function input arguments are less than 1!\n"
        exit 1
    fi
    
    local pname="$1"
    local tmpShPid; 
    local tmpShPNum

    tmpShPid=$(pidof -x ${pname})
    tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
    if [ ${tmpShPNum} -gt 1 ]; then
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|script [${pname}] has been running this startup exit,pidNum=[$tmpShPNum],pid=[${tmpShPid}]!\n"
        exit 0
    fi

    return 0
}

function F_rmExpiredFile() #call eg: F_rmExpiredFile "path" "days" OR F_rmExpiredFile "path" "days" "files"
{
    [ $# -ne 2 ] && [ $# -ne 3 ] && return 1
    [ ! -d "${tpath}" ] && return 2

    local tpath="$1" ; local tdays="$2"

    [ $(F_isDigital "${tdays}") = "0" ] && tdays=1

    local tname="*"
    [ $# -eq 3 ] && tname="$3"

    local tnum=0
    tnum=$(find "${tpath}" -name "${tname}" -type f -mtime +${tdays} -print 2>/dev/null|wc -l)
    [ ${tnum} -eq 0 ] && return 0

    find "${tpath}" -name "${tname}" -type f -mtime +${tdays} -print0 2>/dev/null|xargs -0 rm -rf

    return 0
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

    return 0
}


function F_convertVLineToSpace() #Convert vertical lines to spaces
{
    [ $# -lt 1 ] && echo "" && return 0
    echo $(echo "$1"|tr -d "[\040\t\r\n]"|tr -s "|" "\040") && return 0
}

function F_judgeFileOlderXSec() # return 0:false; 1:ture
{
    [ $# -lt 2 ] && echo "0" && return 0
    [ ! -f "$1" ] && echo "0" && return 0
    [ $(F_isDigital "$2") = "0" ] && echo "0" && return  0

    local tFile="$1" ; local tScds="$2"

    local tFscds=0; local trueFlag=0; local curScds=0;

    tFscds=$(stat -c %Y ${tFile})
    curScds=$(date +%s)
    trueFlag=$(echo "( ${curScds} - ${tFscds} ) >= ${tScds}"|bc)

    [ ${trueFlag} -eq 1 ] && echo "1" && return 1

    echo "0" && return 0
}

