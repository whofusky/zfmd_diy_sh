
################################################################################
#
#author: fushikai
#
#date  : 2022-10-24_16:28:02
#
#desc  :方便文件同级目录的脚本而写的一此shell函数
#
#
################################################################################
#

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


function F_cfgFileCheck()
{

    if [ ! -e "${cfgFile}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not exist!!\n"
        exit 1
    fi

    local tCfgSec=0;
    tCfgSec=$(stat -c %Y ${cfgFile})

    #load cfg file
    . ${cfgFile}

    #if [ "${tCfgSec}" != "${v_CfgSec}" ];then
    #    echo "$(date +%Y/%m/%d-%H:%M:%S.%N):load ${cfgFile}"
    #    v_CfgSec="${tCfgSec}"
    #    . ${cfgFile}
    #else
    #    return 0
    #fi

    if [ -z "${g_do_nums}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set g_do_nums\n"
        exit 1
    fi
    if [ -z "${g_do_ser_nums}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set g_do_ser_nums\n"
        exit 1
    fi

    local tsrcNum=${#g_src_dir[*]}
    local tfilNum=${#g_file_name[*]}
    local tbscNum=${#g_basicCondition_sec[*]}

    if [[ ${tsrcNum} -ne ${tfilNum} || ${tsrcNum} -ne ${tbscNum} ]];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set g_src_dir[x],g_file_name[x],g_basicCondition_sec[x] 's number not eq !\n"

        exit 1
    fi
    g_do_nums=${tsrcNum}

    local tipNum=${#g_ser_ip[*]}
    local tusrNum=${#g_ser_username[*]}
    local tpwdNum=${#g_ser_password[*]}
    local tporNum=${#g_ser_port[*]}
    local tdirNum=${#g_ser_dir[*]}

    if [[ ${tipNum} -ne ${tusrNum} || ${tipNum} -ne ${tpwdNum} ]];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set g_ser_ip[x],g_ser_username[x],g_ser_password[x] 's number not eq !\n"
        exit 1
    fi
    if [[ ${tipNum} -ne ${tporNum} || ${tipNum} -ne ${tdirNum} ]];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set g_ser_ip[x],g_ser_port[x],g_ser_dir[x] 's number not eq !\n"
        exit 1
    fi
    g_do_ser_nums=${tipNum}

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


function F_wegrepFileDir()
{
    if [ $# -ne 2 ];then
        return 1
    fi

    local tpath="$1"
    local sfname="$2"
    
    [ ! -d "${tpath}" ] && return 2
    [ -z "${sfname}" ] && return 3

    local tmpRead; local fileRet; local TTNUM;

    #check whether there are ${sfname} related files in the ${tpath} directory
    fileRet=$(cd ${tpath} 2>&1 && ls -1 2>&1|while read tmpRead
    do
    echo ${tmpRead}
    done);

    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|${fileRet}"

    TTNUM=$(echo ${fileRet}|grep -Ew "${sfname}"|wc -l)
    if [[ "${TTNUM}" -eq 0 ]];then
        #the file  [${fileName}] is not exists
        echo "${fileRet}"
        return 4
    fi

    return 0
}

function F_getSftpStatu() #get sftp server's status
{
    if [ $# -ne 8 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|input parameter numbers not eq 8"
        return 1
    fi

    local opFlag=$1 #0:download; 1:upload
    local tcheck=$(echo "${opFlag}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && opFlag=0
    shift

    local sftpIP=$1      #sftp ip address
    local sftpUser=$2    #sftp username
    local sftpPwd=$3     #sftp password
    local sftpRdir="$4"  #sftp server path
    local sftpLdir="$5"  #sftp client local path
    local fileName="$6" #file name on the service to be processed
    local sftpCtrPNum=$7 #the port number
    local ret

    #if the file name ${fileName} is mutiple file names(separated by spaces or table keys),replaced with | ,and remove the head and tail | (if any)
    #if the file name R{fileName} contains . replace it whith \. ther is a wildcard * replaced by .{0,} for the subsequent grep -E syntax lookup
    local fileNameTmp
    if [ -n "${fileName}" ];then
       fileNameTmp=$(echo "$fileName"|sed 's/[ ,\t]\{1,\}/\|/g'|sed 's/^|//'|sed 's/|$//'|sed 's/\./\\./g'|sed 's/\*\{1,\}/.\{0,\}/g')
    fi


    local opStr; local opCmd
    #0:download; 1:upload
    if [ ${opFlag} -eq 0 ];then
        opStr="downlaod"
        opCmd="mget"
    else
        opStr="upload"
        opCmd="mput"
    fi


    local outmsg="input para
         opFlag=[${opFlag}],opStr=[${opStr}],opCmd=[${opCmd}]
         fileNameTmp=[$fileNameTmp]--------
         ---------sftp para begine--------
         ----sftpIP     =[${sftpIP}]
         ----sftpUser   =[${sftpUser}]
         ----sftpPwd    =[${sftpPwd}]
         ----sftpRdir   =[${sftpRdir}]
         ----sftpLdir   =[${sftpLdir}]
         ----fileName  =[${fileName}]
         ----sftpCtrPNum=[${sftpCtrPNum}]
         ---------sftp para end---------- "
    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|${outmsg}"
    
    #local path error
    if [[ ! -d "${sftpLdir}" ]];then
        outmsg="${LINENO}|${FUNCNAME}|local path [${sftpLdir}] error"
        F_writeLog "$ERROR" "${outmsg}"
        echo "${outmsg}"
        return 10
    fi

    nc -z ${sftpIP} ${sftpCtrPNum} >/dev/null 2>&1
    ret=$?
    #connect sftp server error
    if [ ${ret} -ne 0 ];then
        outmsg="${LINENO}|${FUNCNAME}|connect sftp server[${sftpIP} ${sftpCtrPNum}] error"
        F_writeLog "$ERROR" "${outmsg}"
        echo "${outmsg}"
        return 11
    fi

    [ -z "${sftpRdir}" ] && sftpRdir="./"
    [ -z "${sftpLdir}" ] && sftpLdir="./"

    local fileRet; local retStat;

    #opFlag 0:download; 1:upload
    if [ -n "${fileName}" -a ${opFlag} -eq 1 ];then 
        #upload

        #view all files in the directory to be uplaod to determine where the uplaod file exists
        fileRet=$(F_wegrepFileDir "${sftpLdir}" "${fileNameTmp}")
        retStat=$?
        #the file  [${fileName}] is not exists
        if [ "${retStat}" -ne 0 ];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|F_wegrepFileDir ret[${retStat}],retmsg[${fileRet}]\n"
            echo "${fileRet}"
            return 14
        fi
    fi

    local sftpRet=0; local sftpSta=0;

    #opFlag 0:download; 1:upload
    if [ -n "${fileName}" -a ${opFlag} -eq 0 ];then
        sftpRet=$(echo "debug 3
            set net:timeout 3s;set net:max-retries 1;set net:reconnect-interval-base 1;
            cd ./ || exit 1
            cd ${sftpRdir} || exit 2
            lcd ${sftpLdir} || exit 10
            cls -1 *
            bye"|lftp -u ${sftpUser},${sftpPwd} sftp://${sftpIP}:${sftpCtrPNum} 2>&1
        );
        sftpSta=$?
    else
        sftpRet=$(echo "debug 3
            set net:timeout 3s;set net:max-retries 1;set net:reconnect-interval-base 1;
            cd ./ || exit 1
            cd ${sftpRdir} || exit 2
            lcd ${sftpLdir} || exit 10
            bye"|lftp -u ${sftpUser},${sftpPwd} sftp://${sftpIP}:${sftpCtrPNum} 2>&1
        );
        sftpSta=$?
    fi


    #wrong user name or password
    if [[ ${sftpSta} -eq 1 ]];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|wrong user name or password,sftpRet=[${sftpRet}]\n"
        echo "${sftpRet}"
        return 12
    fi

    #The system cannot find the file specified.
    if [[ ${sftpSta} -eq 2 ]];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|The system cannot find the file specified,sftpRet=[${sftpRet}]\n"
        echo "${sftpRet}"
        return 13
    fi

    #opFlag 0:download; 1:upload
    if [ -n "${fileName}" -a ${opFlag} -eq 0 ];then
        #download

        local TTNUM=$(echo ${sftpRet}|grep -Ew "${fileNameTmp}"|wc -l)
        #the file  [${fileName}] is not exists
        if [[ "${TTNUM}" -eq 0 ]];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|the file  [${fileName}] is not exists,sftpRet=[${sftpRet}]\n"
            echo "${sftpRet}"
            return 14
        fi
    fi

    echo "${sftpRet}"
    return 0
}

function F_getOrPutSftpFile() #download or upload files from sftp server
{
    if [ $# -ne 8 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|input parameter numbers not eq 8"
        return 1
    fi

    local opFlag=$1 #opFlag 0:download; 1:upload
    local tcheck=$(echo "${opFlag}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && opFlag=0
    shift
    

    local sftpIP=$1      #sftp ip address
    local sftpUser=$2    #sftp username
    local sftpPwd=$3     #sftp password
    local sftpRdir="$4"  #sftp server path
    local sftpLdir="$5"  #sftp client local path
    local fileName="$6" #file name on the service to be processed
    local sftpCtrPNum=$7 #the port number
    local ret

    #if the file name ${fileName} is mutiple file names(separated by spaces or table keys),replaced with | ,and remove the head and tail | (if any)
    #if the file name R{fileName} contains . replace it whith \. ther is a wildcard * replaced by .{0,} for the subsequent grep -E syntax lookup
    local fileNameTmp
    if [ -n "${fileName}" ];then
       fileNameTmp=$(echo "$fileName"|sed 's/[ ,\t]\{1,\}/\|/g'|sed 's/^|//'|sed 's/|$//'|sed 's/\./\\./g'|sed 's/\*\{1,\}/.\{0,\}/g')
    fi


    local opStr; local opCmd;

    #opFlag 0:download; 1:upload
    if [ ${opFlag} -eq 0 ];then
        opStr="downlaod"
        opCmd="mget -c "
    else
        opStr="upload"
        opCmd="mput"
    fi

    local outmsg="input para
         opFlag=[${opFlag}],opStr=[${opStr}],opCmd=[${opCmd}]
         fileNameTmp=[$fileNameTmp]--------
         ---------sftp para begine--------
         ----sftpIP     =[${sftpIP}]
         ----sftpUser   =[${sftpUser}]
         ----sftpPwd    =[${sftpPwd}]
         ----sftpRdir   =[${sftpRdir}]
         ----sftpLdir   =[${sftpLdir}]
         ----fileName  =[${fileName}]
         ----sftpCtrPNum=[${sftpCtrPNum}]
         ---------sftp para end---------- "
    F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|${outmsg}"
    
    #file name is null
    if [[ -z "${fileName}" ]];then
        outmsg="${LINENO}|${FUNCNAME}|file name is null"
        F_writeLog "$ERROR" "${outmsg}"
        echo "${outmsg}"
        return 9
    fi

    #local path error
    if [[ ! -d "${sftpLdir}" ]];then
        outmsg="${LINENO}|${FUNCNAME}|local path [${sftpLdir}] error"
        F_writeLog "$ERROR" "${outmsg}"
        echo "${outmsg}"
        return 10
    fi

    nc -z ${sftpIP} ${sftpCtrPNum} >/dev/null 2>&1
    ret=$?
    #connect sftp server error
    if [ ${ret} -ne 0 ];then
        outmsg="${LINENO}|${FUNCNAME}|connect sftp server[${sftpIP} ${sftpCtrPNum}] error"
        F_writeLog "$ERROR" "${outmsg}"
        echo "${outmsg}"
        return 11
    fi

    [ -z "${sftpRdir}" ] && sftpRdir="./"
    [ -z "${sftpLdir}" ] && sftpLdir="./"

    local fileRet; local retStat;

    #opFlag 0:download; 1:upload
    if [ -n "${fileName}" -a ${opFlag} -eq 1 ];then 
        #upload

        #view all files in the directory to be uplaod to determine where the uplaod file exists
        fileRet=$(F_wegrepFileDir "${sftpLdir}" "${fileNameTmp}")
        retStat=$?
        #the file  [${fileName}] is not exists
        if [ "${retStat}" -ne 0 ];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|F_wegrepFileDir ret[${retStat}],retmsg[${fileRet}]\n"
            echo "${fileRet}"
            return 14
        fi
    fi

    #download or upload
    local sftpSta; local sftpRet;

        #set net:timeout 4;set net:max-retries 4;set net:reconnect-interval-base 1;
        #set net:timeout 3;set net:max-retries 1;set net:reconnect-interval-base 1;
    sftpRet=$(echo "debug 3
        set net:timeout 4s;set net:max-retries 4;set net:reconnect-interval-base 1;
        cd ./ || exit 1
        cd ${sftpRdir} || exit 2
        lcd ${sftpLdir} || exit 10
        ${opCmd} ${fileName} || exit 3
        bye"|lftp -u ${sftpUser},${sftpPwd} sftp://${sftpIP}:${sftpCtrPNum} 2>&1
    );
    sftpSta=$?

    #wrong user name or password
    if [[ ${sftpSta} -eq 1 ]];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|wrong user name or password,sftpRet=[${sftpRet}]\n"
        echo "${sftpRet}"
        return 12
    fi

    #The system cannot find the file specified.
    if [[ ${sftpSta} -eq 2 ]];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|The system cannot find the file specified,sftpRet=[${sftpRet}]\n"
        echo "${sftpRet}"
        return 13
    fi

    #opFlag 0:download; 1:upload
    #the file  [${fileName}] is not exists
    if [ ${sftpSta} -eq 3  -a ${opFlag} -eq 0 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|the file  [${fileName}] is not exists,retmsg[${fileRet}]\n"
        echo "${sftpRet}"
        return 14
    elif [ -n "${fileName}" -a ${opFlag} -eq 0 ];then
        #download
        fileRet=$(F_wegrepFileDir "${sftpLdir}" "${fileNameTmp}")
        retStat=$?
        #the downloaded file  [${fileName}] is not exists
        if [ "${retStat}" -ne 0 ];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|the downloaded file  [${fileName}] is not exists,F_wegrepFileDir ret[${retStat}],retmsg[${fileRet}]\n"
            echo "${fileRet}"
            return 15
        fi
    fi


    echo "${sftpRet}"
    return 0
}



function F_fuskytest()
{
    echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:test 11111"
    return 0
}


