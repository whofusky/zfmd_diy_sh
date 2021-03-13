
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
        echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:+++${tmpShPid}+++++${tmpShPNum}+++"
        echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:${pname} script has been running this startup exit!"
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
    else
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}">>"${logFile}"
    fi
    
    return 0
}

function F_fuskytest()
{
    echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:test 11111"
    return 0
}
