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


#call eg: F_reduceFileSize "/zfmd/out_test.csv" "4"
function F_reduceFileSize()
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

    F_reduceFileSize "/home/fusky/tmp/t/out_test.csv" "4"

    return 0
}


main()
{
    F_test
    return 0
}
main


