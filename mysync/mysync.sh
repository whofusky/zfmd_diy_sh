#!/bin/bash
#
################################################################################
#
#author: fushikai
#date  : 2023-02-28_14:22:51
#desc  :
#        根据脚本的同级目录下有配置文件.mycfg配置的源文件夹与目标文件夹
#        内容进行同步(完全相同)
#
################################################################################
#


versionNo="v20.01.000"

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

logDir="${runDir}/log"
logFile="${logDir}/${onlyShPre}.log"

cfgFile="${runDir}/.mycfg"
tmpFile="${runDir}/.tmpfile"
versionFile="${runDir}/version.txt"


##################################################
#Define some global variables used by the script
##################################################
do_type_nums=0; src_dir_nums=0; dst_dir_nums=0;
curUser=$(whoami)

lclDir=""; rmtDir=""; userName=""; userPwd=""; tPort="";
tIp="";    tnum="";   tType="";    srcStr="";   dstStr="";
tmpStr="";


[ ! -d "${logDir}" ] && mkdir -p "${logDir}"



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


function F_writeVersion()
{
    echo "">"${versionFile}"
    echo "version: ${versionNo}" >>"${versionFile}"
    echo "runtime: $(date +%F_%T.%N)" >>"${versionFile}"
    echo "">>"${versionFile}"
}


function F_myExit()
{
    F_writeLog "$INFO" "\n"
    F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|[${onlyShName}] Exit normally after receiving the signal!"
    F_writeLog "$INFO" "\n"
    exit 0
}


function F_isDigital() # return 1: digital; 0: not a digital
{
    [ $# -ne 1 ] && echo "0" && return 0

    if [ $(echo "$1"|sed -n '/\(^[0-9]$\|^[1-9][0-9]\+$\)/p'|wc -l) -gt 0 ];then 
        echo "1" && return 1
    fi

    echo "0" && return 0
}

function F_convertVLineToSpace() #Convert vertical lines to spaces
{
    [ $# -lt 1 ] && echo "" && return 0
    echo $(echo "$1"|tr -d "[\040\t\r\n]"|tr -s "|" "\040") && return 0
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

    find "${tpath}" -name "${tname}" -type f -mtime +${tdays} -print0 2>/dev/null|xargs -0 rm -rf

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

function F_notDirExit() #call eg: notDirExit "file1" "file2" ... "filen"
{
    [ $# -lt 1 ] && return 0
    local tmpS
    while [ $# -gt 0 ]
    do
        tmpS="$1"
        if [ ! -d "${tmpS}" ];then
            F_writeLog "$ERROR" "dir [${tmpS}] does not exist!"
            exit 1
        fi
        shift
    done
    return 0
}

function F_chkSptRmtAddr()
{
    if [ $# -lt 3 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}| input para num less than 3"
        exit 1
    fi
    local tTipStr rmtStr chkFlag tnum ret
    tTipStr="$1"; rmtStr="$2"; chkFlag="$3";
    tnum=$(echo "${rmtStr}"|awk -F'@' '{print NF}')
    if [ ${tnum} -ne 4 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}| tTipStr=[${tTipStr}] format error,should be:用户名@密码@ssh端口@ip:路径"
        exit 2
    fi

    userName=$(echo "${rmtStr}"|cut -d'@' -f 1)
    userPwd=$(echo "${rmtStr}"|cut -d'@' -f 2)
    tPort=$(echo "${rmtStr}"|cut -d'@' -f 3)
    tmpStr=$(echo "${rmtStr}"|cut -d'@' -f 4)
    tnum=$(echo "${tmpStr}"|awk -F':' '{print NF}')
    if [ ${tnum} -ne 2 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}| tTipStr=[${tTipStr}] format error,should be:用户名@密码@ssh端口@ip:路径"
        exit 3
    fi
    tIp=$(echo "${tmpStr}"|cut -d':' -f 1)
    rmtDir=$(echo "${tmpStr}"|cut -d':' -f 2)

    if [ "x${chkFlag}" != "1x" ];then
        return 0
    fi

    which nc >/dev/null 2>&1
    if [ $? -eq 0 ];then
        nc -vz -w 2 ${tIp} ${tPort} >/dev/null 2>&1
        if [ $? -ne 0 ];then
            F_writeLog $ERROR "${LINENO}|${FUNCNAME}| tTipStr=[${tTipStr}] [${tIp}:${tPort}] network failure"
            exit 3
        fi
    fi

    sshpass -p "${userPwd}" ssh -o StrictHostKeyChecking=no -p ${tPort} ${userName}@${tIp} "ls -d ${rmtDir}" >/dev/null 2>${tmpFile}
    ret = $?
    if [ ${ret} -eq 5 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}| tTipStr=[${tTipStr}] 用户名或密码错误"
        exit 3
    elif [ ${ret} -ne 0 ];then
        tmpStr=$(cat ${tmpFile})
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}| tTipStr=[${tTipStr}] ${tmpStr}"
        exit 3
    fi

}

function F_cfgFileCheck()
{

    if [ ! -e "${cfgFile}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not exist!!\n"
        exit 1
    fi


    #load cfg file
    . ${cfgFile}


    do_type_nums=${#g_do_type[*]}; src_dir_nums=${#g_src_dir[*]};
    dst_dir_nums=${#g_dst_dir[*]};
    
    if [ ${do_type_nums} -lt 1 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not have g_do_type!\n"
        exit 1
    fi

    if [[ ${do_type_nums} -ne ${src_dir_nums} || ${do_type_nums} -ne ${dst_dir_nums} ]];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set #g_do_type[x],#g_src_dir[x],#g_dst_dir[x] 's number not eq !\n"
        exit 1
    fi

    local i=0
    for((i=0;i<${do_type_nums};i++)); do
        if [[ "x${g_do_type[$i]}" != "xlocal" && "x${g_do_type[$i]}" != "xget" && "x${g_do_type[$i]}" != "xput" ]];then
            F_writeLog $ERROR "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] g_do_type[$i]=[${g_do_type[$i]}],not equal to get,put,local "
            exit 1
        fi

        if [ "x${g_do_type[$i]}" == "xlocal" ];then
            F_notDirExit "${g_src_dir[$i]}" "${g_dst_dir[$i]}"
        elif [ "x${g_do_type[$i]}" == "xget" ];then
            F_chkSptRmtAddr "g_src_dir[$i]" "${g_src_dir[$i]}" "1"
            F_notDirExit  "${g_dst_dir[$i]}"
        elif [ "x${g_do_type[$i]}" == "xput" ];then
            F_notDirExit  "${g_src_dir[$i]}"
            F_chkSptRmtAddr "g_dst_dir[$i]" "${g_dst_dir[$i]}" "1"
        fi
    done

}

function F_addSlashEnd()
{
    [ $# -ne 1 ] && return 1
    if [ $(echo "$1"|sed -n '/\/\s*$/p'|wc -l) -eq 0 ];then
        echo "$1"|sed 's/\s*$/\//'
    else
        echo "$1"
    fi
}

function F_rmtSync()
{
    #get
    #sshpass -p Zfmd_wpf20 rsync -vr --size-only -e "ssh -p 22 -o StrictHostKeyChecking=no" --delete root@192.168.0.51:/root/fusk/d1/ /root/fusk/d1
    #put
    #sshpass -p Zfmd_wpf20 rsync -vr --size-only -e "ssh -p 22 -o StrictHostKeyChecking=no" --delte /root/fusk/d1 root@192.168.0.51:/root/fusk/d1

    local curSrcStr curDstStr tOption allFlag
    tOption="-vr --size-only" ; allFlag=0

    if [[ "x${tType}" == "xget" ]];then
        F_chkSptRmtAddr "${srcStr}" "${srcStr}" "0"
        curSrcStr="${userName}@${tIp}:${rmtDir}"
        curDstStr="${dstStr}"
        if [ "x${userName}" = "x${curUser}" ];then
            allFlag=1
        elif [ "x${userName}" = "xroot" ];then
            id "${userName}" >/dev/null 2>&1
            [ $? -eq 0 ] && allFlag=1
        fi
    elif [[ "x${tType}" == "xput" ]];then
        F_chkSptRmtAddr "${dstStr}" "${dstStr}" "0"
        curSrcStr="${srcStr}"
        curDstStr="${userName}@${tIp}:${rmtDir}"
        if [ "x${userName}" = "x${curUser}" ];then
            allFlag=1
        elif [ "x${userName}" = "xroot" ];then
            local tUser=$(stat -c %U "${curSrcStr}")
            [ "x${userName}" = "x${tUser}" ] && allFlag=1
        fi
    else
        return 0
    fi

    curSrcStr=$(F_addSlashEnd "${curSrcStr}")

    [ ${allFlag} -eq 1 ] && tOption="-av"

    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|sshpass -p \"${userPwd}\" rsync ${tOption} -e \"ssh -p ${tPort} -o StrictHostKeyChecking=no\" --delete ${curSrcStr} ${curDstStr} >> \"${logFile}\" 2>&1"

    if [ "x${debug_falg}" != "x1" ];then
        F_writeLog $INFO "[${tType}]:[${curSrcStr}] --sync--> [${curDstStr}] begine"
        if [ ${print_to_stdin_flag} -eq 1 ];then
            sshpass -p "${userPwd}" rsync ${tOption} -e "ssh -p ${tPort} -o StrictHostKeyChecking=no" --delete ${curSrcStr} ${curDstStr} 
        else
            sshpass -p "${userPwd}" rsync ${tOption} -e "ssh -p ${tPort} -o StrictHostKeyChecking=no" --delete ${curSrcStr} ${curDstStr} >> "${logFile}" 2>&1
        fi
        F_writeLog $INFO "[${tType}]:[${curSrcStr}] --sync--> [${curDstStr}] end"
    fi

}


function F_localSync()
{
    #rsync -vr --size-only --delte /root/fusk/d1 /root/fusk/d2

    srcStr=$(F_addSlashEnd "${srcStr}")
    local tOption allFlag tUser

    tOption="-vr --size-only"
    allFlag=0
    tUser=$(stat -c %U "${srcStr}")

    if [ "x${tUser}" = "x${curUser}" ];then
        allFlag=1
    elif [ "xroot" = "x${curUser}" ];then
        allFlag=1
    fi

    [ ${allFlag} -eq 1 ] && tOption="-av"

    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| rsync ${tOption} --delete ${srcStr} ${dstStr} >> \"${logFile}\" 2>&1"

    if [ "x${debug_falg}" != "x1" ];then
        F_writeLog $INFO "[${tType}]:[${srcStr}] --sync--> [${dstStr}] begine"
        if [ ${print_to_stdin_flag} -eq 1 ];then
            rsync ${tOption} --delete ${srcStr} ${dstStr} 
        else
            rsync ${tOption} --delete ${srcStr} ${dstStr}  >>"${logFile}" 2>&1
        fi
        F_writeLog $INFO "[${tType}]:[${srcStr}] --sync--> [${dstStr}] end"
    fi

}


function F_doSync()
{
    local i
    for((i=0;i<${do_type_nums};i++));do

        tType="${g_do_type[$i]}"
        srcStr="${g_src_dir[$i]}"
        dstStr="${g_dst_dir[$i]}"

        if [[ "x${g_do_type[$i]}" != "xlocal" && "x${g_do_type[$i]}" != "xget" && "x${g_do_type[$i]}" != "xput" ]];then
            F_writeLog $ERROR "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] g_do_type[$i]=[${g_do_type[$i]}],not equal to get,put,local "
            exit 1
        fi

        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|g_do_type[$i]=[${g_do_type[$i]}],g_src_dir[$i]=[${g_src_dir[$i]}],g_dst_dir[$i]=[${g_dst_dir[$i]}] "

        if [[ "x${g_do_type[$i]}" == "xlocal" ]];then
            F_localSync
        else
            F_rmtSync
        fi

    done
}


#Some checks that the program needs to run
#
function F_check()
{
    [ ! -d "${logDir}" ] && mkdir -p "${logDir}"

    F_reduceFileSize "${logFile}" "6"

    #Exit if a script is already running
    F_shHaveRunThenExit "${onlyShName}"

    F_checkSysCmd  "bc"  "cut" "rsync"

    which sshpass >/dev/null 2>&1
    if [ $? -ne 0 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|系统中还未安装sshpass工具请先用root用户执行tools_src/install_sshpass.sh脚本进行安装!"
        exit 2
    fi

    F_cfgFileCheck

    return 0
}



#Delete some expired files according to the configuration of the 
#configuration file
#
function F_delSomeExpireFile()
{

    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|doing [${backDir}]...!"

    #back file deletion
    F_rmExpiredFile "${backDir}" "1"

    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|do [${backDir}] complete!"

    return 0
}



#Test function, abnormal logic
#
function F_printTest()
{
    local i=0
    #F_fuskytest
    #local aa=$(F_addSlashEnd "${inTest}")
    #F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|inTest=[${inTest}],aa=[${aa}]"

    return 0
}



trap "F_myExit"  1 2 3 9 11 13 15


#Main function logic
main()  
{

    #F_printTest
    #return 0

    F_writeVersion

    F_check
    F_doSync

    #F_delSomeExpireFile


    return 0
}

main

exit 0



