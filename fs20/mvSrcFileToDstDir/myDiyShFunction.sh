
################################################################################
#
#author:fushikai
#
#date  :2021-03-13
#
#desc  :方便文件同级目录的脚本而写的一此shell函数
#
#
################################################################################
#

function F_isDigital() # return 1: digital; 0: not a digital
{
    [ $# -ne 1 ] && return 0

    local tData="$1"
    local tnum=0
    tnum=$(echo "${tData}"|sed -n '/\(^[0-9]$\|^[1-9][0-9]\+$\)/p'|wc -l)

    [ ${tnum} -gt 0 ] && return 1

    return 0
}

function F_convertVLineToSpace() #Convert vertical lines to spaces
{

    if [ $# -lt 1 ];then
        echo ""
        return 0
    fi

    echo $(echo "$1"|tr -d "[\040\t\r\n]"|tr -s "|" "\040")
    return 0
}

function F_judgeFileOlderXSec() # return 0:false; 1:ture
{
    if [ $# -lt 2 ];then
        return 0
    fi
    local tFile="$1"
    local tScds="$2"
    if [ ! -f "${tFile}" ];then
        return 0
    fi
    local ret
    F_isDigital "${tScds}"
    ret=$?
    if [ ${ret} -eq 0 ];then
        return  0
    fi

    local tFscds=0; local trueFlag=0; local curScds=0;

    tFscds=$(stat -c %Y ${tFile})
    curScds=$(date +%s)
    trueFlag=$(echo "( ${curScds} - ${tFscds} ) >= ${tScds}"|bc)

    [ ${trueFlag} -eq 1 ] && return 1

    return 0
}

function F_rmExpiredFile()
{
    if [ $# -ne 2 ] && [ $# -ne 3 ];then
        return 1
    fi

    local tpath="$1"
    if [ ! -d "${tpath}" ];then
        return 2
    fi
    local tdays="$2"
    local ret
    F_isDigital "${tdays}"
    ret=$?
    if [ ${ret} -eq 0 ];then
        tdays=1
    fi

    local tname
    if [ $# -eq 3 ];then
        tname="$3"
    else
        tname="*"
    fi

    local tnum=0
    tnum=$(find "${tpath}" -name "${tname}" -type f -mtime +${tdays} -print 2>/dev/null|wc -l)
    if [ ${tnum} -eq 0 ];then
        return 0
    fi

    find "${tpath}" -name "${tname}" -type f -mtime +${tdays} -print0 2>/dev/null|xargs -0 rm -rf

    return 0
}


function getPathOnFname() #get the path value in the path string(the path does not have / at the end)
{

    if [ $# -ne 1 ];then
        echo "  Error: function ${FUNCNAME} input parameters not eq 1!"
        return 1
    fi

    if [  -z "$1" ];then
        echo "  Error: function ${FUNCNAME} input parameters is null!"
        return 2
    fi
    
    local dirStr
    dirStr=$(echo "$1"|awk -F'/' '{for(i=1;i<NF;i++){printf "%s/",$i}}'|sed 's/\/$//g')
    if [ -z "${dirStr}" ];then
        dirStr="."
    fi

    echo "${dirStr}"
    return 0
}

function F_shHaveRunThenExit()  #Exit if a script is already running
{
    if [ $# -lt 1 ];then
        echo "$(date +%Y/%m/%d-%H:%M:%S.%N):ERROR:The input parameter of function ${FUNCNAME} is less than 1!"
        exit 1
    fi
    
    local pname="$1"
    local tmpShPid; 
    local tmpShPNum

    tmpShPid=$(pidof -x ${pname})
    tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
    if [ ${tmpShPNum} -gt 1 ]; then
        #echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:+++${tmpShPid}+++++${tmpShPNum}+++"
        #echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:${pname} script has been running this startup exit!"
        exit 0
    fi

    return 0
}

function F_outShDebugMsg() #out put $4 to $1; use like: F_outShDebugMsg $logfile $cfgdebug $valdebug $putcontent $clearflag
{
    if [ $# -ne 4 -a $# -ne 5 ];then
        echo "  Error: function ${FUNCNAME} input parameters not eq 4 or 5 !"
        return 1
    fi

    local inum=$#
    local logFile="$1"
    local cfgDebugFlag="$2"
    local valDebugFlag="$3"
    local puttxt="$4"
    
    local tcheck=$(echo "${cfgDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && cfgDebugFlag=0
    tcheck=$(echo "${valDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && valDebugFlag=0

    if [ $((${cfgDebugFlag}&${valDebugFlag})) -ne ${valDebugFlag} ];then
        return 0
    fi
    
    #output content to standard output device if the log file name is empty
    if [ -z "${logFile}" ];then
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}"
        return 0
    fi

    local tmpdir=$(getPathOnFname "${logFile}")
    local ret=$?
    [ ${ret} -ne 0 ] && echo "${tmpdir}" && return ${ret}

    if [ ! -d "${tmpdir}" ];then
        echo "  Error: dirname [${tmpdir}] not exist!"
        return 2
    fi

    local clearFlag=0
    [ ${inum} -ge 5 ] && clearFlag=$5
    tcheck=$(echo "${clearFlag}"|sed -n "/^[0-9]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && clearFlag=0
    [ ${clearFlag} -eq 1 ] && >"${logFile}"
    
    if [ ${clearFlag} -eq 2 ];then
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}"|tee -a "${logFile}"
    elif [ ${clearFlag} -eq 3 ];then
        echo "">>"${logFile}"
    else
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}">>"${logFile}"
    fi
    
    return 0
}


function F_cfgFileCheck()
{
    local logFile=""

    [ $# -ge 1 ] && logFile="$1"

    if [ ! -e "${cfgFile}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not exist!" 2
        exit 1
    fi

    local tCfgSec=0;
    tCfgSec=$(stat -c %Y ${cfgFile})

    #load cfg file
    if [ "${tCfgSec}" != "${v_CfgSec}" ];then
        echo "$(date +%Y/%m/%d-%H:%M:%S.%N):load ${cfgFile}"
        v_CfgSec="${tCfgSec}"
        . ${cfgFile}
    else
        return 0
    fi

    if [ -z "${g_log_delExpirFlag}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_log_delExpirFlag\"!" 2
        exit 1
    fi
    if [ -z "${g_log_delExpirDays}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_log_delExpirDays\"!" 2
        exit 1
    fi
    if [ -z "${g_do_nums}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_do_nums\"!" 2
        exit 1
    fi
    local retstat=0

    F_isDigital "${g_debugL_value}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_debugL_value=${g_debugL_value} is not a number !" 2
        exit 1
    fi

    F_isDigital "${g_log_delExpirFlag}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_log_delExpirFlag=${g_log_delExpirFlag} is not a number !" 2
        exit 1
    fi
    F_isDigital "${g_log_delExpirDays}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_log_delExpirDays=${g_log_delExpirDays} is not a number !" 2
        exit 1
    fi

    local tsrcNum=${#g_src_dir[*]}
    local tdstNum=${#g_dst_dir[*]}
    local tfilNum=${#g_file_name[*]}
    local tbscNum=${#g_basicCondition_sec[*]}

    if [[ ${tsrcNum} -ne ${tdstNum} || ${tsrcNum} -ne ${tfilNum} || ${tsrcNum} -ne ${tbscNum} ]];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_src_dir[x],g_dst_dir[x],g_file_name[x],g_basicCondition_sec[x] 's number not eq !" 2

        exit 1
    fi
    g_do_nums=${tsrcNum}

    return 0
}

function F_checkSysCmd()
{
    local logFile=""

    [ $# -ge 1 ] && logFile="$1"
    
    local retstat=0

    which bc >/dev/null 2>&1
    retstat=$?
    if [ ${retstat} -ne 0 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:The system command \"bc\" does not exist in the current environment!" 2
        exit 1
    fi

    which cut >/dev/null 2>&1
    retstat=$?
    if [ ${retstat} -ne 0 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:The system command \"cut\" does not exist in the current environment!" 2
        exit 1
    fi

    return 0
}


function F_delExpirlogFile()
{
    [ $# -lt 1 ] && return 0

    local tlogPath="$1"
    [ ! -d "${tlogPath}" ] && return 0
    [ -z "${g_log_delExpirFlag}" ] && return 0

    [ "${g_log_delExpirFlag}x" != "1x" ] && return 0

    [ -z "${g_log_delExpirDays}" ] && return 0

    [ -z "${g_log_delExpirFlag}" ] && return 0

    F_rmExpiredFile "${tlogPath}" "${g_log_delExpirDays}" "*.log"

    return 0
}

function F_fuskytest()
{
    echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:test 11111"
    return 0
}


