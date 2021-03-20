
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

function F_genZeroPointPrecision()
{
    if [ $# -ne 1 ];then
        echo "0"
        return 0
    fi

    local tscale="$1"
    local ret
    F_isDigital "${tscale}"
    ret=$?
    if [ ${ret} -eq 0 ];then
        echo "0"
        return 0
    fi

    local retStr="0."
    local i=0
    for((i=0;i<${tscale};i++))
    do
        retStr="${retStr}0"
    done

    echo "${retStr}"

    return 0
}

function F_getFloatScaleResult()
{
    [[ $# -ne 2 && $# -ne 3 ]] && return 0

    local tscale="$1"
    local tData="$2"
    local ret
    local divisor=1
    [ $# -eq 3 ] && divisor="$3"

    ret=$(echo "scale=${tscale};${tData}/${divisor}"|bc)
    local tnum=0
    tnum=$(echo "${ret}"|sed -n '/^\./p'|wc -l)
    [ ${tnum} -gt 0 ] && ret="0${ret}"

    if [ "${ret}x" = "0x" ];then
        ret=$(F_genZeroPointPrecision "${tscale}")
    fi

    echo "${ret}"

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

    #load cfg file
    . ${cfgFile}

    if [ -z "${g_debugL_value}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_debugL_value\"!" 2
        exit 1
    fi
    if [ -z "${g_1mi_src_dir}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_1mi_src_dir\"!" 2
        exit 1
    fi
    if [ -z "${g_1mi_filePre_domain}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_1mi_filePre_domain\"!" 2
        exit 1
    fi
    if [ -z "${g_1mi_suffix_domian}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_1mi_suffix_domian\"!" 2
        exit 1
    fi
    if [ -z "${g_1mi_joiner_char}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_1mi_joiner_char\"!" 2
        exit 1
    fi
    if [ -z "${g_1mi_basicCondition_num}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_1mi_basicCondition_num\"!" 2
        exit 1
    fi
    if [ -z "${g_dst_result_dir}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_dst_result_dir\"!" 2
        exit 1
    fi
    if [ -z "${g_upfile_frmName_domain}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_upfile_frmName_domain\"!" 2
        exit 1
    fi
    if [ -z "${g_upfile_fanCode_domain}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_upfile_fanCode_domain\"!" 2
        exit 1
    fi
    if [ -z "${g_upfile_suffix_domain}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_upfile_suffix_domain\"!" 2
        exit 1
    fi
    if [ -z "${g_upfile_joiner_char}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_upfile_joiner_char\"!" 2
        exit 1
    fi
    if [ -z "${g_upfile_fixCnt_frmName}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_upfile_fixCnt_frmName\"!" 2
        exit 1
    fi
    if [ -z "${g_upfile_fixCnt_itemH}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_upfile_fixCnt_itemH\"!" 2
        exit 1
    fi
    if [ -z "${g_turbn_num}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_turbn_num\"!" 2
        exit 1
    fi
    if [ -z "${g_turbn_ID_suffix}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_turbn_ID_suffix\"!" 2
        exit 1
    fi
    if [ -z "${g_default_TTYPE}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_default_TTYPE\"!" 2
        exit 1
    fi
    if [ -z "${g_default_TSTATE}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_default_TSTATE\"!" 2
        exit 1
    fi
    if [ -z "${g_STATE_maxValue}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_STATE_maxValue\"!" 2
        exit 1
    fi
    if [ -z "${g_PP_scale}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_PP_scale\"!" 2
        exit 1
    fi
    if [ -z "${g_PQ_scale}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_PQ_scale\"!" 2
        exit 1
    fi
    if [ -z "${g_WS_scale}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_WS_scale\"!" 2
        exit 1
    fi
    if [ -z "${g_PP_divisor}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_PP_divisor\"!" 2
        exit 1
    fi
    if [ -z "${g_PQ_divisor}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_PQ_divisor\"!" 2
        exit 1
    fi
    if [ -z "${g_WS_divisor}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_WS_divisor\"!" 2
        exit 1
    fi
    if [ -z "${g_file_SerialNo}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] not set \"g_file_SerialNo\"!" 2
        exit 1
    fi
    if [ ! -d "${g_1mi_src_dir}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_1mi_src_dir=\"${g_1mi_src_dir}\" Directory does not exist !" 2
        exit 1
    fi
    if [ ! -d "${g_dst_result_dir}" ];then
        mkdir -p "${g_dst_result_dir}"
    fi

    local retstat=0

    F_isDigital "${g_debugL_value}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_debugL_value=${g_debugL_value} is not a number !" 2
        exit 1
    fi

    F_isDigital "${g_1mi_basicCondition_num}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_1mi_basicCondition_num=${g_1mi_basicCondition_num} is not a number !" 2
        exit 1
    fi
    F_isDigital "${g_turbn_num}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_turbn_num=${g_turbn_num} is not a number !" 2
        exit 1
    fi
    F_isDigital "${g_default_TSTATE}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_default_TSTATE=${g_default_TSTATE} is not a number !" 2
        exit 1
    fi
    F_isDigital "${g_PP_scale}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_PP_scale=${g_PP_scale} is not a number !" 2
        exit 1
    fi
    F_isDigital "${g_PQ_scale}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_PQ_scale=${g_PQ_scale} is not a number !" 2
        exit 1
    fi
    F_isDigital "${g_WS_scale}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_WS_scale=${g_WS_scale} is not a number !" 2
        exit 1
    fi
    F_isDigital "${g_STATE_maxValue}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:cfgfile [${cfgFile}] 's set g_STATE_maxValue=${g_STATE_maxValue} is not a number !" 2
        exit 1
    fi


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

function F_initCfgDefaultValue()
{
    local i=0

    #init  default turbn type
    #g_turbn_TTYPE[idx]; idx:The default is the EC value of the fan in the database
    for((i=0;i<${g_turbn_num};i++))
    do
        if [ -z "${g_turbn_TTYPE[$i]}" ];then
            g_turbn_TTYPE[$i]="${g_default_TTYPE}"
        fi
    done

    #Initialize the conversion of the default value of the fan state
    for((i=0;i<=${g_STATE_maxValue};i++))
    do
        if [ -z "${g_turbn_TSTATE[$i]}" ];then
            g_turbn_TSTATE[$i]=${g_default_TSTATE}
        fi
    done

    #Init  g_turbn_exception_ec:0, 3, 5-8,40,45 -> 0 3 5 6 7 8 40 45
    if [ ! -z "${g_turbn_exception_ec}" ];then
        local kk=$(echo ${g_turbn_exception_ec}|sed 's/\s\+//g;s/,/ /g')
        g_turbn_exception_ec=""
        local i; local j; local tnum; local ttStr
        for i in ${kk}
        do
            tnum=$(echo "${i}"|sed -n '/-\+/p'|wc -l)
            if [ ${tnum} -gt 0 ];then
                ttStr=$(echo "${i}"|sed 's/-\+/ /g')
                for j in $(seq ${ttStr})
                do
                    g_turbn_exception_ec="${g_turbn_exception_ec} ${j}"
                done
            else
                g_turbn_exception_ec="${g_turbn_exception_ec} ${i}"
            fi
        done
        g_turbn_exception_ec=$(echo "${g_turbn_exception_ec}"|sed 's/^\s\+//g')
    fi


    return 0
}


function F_delExpir1miFile()
{
    [ -z "${g_1mi_delExpirFlag}" ] && return 0

    [ "${g_1mi_delExpirFlag}x" != "1x" ] && return 0

    [ -z "${g_1mi_delExpirDays}" ] && return 0

    [ -z "${g_1mi_delExpirFlag}" ] && return 0

    F_rmExpiredFile "${g_1mi_src_dir}" "${g_1mi_delExpirDays}" "*${g_1mi_suffix_domian}"

    return 0
}

function F_delExpirdstFile()
{
    [ -z "${g_dst_delExpirFlag}" ] && return 0

    [ "${g_dst_delExpirFlag}x" != "1x" ] && return 0

    [ -z "${g_dst_delExpirDays}" ] && return 0

    [ -z "${g_dst_delExpirFlag}" ] && return 0

    local tmpStr="${g_upfile_frmName_domain}${g_upfile_joiner_char}${g_upfile_fanCode_domain}*${g_upfile_suffix_domain}"
    F_rmExpiredFile "${g_dst_result_dir}" "${g_dst_delExpirDays}" "${tmpStr}"

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
