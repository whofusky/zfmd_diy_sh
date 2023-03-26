#!/bin/bash
#
##############################################################################
#
#
#
#
##############################################################################
#




#function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
#{
#
#    #NOOUT=0 ; levelName[0]="NOOUT";
#    #ERROR=1 ; levelName[1]="ERROR";
#    #INFO=2  ; levelName[2]="INFO" ;
#    #DEBUG=3 ; levelName[3]="DEBUG";
#    #
#    #OUT_LOG_LEVEL=${DEBUG}
#    #
#    #logDir="/home/fusky/mygit/zfmd_diy_sh/wk_tmp/log"
#    #logFile="${logDir}/t.log"
#
#
#    #    [ -z "${NOOUT}" ] && NOOUT=0               
#    #    [ -z "${ERROR}" ] && ERROR=1               
#    #    [ -z "${INFO}" ]  && INFO=2               
#    #    [ -z "${DEBUG}" ] && DEBUG=3               
#    #    [ -z "${levelName[0]}" ] && levelName[0]="NOOUT"               
#    #    [ -z "${levelName[1]}" ] && levelName[1]="ERROR"               
#    #    [ -z "${levelName[2]}" ] && levelName[2]="INFO"               
#    #    [ -z "${levelName[3]}" ] && levelName[3]="DEBUG"               
#    #
#    #    [ -z "${OUT_LOG_LEVEL}" ] && OUT_LOG_LEVEL=${DEBUG}
#
#
#
#    [ $# -lt 2 ] && return 1
#
#    #特殊调试时用
#    local print_to_stdin_flag=1  # 0:可能输出到日志文件; 1: 输出到屏幕
#
#    #input log level
#    local i="${1-3}"   
#    
#
#    ##debug to open this
#    #[ $(echo "${i}"|sed -n '/^[0-9]*$/p' |wc -l) -eq 0 ] && i=${DEBUG}
#    #[ $(echo "${NOOUT}<=${i} && ${i}<=${DEBUG}"|bc) -eq 0 ] && i=${DEBUG}
#
#
#    [ ${i} -gt ${OUT_LOG_LEVEL:=3} ] && return 0
#
#    local puttxt="$2"
#
#    # 1.换行符;2.空; 3.多个-;
#    # 以上作一情况 则直接输出而不在输出内容之前添加日期等内容
#    local tflag=$(echo "${puttxt}"|sed -n '/^\s*\(\(\\n\)\+\)*$\|^\s*-\+$/p'|wc -l)
#
#    #没有设置日志文件时默认也是输出到屏幕
#    [ -z "${logFile}" ] && print_to_stdin_flag=1
#
#    local timestring
#    [ ${tflag} -eq 0 ] && timestring="$(date +%F_%T.%N)"
#
#    if [ ${print_to_stdin_flag} -eq 1 ];then
#        if [ ${tflag} -gt 0 ];then
#            echo -e "${puttxt}"
#        else
#            echo -e "${timestring}|${levelName[$i]}|${puttxt}"
#        fi
#        return 0
#    fi
#
#
#    [ -z "${logDir}" ] &&  logDir="${logFile%/*}"
#    if [ "${logDir}" = "${logFile}" ];then
#        logDir="./"
#    elif [ ! -d "${logDir}" ];then
#        mkdir -p "${logDir}"
#    fi
#
#    if [ ${tflag} -gt 0 ];then
#        echo -e "${puttxt}" >> "${logFile}"
#    else
#        echo -e "${timestring}|${levelName[$i]}|${puttxt}" >> "${logFile}"
#    fi
#
#
#    #return 0
#}




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


function F_rmFile() #call eg: F_rmFile "file1" "file2" ... "$filen"
{
    [ $# -lt 1 ] && return 0

    while [ $# -gt 0 ]
    do
        [ -e "$1" ] && rm -rf "$1"
        shift
    done

    #return 0
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

    #return 0
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

    #return 0
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


function F_setKeyValInFile() #use: F_setKeyValInFile <file> "key=val"
{
    if [ $# -lt 2 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|input parameters number less than 2 !"
        return 1
    fi

    local tFile="$1"
    local tKeyVal=$(echo "$2"|sed 's/\s\+=/=/g;s/=\s\+/=/g')
    local tKey=$(echo "${tKeyVal}"|awk -F'=' '{print $1}'|sed 's/^\s\+//g;s/\s\+$//g')
    if [ -z "${tKey}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|input parameters 2 format error!"
        return 1
    fi

    if [ ! -f "${tFile}" ];then
        local tdir=$(F_getPathName "${tFile}")
        if [ ! -d "${tdir}" ];then 
            F_writeLog $ERROR "${LINENO}|${FUNCNAME}|file[ ${tFile} ] not exist!"
            return 1
        fi
        echo "${tKeyVal}">>"${tFile}"
        return 0
    fi

    local tnum=$(sed -n "/^\s*${tKey}\b/=" "${tFile}")
    if [ ! -z "${tnum}" ];then
        local tVal=$(echo "${tKeyVal}"|awk -F'=' '{print $2}'|sed 's/^\s\+//g;s/\s\+$//g')
        local tno=$(echo "${tnum}"|head -1)
        if [ $(echo "${tnum}"|wc -l) -gt 1 ];then
            local ttno=$(echo "${tno} + 1"|bc)
            sed -i "${ttno},$ {/^\s*${tKey}\b/ d}" "${tFile}"
        fi
        #sed -i "/^\s*${tKey}\b/ d" "${tFile}"
        tVal=$(echo "${tVal}"|sed 's/\//\\\//g')
        sed -i "${tno} s/^\s*${tKey}\b\s*=[^=]*/${tKey}=${tVal}/g" "${tFile}"
    else
        echo "${tKeyVal}">>"${tFile}"
    fi

    return 0
}




function F_getKeyValInFile() #use: F_getKeyValInFile <file> "key"
{
    if [ $# -lt 2 ];then
        #F_writeLog $ERROR "${LINENO}|${FUNCNAME}|input parameters number less than 2 !"
        echo ""
        return 1
    fi

    local tFile="$1"
    local tKey=$(echo "$2"|sed 's/^\s\+//g;s/\s\+$//g')

    if [ ! -f "${tFile}" ];then
        #F_writeLog $ERROR "${LINENO}|${FUNCNAME}|file[ ${tFile} ] not exist!"
        echo ""
        return 1
    fi

    if [ -z "${tKey}" ];then
        #F_writeLog $ERROR "${LINENO}|${FUNCNAME}|input parameters 2 format error!"
        echo ""
        return 1
    fi
    local tVal=$(sed -n "/^\s*${tKey}\s*=/p" "${tFile}"|tail -1|awk -F'=' '{print $2}'|sed 's/^\s*"//g;s/"\s*$//g')
    echo "${tVal}"

    return 0
}

#function F_notFileExit() #call eg: notFileExit "file1" "file2" ... "filen"
#{
#    [ $# -lt 1 ] && return 0
#    local tmpS
#    while [ $# -gt 0 ]
#    do
#        tmpS="$1"
#        if [ ! -f "${tmpS}" ];then
#            F_writeLog "$ERROR" "file [${tmpS}] does not exist!"
#            exit 1
#        fi
#        shift
#    done
#    return 0
#}


function F_notDirExit() #call eg: notDirExit "file1" "file2" ... "filen"
{
    [ $# -lt 1 ] && return 0
    local tmpS
    while [ $# -gt 0 ]
    do
        tmpS="$1"
        if [ ! -d "${tmpS}" ];then
            F_writeLog "$ERROR" "directory [${tmpS}] does not exist!"
            exit 1
        fi
        shift
    done
    return 0
}



function F_chown_R() #F_chown_R "${OWNER}[:${GROUP}]"  "obj"
{
    [ $# -ne 2 ] && return 1
    
    [ -z "$1" ] && return 0
    [ ! -e "$2" ] && return 0
    
    local tUser tGroup edObj
    tUser=$(echo "$1"|awk -F':' '{print $1}')
    tGroup=$(echo "$1"|awk -F':' '{print $2}')
    edObj="$2"
    
    #define the file to be edited
    local shadFile pwdFile grpFile
    shadFile="/etc/shadow"
    pwdFile="/etc/passwd"
    grpFile="/etc/group"

    local uzfnum gnum
    #get user status in existing systems
    uzfnum=$(egrep -w "^${tUser}" ${pwdFile}|wc -l)
    [ ${uzfnum} -eq 0 ] && return 0

    #get group status in existing systems
    if [ ! -z "${tGroup}" ];then
        gnum=$(egrep -w "^${tGroup}" ${grpFile}|wc -l)
        [ ${gnum} -eq 0 ] && return 0
    fi
    
    local objGroup objUser
    objGroup=$(stat --format=%G "${edObj}")
    [ ! -z "${tGroup}" ] && objUser=$(stat --format=%U "${edObj}")

    if [ ! -z "${tGroup}" ]; then
        if [[ "$objGroup" != "${tGroup}" || "$objUser" != "${tUser}" ]];then
            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|chown -R ${tUser}:${tGroup} ${edObj}"
            chown -R ${tUser}:${tGroup} "${edObj}"
        fi
    else
        if [[ "$objUser" != "${tUser}" ]];then
            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|chown -R ${tUser} ${edObj}"
            chown -R ${tUser} "${edObj}"
        fi
    fi
}

function F_chown_upn()  #F_chown_upn "${OWNER}[:${GROUP}]"  "obj" "modify_parent_directory_num"
{
    [ $# -ne 3 ] && return 1

    [ -z "$1" ] && return 0
    [ ! -e "$2" ] && return 0
    
    local edObj upDirNum tname i
    
    edObj="$2"
    if [ ! -e ${edObj} ];then
        return 0
    fi
    
    upDirNum="$3"
    F_chown_R "$1" ${edObj}
    [ $(F_isDigital "${upDirNum}") = "0" ] && upDirNum=1

    for ((i=1;i<${upDirNum};i++));do
        tname=$(dirname ${edObj})
        F_chown_R "$1" ${tname}
        edObj=${tname}
    done
    
}

function F_chown_upname()  #F_chown_upname "${OWNER}[:${GROUP}]"  "obj" "upto_parent_directory_name"
{
    [ $# -ne 3 ] && return 1

    [ -z "$1" ] && return 0
    [ ! -e "$2" ] && return 0
    
    local edObj lastName i fnum
    
    edObj="$2"
    lastName="$3"
    F_chown_R "$1" "${edObj}"

    fnum=$(echo "${edObj}"|sed -n "/\<${lastName}\>/p"|wc -l)
    [ ${fnum} -eq 0 ] && return 0

    while [ "$(basename "${edObj}")" != "${lastName}" ];do
        edObj=$(dirname "${edObj}")
        F_chown_R "$1" "${edObj}"
    done

}


function F_chmod_R() #chmod -R $1  $2
{
    [ $# -ne 2 ] && return 1
    [ -z "$1" ] && return 0
    [ ! -e "$2" ] && return 0

    local perVal edObj fPerVal

    perVal="$1"
    edObj="$2"
    
    fPerVal=$(stat --format=%a ${edObj})
    if [[  ! -z "${fPerVal}" && "${fPerVal}" != "${perVal}" ]];then
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|chmod -R ${perVal} ${edObj}"
        chmod -R ${perVal} ${edObj}
    fi
}



function F_get_lsattr_i() #get immutable  (i) file attributes
{
    [ $# -ne 1 ] && return 1
    [ ! -e "${1}" ] && return 2

    echo "$(lsattr -d "${1}"|awk '{print $1}'|cut -c5)"
}


function F_chattr_add_i() #add  immutable  (i) file attributes on a Linux file system
{
    [ $# -ne 1 ] && return 1
    local fOrd tAtrtChr ret
    fOrd="$1"
    tAtrtChr=$(F_get_lsattr_i "${fOrd}") ; ret=$?
    [ ${ret} -ne 0 ] && return ${ret}

    if [ "${tAtrtChr}" == "-" ];then
        #F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|chattr +i ${fOrd}"
        chattr +i "${fOrd}"
    fi
}


function F_chattr_del_i() #delete  immutable  (i) file attributes on a Linux file system
{
    [ $# -ne 1 ] && return 1
    local fOrd tAtrtChr ret
    fOrd=$1
    tAtrtChr=$(F_get_lsattr_i "${fOrd}") ; ret=$?
    [ ${ret} -ne 0 ] && return ${ret}

    if [ "${tAtrtChr}" == "i" ];then
        #F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|chattr -i ${fOrd}"
        chattr -i "${fOrd}"
    fi
}


function F_updateFile() #if the file $1 is different from the md5 code of $2 or $2 does not exist then cp $1 $2
{
    [ $# -ne 2 -a $# -ne 3 ] && return 2

    local cmdstat
    which md5sum &>/dev/null ; cmdstat=$?
    [ ${cmdstat} -ne 0 ] && return 1
    
    local srcFile dstFile bakdir
    srcFile=$1
    dstFile=$2
    [ $# -eq 3 ] && bakdir="$3"
    
    if [ ! -f ${srcFile} ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|file [${srcFile}] does not exist!" 
        return 3
    fi
    if [ ! -f ${dstFile} ];then
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|cp ${srcFile} ${dstFile}" 
        cp "${srcFile}" "${dstFile}"
        return 0
    fi
    
    local srcmd5 dstmd5
    srcmd5=$(md5sum "${srcFile}"|awk '{print $1}')
    dstmd5=$(md5sum "${dstFile}"|awk '{print $1}')

    #F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|srcmd5=[${srcmd5}],dstmd5=[${dstmd5}]" 

    local iflag ret tAtrtChr

    #md5sum 值不一样则需要对目标文件进行更新
    if [[ "x${srcmd5}" != "x${dstmd5}" ]];then
        iflag=0 
        tAtrtChr=$(F_get_lsattr_i ${dstFile}) ; ret=$?
        if [ ${ret} -ne 0 ];then
            iflag=0 
        elif [ "${tAtrtChr}" == "i" ];then
            iflag=1
            F_chattr_del_i "${dstFile}"
        fi
        
        local bakF tbakdir timestamp
        #有备份目录则对原文件进行备份
        if [ -d "${bakdir}" ];then
            bakF=$(getFnameOnPath "${dstFile}") ; ret=$?
            if [ ${ret} -eq 0 ];then
                tbakdir=$(echo "${bakdir}"|sed 's/\/$//g')
                timestamp=$(date +%Y%m%d%H%M%S)
                cp "${dstFile}" "${tbakdir}/${bakF}_${timestamp}"
                F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|back following: cp ${dstFile} ${tbakdir}/${bakF}_${timestamp}" 
            fi
        fi

        cp "${srcFile}" "${dstFile}"
        if [ $? -ne 0 ];then
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|rm -rf ${dstFile}" 
            \rm -rf "${dstFile}"
            cp "${srcFile}" "${dstFile}"
        fi

        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|back following:cp ${srcFile} ${dstFile}" 

        if [ ${iflag} -eq 1 ];then
            F_chattr_add_i "${dstFile}"
        fi

        return 0
    fi
}



function F_chg_usr_pwd() #Change the password of user $1 with plaintext password $2
{
    [ $# -ne 2 ] && return 1
    
    #local inUser inPwd shadFile pwdFile grpFile uNum
    local inUser inPwd pwdFile uNum

    inUser="$1"
    inPwd="$2"
    
    #define the file to be edited
    #shadFile="/etc/shadow"
    #grpFile="/etc/group"

    pwdFile="/etc/passwd"
    
    uNum=$(egrep -w "^${inUser}" ${pwdFile}|wc -l)
    [ ${uNum} -lt 1 ] && return 1

    #################change password, "openssl passwd -1"
    #echo 'chpasswd -e '
    #rtPwNum=$(egrep -w "^${inUser}" ${shadFile}|grep -w "${inPwd}"|wc -l)
    #if [[ $rtPwNum -eq 0 ]];then

    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|change the password of the [${inUser}] user" 

    echo "${inUser}:${inPwd}"|chpasswd 
    [ $? -ne 0 ] && return $?

}


function F_mkdirFromXml()  #take all the node values named $2 from the xml file $1 to create the directory,the element value of the xml file must be on one line
{
    [ $# -ne 2 ] && return 1

    local xFile xnodeName tnaa
    xFile="$1"
    xnodeName="$2"
    if [ ! -f "${xFile}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|file [${xFile}] not exist!" 
        return 2
    fi 

    sed -n "/^[ \t]*<[ \t]*\<${xnodeName}\>[ \t]*>.*<[ \t]*\/\<${xnodeName}\>[ \t]*>/p" ${xFile}|awk -F"[><]" '{ if(NF>=5){print $3} }'|while read tnaa
    do
        #F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|----${tnaa}" 
        F_mkpDir "${tnaa}"
    done

}



function F_group_add() #groupadd $1 if there is no $1
{
    
    [ $# -ne 1 ] && return 1

    local grpname grpFile gnum
    grpname="$1"
    grpFile="/etc/group"

    if [ ! -e "${grpFile}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|file [${grpFile}] not exist!" 
        return 2
    fi

    gnum=$(egrep -w "^${grpname}" ${grpFile}|wc -l)
    [ ${gnum} -gt 0 ] && return 0

    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|groupadd ${grpname}" 
    groupadd "${grpname}"

}


function F_mdify_usrgrp() # add user or change user's group; F_mdify_usrgrp $user $group OR F_mdify_usrgrp $user $group $addgroup
{
    #F_mdify_usrgrp user group
    #or F_mdify_usrgrp user group addGroup
    [ $# -ne 2 -a $# -ne 3 ] && return 1

    local inputNum pwdFile grpFile
    inputNum=$#

    #shadFile=/etc/shadow
    pwdFile=/etc/passwd
    grpFile=/etc/group

    if [ ! -e "${grpFile}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|file [${grpFile}] not exist!" 
        return 2
    fi
    if [ ! -e "${pwdFile}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|file [${pwdFile}] not exist!" 
        return 3
    fi

    local uname gname unum gnum Gname
    uname="$1"
    gname="$2"
    [ ${inputNum} -eq 3 ] && Gname="$3"
    
    unum=$(egrep -w "^${uname}" ${pwdFile}|wc -l)
    gnum=$(egrep -w "^${gname}" ${grpFile}|wc -l)
    
    if [ ${gnum} -eq 0 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|[${gname}] not exist in file [${grpFile}]!" 
        return 4
    fi

    local tgnum degrp
    if [ ! -z "${Gname}" ];then
        tgnum=$(egrep -w "^${Gname}" ${grpFile}|wc -l)
        if [ ${tgnum} -eq 0 ];then
            F_writeLog $ERROR "${LINENO}|${FUNCNAME}|[${Gname}] not exist in file [${grpFile}]!" 
            return 5
        fi
    fi

    #对应用户不存在
    if [ ${unum} -eq 0 ];then

        #有附加组
        if [ ! -z "${Gname}" ];then
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|useradd ${uname} -g ${gname} -G ${Gname}"
            useradd "${uname}" -g "${gname}" -G "${Gname}"
        else
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|useradd ${uname} -g ${gname}"
            useradd "${uname}" -g "${gname}"
        fi
    else

        #取用户原来的组名
        degrp=$(groups ${uname} 2>/dev/null|awk -F: '{print $2}'|awk '{print $1}'|tr "\040\011" "\0")
        if [ "${degrp}" != "${gname}" ];then
            #修改用户现在的用户组
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|usermod -g \"${gname}\" \"${uname}\""
            usermod -g "${gname}" "${uname}"
        fi

        local Gnum tgrps
        if [ ! -z "${Gname}" ];then

            Gnum=$(groups ${uname} 2>/dev/null|awk -F: '{print $2}'|awk -v atgroup="$Gname" '{for(i=2;i<=NF;i++){if($i==atgroup){print $i;break;}}}'|tr "\040\011" "\0"|wc -l)

            if [ ${Gnum} -eq 0 ];then
                tgrps=$(groups ${uname} 2>/dev/null|awk -F: '{print $2}'|awk -v atgroup="$Gname" '{for(i=2;i<=NF;i++){if($i!=atgroup){printf "%s,",$i;}}}'|tr "\040\011" "\0")
                if [ ! -z ${tgrps} ];then
                    Gname="${tgrps}${Gname}"
                fi
                F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|usermod -G \"${Gname}\" \"${uname}\""
                usermod -G "${Gname}" "${uname}"
            fi
        fi
    fi
}




##############################################################################
# 在系统配置文件中,设置以空格分隔的的一行值
#
#set the value of the configuration file;
#eg: setEnvOneVal ${file} "set" "encoding" "set encoding=utf-8"   '\"' 'positition_character'
#
#inpara:
#   [1] file_name
#   [2] 第一列值
#   [3] 第二列值定位字符(可以有通配特殊符号)
#   [4] 要添加的一整行内容值
#   [5] 注释符号
#   [6] 参考行定位字符串(此值用于定位在哪一行之后追加要设置的值)(可选参数)(可以使用sed可识别的正则表达符号)
#return:
#   0      要添加的内容已经存在
#   9      添加成功
#   其他值 失败
##############################################################################
function F_setEnvSpaceVal() 
{
    if [ $# -ne 5 -a $# -ne 6 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|input parameters num not eq 5 or 6"
        return 1
    fi

    local referenceLineStr edfile

    [ $# -eq 6 ] && referenceLineStr="$6"
    edfile=$1
    if [ ! -f ${edfile} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|file[${edfile}] not exist!"
        return 2
    fi

    local firstColumn secondColumnPosStr addLineContent commentSymbol speFlag

    firstColumn="$2"; secondColumnPosStr="$3";
    addLineContent="$4"; commentSymbol="$5";

    #F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|fusktest:secondColumnPosStr=[${secondColumnPosStr}]"
    #判断定位编辑行的字符串中是否有特殊字符(通配,正则语法)
    speFlag=$(echo "${secondColumnPosStr}"|grep "[^0-9a-zA-Z\.\_\-]"|wc -l)

    local haveCol_1 haveCol_1_2 haveComCol_1 haveComCol_1_2 

    #判断文件中是否存在要添加内容首列的内容
    haveCol_1=$(egrep "^\s*${firstColumn}\s+[^$]" ${edfile}|wc -l)

    #判断文件中是否存在要添加内容首列和第二列内容
    if [ ${speFlag} -gt 0 ];then
        haveCol_1_2=$(egrep "^\s*${firstColumn}\s+${secondColumnPosStr}" ${edfile}|wc -l)
    else
        haveCol_1_2=$(egrep "^\s*${firstColumn}\s+\<${secondColumnPosStr}\>" ${edfile}|wc -l)
    fi

    #判断文件中是否存在要添加内容首列的内容(注释掉的)
    haveComCol_1=$(egrep "^\s*${commentSymbol}\s*${firstColumn}\s+[^$]" ${edfile}|wc -l)

    #判断文件中是否存在要添加内容首列和第二列内容(注释掉的)
    if [ ${speFlag} -gt 0 ];then
        haveComCol_1_2=$(egrep "^\s*${commentSymbol}\s*${firstColumn}\s+${secondColumnPosStr}" ${edfile}|wc -l)
    else
        haveComCol_1_2=$(egrep "^\s*${commentSymbol}\s*${firstColumn}\s+\<${secondColumnPosStr}\>" ${edfile}|wc -l)
    fi


    #文件中存在要添加内容首列的内容
    if [[ ${haveCol_1} -gt 0 ]];then

        #文件中存在要添加的整行内容
        if [[ $(grep "^\s*${addLineContent}\s*$" ${edfile}|wc -l) -gt 0 ]];then
            return 0
        fi
        #文件中不存在要添加的整行内容

        #文件中存在要添加内容的第1列内容但不存在第2列值
        if [[ ${haveCol_1_2} -lt 1 ]];then

            #文件中存在注释掉的第1和第2列值
            if [[ ${haveComCol_1_2} -gt 0 ]];then

                #入参中定位第二列值的字符串有特殊字符(通配符等)
                if [ ${speFlag} -gt 0 ];then

                    #将当前行替换成要添加的行内容
                    sed "$(sed -n "/^\s*${commentSymbol}\s*${firstColumn}\s\+${secondColumnPosStr}/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
                else

                    #将当前行替换成要添加的行内容
                    sed "$(sed -n "/^\s*${commentSymbol}\s*${firstColumn}\s\+\<${secondColumnPosStr}\>/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
                fi

                F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change row=[${addLineContent}]"

            #文件中不存在注释掉的第1和第2列值
            else

                #在文件中所有已经存在的第1列值最后一行后添加新内容
                sed "$(sed -n "/^\s*${firstColumn}\s\+[^$]/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
                F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|add row=[${addLineContent}]"
            fi


        #文件中存在要添加内容的第1和第2列值
        else

            #将当前行替换成要添加的行内容
            if [ ${speFlag} -gt 0 ];then
                sed "$(sed -n "/^\s*${firstColumn}\s\+${secondColumnPosStr}/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
            else
                sed "$(sed -n "/^\s*${firstColumn}\s\+\<${secondColumnPosStr}\>/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
            fi

            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change row=[${addLineContent}]"
        fi

        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|edit file=[$edfile]"
        return 9
    fi

        
    #文件中不存在要添加内容首列的内容,但存在注释掉的首列内容
    if [[ ${haveComCol_1} -gt 0 ]];then

        #文件中存在注释掉的第1和第2列内容
        if [[ ${haveComCol_1_2} -gt 0 ]];then

            #将找到的第一行内容替换成新内容
            if [ ${speFlag} -gt 0 ];then
                sed "$(sed -n "/^\s*${commentSymbol}\s*${firstColumn}\s\+${secondColumnPosStr}/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
            else
                sed "$(sed -n "/^\s*${commentSymbol}\s*${firstColumn}\s\+\<${secondColumnPosStr}\>/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
            fi

            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change row=[${addLineContent}]"

        #文件中存在注释掉的第1但不存在第2列
        else

            #在注释掉的第1列内容所有行后添加新行内容
            sed "$(sed -n "/^\s*${commentSymbol}\s*${firstColumn}\s\+[^$]/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|add row=[${addLineContent}]"
        fi

        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|edit file=[$edfile]"
        return 9
    fi

    #文件中不存在要添加内容首列的内容,也不存在注释掉的首列内容

    local ttnum

    #空文件则直接将添加的内容追加到文件中
    ttnum=$(sed -n "/.*/=" ${edfile}|wc -l)
    if [ ${ttnum} -eq 0 ];then
        echo "${addLineContent}">>${edfile}
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|old [$edfile] is null,and add[${addLineContent}] to file!"
        return 9
    fi

    local posSpeFlag posnum

    #文件中不存在要添加内容首列的内容,也不存在注释掉的首列内容,所以需要在
    #源文件中追加内容

    # 有定位参考符号(需要把相应内容添加到参考符的行下)
    if [ ! -z "${referenceLineStr}" ];then

        #判断定位符是否有特殊含义字符
        posSpeFlag=$(echo "${referenceLineStr}"|grep "[^0-9a-zA-Z\.\_\-]"|wc -l)
        if [ ${posSpeFlag} -gt 0 ];then

            #是否能根据参考符找到相应参考位置
            posnum=$(sed -n "/${referenceLineStr}/=" ${edfile}|wc -l)

            if [ ${posnum} -gt 0 ];then

                #参考符对应的行下追加新内容
                sed "$(sed -n "/${referenceLineStr}/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
            else
                #文件末尾追加新内容
                sed "$(sed -n "/.*/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
            fi

        else

            #是否能根据参考符找到相应参考位置
            posnum=$(sed -n "/\<${referenceLineStr}\>/=" ${edfile}|wc -l)
            if [ ${posnum} -gt 0 ];then
                #参考符对应的行下追加新内容
                sed "$(sed -n "/\<${referenceLineStr}\>/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
            else
                #文件末尾追加新内容
                sed "$(sed -n "/.*/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
            fi
        fi

    #没有参考符参数
    else
        #文件末尾追加新内容
        sed "$(sed -n "/.*/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
    fi

    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|add row=[${addLineContent}]"
    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|edit file=[$edfile]"

    return 9
}



##############################################################################
# 在系统配置文件中,key=value;或 export key=value 或 export key 类型的值
#
#eg: F_setEnvKeyVal ${file} "export" "key" "value"   '#' 'positition_character'
# 注意value中的$或"需要用\符号转义
#
#inpara:
#   [1] file_name
#   [2] 前缀值(例如:export)
#   [3] key名称
#   [4] value值
#   [5] 注释符号
#   [6] 参考行定位字符串(此值用于定位在哪一行之后追加要设置的值)(可选参数)(可用sed识别的正则表达式)
#return:
#   0      要添加的内容已经存在
#   9      添加成功
#   其他值 失败
##############################################################################
function F_setEnvKeyVal() 
{
    if [ $# -ne 5 -a $# -ne 6 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|input parameters num not eq 5 or 6"
        return 1
    fi

    local edfile setPrefix setKey setVal setComment setLocator

    edfile="$1"; setPrefix="$2"; setKey="$3"; setVal="$4"; setComment="$5";
    [ $# -eq 6 ] && setLocator="$6"

    if [ ! -f ${edfile} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|file[${edfile}] not exist!"
        return 2
    fi

    if [  -z "${setKey}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|in para setKey is null!"
        return 3
    fi

    local haveCol_1_2 sameFlag haveComCol_1_2
    local addCnt locatorNo
    if [ ! -z  "${setPrefix}" ];then
        addCnt="${setPrefix} ${setKey}=${setVal}"
    else
        addCnt="${setKey}=${setVal}"
    fi

    #echo "fusktest=[${addCnt}]"

    #有前缀的时候,比如有 export
    if [ ! -z "${setPrefix}" ];then
        haveCol_1_2=$(egrep "^\s*${setPrefix}\s+\<${setKey}\>" ${edfile}|wc -l)

        #存在相同的前缀和相同的key
        if [ ${haveCol_1_2} -gt 0 ];then

            #已经有要添加的内容
            sameFlag=$(grep -x --fixed-strings "${addCnt}" "${edfile}"|wc -l)
            if [ ${sameFlag} -gt 0 ];then
                return 0
            fi

            #替换成要添加的值
            #echo "sed \"\$(sed -n \"/^\s*${setPrefix}\s\+${setKey}\b/=\" ${edfile}|sed -n '\$p')c${addCnt}\" -i ${edfile}    "
            sed "$(sed -n "/^\s*${setPrefix}\s\+${setKey}\b/=" ${edfile}|sed -n '$p')c${addCnt}" -i ${edfile}    
            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change file[${edfile}] row=[${addCnt}]"
            return 9
        fi

        #不存在相同的前缀和key

        #如果注释字符不为空:查一下是否有注释掉的前缀和key
        if [ ! -z "${setComment}" ];then
            haveComCol_1_2=$(egrep "^\s*${setComment}+\s*${setPrefix}\s+\<${setKey}\>" ${edfile}|wc -l)
            if [ ${haveComCol_1_2} -gt 0 ];then

                #在找到注释行的最后一行进行替换
                sed "$(sed -n "/^\s*${setComment}\+\s*${setPrefix}\s\+\b${setKey}\b/=" ${edfile}|sed -n '$p')c${addCnt}" -i ${edfile}    

                F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change file[${edfile}] row=[${addCnt}]"
                return 9
            fi
        fi

        #如果定位符不为空则查找定位符的位置
        if [ ! -z "${setLocator}" ];then
            locatorNo=$(sed -n "/${setLocator}/=" ${edfile}|sed -n '$p')
            #参考符对应的行下追加新内容
            if [ ! -z "${locatorNo}" ];then
                sed "${locatorNo}a${addCnt}" -i ${edfile}    
                F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|modify file[${edfile}] add row=[${addCnt}]"
                return 9
            fi
        fi

        #直接在文件末尾追加要添加的内容
        echo "${addCnt}">>"${edfile}"
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|modify file[${edfile}] add row=[${addCnt}]"
        return 9
    fi

    #没有前缀的情况

    local haveCol_1 haveComCol_1 haveComCol_1

    #是否有相应key值
    haveCol_1=$(egrep "^\s*\<${setKey}\>\s*=" ${edfile}|wc -l)
    if [ ${haveCol_1} -gt 0 ];then

        #已经有要添加的内容
        sameFlag=$(grep -x --fixed-strings "${addCnt}" "${edfile}"|wc -l)
        if [ ${sameFlag} -gt 0 ];then
           return 0
        fi

        #没有相等的内容,则修改有相同key的那一行值
        sed "$(sed -n "/^\s*\b${setKey}\b\s*=/=" ${edfile}|sed -n '$p')c${addCnt}" -i ${edfile}    
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change file[${edfile}] row=[${addCnt}]"
        #echo "addCnt=[${addCnt}]"
        return 9
    fi

    #没有相应key值,则查找是否有注释个的相应key值
    #如果注释字符不为空:查一下是否有注释掉的前缀和key
    if [ ! -z "${setComment}" ];then
        haveComCol_1=$(egrep "^\s*${setComment}+\s*\<${setKey}\>\s*=" ${edfile}|wc -l)
        if [ ${haveComCol_1} -gt 0 ];then

            #在找到注释行的最后一行进行替换
            sed "$(sed -n "/^\s*${setComment}\+\s*\b${setKey}\b\s*=/=" ${edfile}|sed -n '$p')c${addCnt}" -i ${edfile}    

            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change file[${edfile}] row=[${addCnt}]"
            return 9
        fi
    fi

    #如果定位符不为空则查找定位符的位置
    if [ ! -z "${setLocator}" ];then
        locatorNo=$(sed -n "/${setLocator}/=" ${edfile}|sed -n '$p')
        #参考符对应的行下追加新内容
        if [ ! -z "${locatorNo}" ];then
            sed "${locatorNo}a${addCnt}" -i ${edfile}    
            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|modify file[${edfile}] add row=[${addCnt}]"
            return 9
        fi
    fi

    #直接在文件末尾追加要添加的内容
    echo "${addCnt}">>"${edfile}"
    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|modify file[${edfile}] add row=[${addCnt}]"
    return 9
}



