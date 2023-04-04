
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

function F_convertVLineToSpace() #Convert vertical lines to spaces
{
    [ $# -lt 1 ] && echo "" && return 0
    echo $(echo "$1"|tr -d "[\040\t\r\n]"|tr -s "|" "\040") && return 0
}

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
    if [ ${tnum} -gt 0 ];then 
        ret="0${ret}"
    else
        tnum=$(echo "${ret}"|sed -n '/^-\./p'|wc -l)
        if [ ${tnum} -gt 0 ];then
            ret=$(echo "${ret}"|sed 's/^-\./-0./')
        fi
    fi

    if [ "${ret}x" = "0x" ];then
        ret=$(F_genZeroPointPrecision "${tscale}")
    fi

    echo "${ret}"

    return 0
}

function getPathOnFname() #get the path value in the path string(the path does not have / at the end)
{

    if [ $# -ne 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}| input parameters not eq 1!"
        return 1
    fi

    if [  -z "$1" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}| input parameters is null!"
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
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|The input parameter is less than 1!"
        exit 1
    fi
    
    local pname="$1"
    local tmpShPid; 
    local tmpShPNum

    tmpShPid=$(pidof -x ${pname})
    tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
    if [ ${tmpShPNum} -gt 1 ]; then
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|+++${tmpShPid}+++++${tmpShPNum}+++"
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|${pname} script has been running this startup exit!"
        exit 0
    fi

    return 0
}



function F_cfgFileCheck()
{
    local logFile=""

    [ $# -ge 1 ] && logFile="$1"

    if [ ! -e "${cfgFile}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not exist!"
        exit 1
    fi

    #load cfg file
    . ${cfgFile}

    if [ -z "${g_version_no}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_version_no\"!"
        exit 1
    fi
    if [ -z "${g_1mi_src_dir}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_1mi_src_dir\"!"
        exit 1
    fi
    if [ -z "${g_1mi_filePre_domain}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_1mi_filePre_domain\"!"
        exit 1
    fi
    if [ -z "${g_1mi_suffix_domian}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_1mi_suffix_domian\"!"
        exit 1
    fi
    if [ -z "${g_1mi_fixCnt_FaultJinChar}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_1mi_fixCnt_FaultJinChar\"!"
        exit 1
    fi
    if [ -z "${g_1mi_joiner_char}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_1mi_joiner_char\"!"
        exit 1
    fi
    if [ -z "${g_1mi_basicCondition_num}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_1mi_basicCondition_num\"!"
        exit 1
    fi

    g_file_nums=${#g_dst_result_dir[*]}
    if [ ${g_file_nums} -lt 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_dst_result_dir\"!"
        exit 1
    fi
    if [ ${g_file_nums} -ne ${#g_upfile_frmName_domain[*]} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}]  g_upfile_frmName_domain's num not eq g_dst_result_dir 's num [${g_file_nums}]!"
        exit 1
    fi
    if [ ${g_file_nums} -ne ${#g_upfile_fanCode_domain[*]} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}]  g_upfile_fanCode_domain's num not eq g_dst_result_dir 's num [${g_file_nums}]!"
        exit 1
    fi
    if [ ${g_file_nums} -ne ${#g_upfile_suffix_domain[*]} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}]  g_upfile_suffix_domain's num not eq g_dst_result_dir 's num [${g_file_nums}]!"
        exit 1
    fi
    if [ ${g_file_nums} -ne ${#g_upfile_joiner_char[*]} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}]  g_upfile_joiner_char's num not eq g_dst_result_dir 's num [${g_file_nums}]!"
        exit 1
    fi
    if [ ${g_file_nums} -ne ${#g_file_ec[*]} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}]  g_file_ec's num not eq g_dst_result_dir 's num [${g_file_nums}]!"
        exit 1
    fi

    local i=0
    for((i=0;i<${g_file_nums};i++))
    do
        if [ -z "${g_dst_result_dir[$i]}" ];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_dst_result_dir[$i]\"!"
            exit 1
        fi
        if [ -z "${g_upfile_frmName_domain[$i]}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_upfile_frmName_domain[$i]\"!"
            exit 1
        fi
        if [ -z "${g_upfile_fanCode_domain[$i]}" ];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_upfile_fanCode_domain[$i]\"!"
            exit 1
        fi
        if [ -z "${g_upfile_suffix_domain[$i]}" ];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_upfile_suffix_domain[$i]\"!"
            exit 1
        fi
        if [ -z "${g_upfile_joiner_char[$i]}" ];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_upfile_joiner_char[$i]\"!"
            exit 1
        fi
        if [ -z "${g_file_ec[$i]}" ];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_file_ec[$i]\"!"
            exit 1
        fi
    done

    if [ -z "${g_upfile_Head_TIM_QMARKS}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_upfile_Head_TIM_QMARKS\"!"
        exit 1
    fi
    if [ -z "${g_upfile_fixCnt_frmName}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_upfile_fixCnt_frmName\"!"
        exit 1
    fi
    if [ -z "${g_upfile_fixCnt_itemH}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_upfile_fixCnt_itemH\"!"
        exit 1
    fi
    if [ -z "${g_turbn_num}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_turbn_num\"!"
        exit 1
    fi
    if [ -z "${g_turbn_ID_suffix}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_turbn_ID_suffix\"!"
        exit 1
    fi
    if [ -z "${g_default_TTYPE}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_default_TTYPE\"!"
        exit 1
    fi
    if [ -z "${g_default_TSTATE}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_default_TSTATE\"!"
        exit 1
    fi
    if [ -z "${g_STATE_maxValue}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_STATE_maxValue\"!"
        exit 1
    fi
    if [ -z "${g_PP_scale}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_PP_scale\"!"
        exit 1
    fi
    if [ -z "${g_PQ_scale}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_PQ_scale\"!"
        exit 1
    fi
    if [ -z "${g_WS_scale}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_WS_scale\"!"
        exit 1
    fi
    if [ -z "${g_PP_divisor}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_PP_divisor\"!"
        exit 1
    fi
    if [ -z "${g_PQ_divisor}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_PQ_divisor\"!"
        exit 1
    fi
    if [ -z "${g_WS_divisor}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_WS_divisor\"!"
        exit 1
    fi
    if [ -z "${g_file_SerialNo[0]}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_file_SerialNo[0]\"!"
        exit 1
    fi
    if [ ! -d "${g_1mi_src_dir}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set g_1mi_src_dir=\"${g_1mi_src_dir}\" Directory does not exist !"
        exit 1
    fi
    local tDstDirs it
    for((i=0;i<${g_file_nums};i++))
    do
        #多个目标目录用|线分隔
        tDstDirs=$(F_convertVLineToSpace "${g_dst_result_dir[$i]}") 
        for it in ${tDstDirs}
        do
            if [ ! -d "${it}" ];then
                mkdir -p "${it}"
            fi
        done
    done

    local retstat=0


    F_isDigital "${g_1mi_basicCondition_num}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set g_1mi_basicCondition_num=${g_1mi_basicCondition_num} is not a number !"
        exit 1
    fi
    F_isDigital "${g_turbn_num}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set g_turbn_num=${g_turbn_num} is not a number !"
        exit 1
    fi
    F_isDigital "${g_default_TSTATE}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set g_default_TSTATE=${g_default_TSTATE} is not a number !"
        exit 1
    fi
    F_isDigital "${g_PP_scale}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set g_PP_scale=${g_PP_scale} is not a number !"
        exit 1
    fi
    F_isDigital "${g_PQ_scale}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set g_PQ_scale=${g_PQ_scale} is not a number !"
        exit 1
    fi
    F_isDigital "${g_WS_scale}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set g_WS_scale=${g_WS_scale} is not a number !"
        exit 1
    fi
    F_isDigital "${g_STATE_maxValue}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] 's set g_STATE_maxValue=${g_STATE_maxValue} is not a number !"
        exit 1
    fi


    return 0
}

function F_writeVersion()
{
    [ $# -ne 1 ] && return 1

    local logFile="$1"
    local dirName="$(dirname ${logFile})"

    [ ! -d "${dirName}" ] && mkdir -p "${dirName}"

    echo -e "\n runtime:[$(date +%y-%m-%d_%H:%M:%S.%N)]\n version:[ ${g_version_no} ] \n">"${logFile}"

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
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|The system command \"bc\" does not exist in the current environment!"
        exit 1
    fi

    which cut >/dev/null 2>&1
    retstat=$?
    if [ ${retstat} -ne 0 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|The system command \"cut\" does not exist in the current environment!"
        exit 1
    fi

    return 0
}

#Init  inpStr:0, 3, 5-8,40,45 -> 0 3 5 6 7 8 40 45
function F_formatRange()
{
    if [ $# -ne 1 ];then
        echo ""
        return 0
    fi
    local inpStr="$1" 
    if [ ! -z "${inpStr}" ];then
        local kk=$(echo ${inpStr}|sed 's/\s\+//g;s/,/ /g')
        inpStr=""
        local i; local j; local tnum; local ttStr
        for i in ${kk}
        do
            tnum=$(echo "${i}"|sed -n '/-\+/p'|wc -l)
            if [ ${tnum} -gt 0 ];then
                ttStr=$(echo "${i}"|sed 's/-\+/ /g')
                for j in $(seq ${ttStr})
                do
                    inpStr="${inpStr} ${j}"
                done
            else
                inpStr="${inpStr} ${i}"
            fi
        done
        inpStr=$(echo "${inpStr}"|sed 's/^\s\+//g')
    fi
    echo "${inpStr}"
    return 0
}

#judge en is in  inpStr:0 3 58 40 45
#   in  : ttnum>0
# not in: ttnum=0
function F_judgeEcInStr()
{
    local ttnum=0
    if [ $# -ne 2 ];then
        echo "${ttnum}"
        return 0
    fi
    local inpStr="$1" 
    local ttEcNo="$2"
    if [ ! -z "${inpStr}" ];then
        ttnum=$(echo "${inpStr}"|sed -n "/\b${ttEcNo}\b/p"|wc -l)
    fi
    echo "${ttnum}"
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
    g_turbn_exception_ec=$(F_formatRange "${g_turbn_exception_ec}")

    #if [ ! -z "${g_turbn_exception_ec}" ];then
    #    local kk=$(echo ${g_turbn_exception_ec}|sed 's/\s\+//g;s/,/ /g')
    #    g_turbn_exception_ec=""
    #    local i; local j; local tnum; local ttStr
    #    for i in ${kk}
    #    do
    #        tnum=$(echo "${i}"|sed -n '/-\+/p'|wc -l)
    #        if [ ${tnum} -gt 0 ];then
    #            ttStr=$(echo "${i}"|sed 's/-\+/ /g')
    #            for j in $(seq ${ttStr})
    #            do
    #                g_turbn_exception_ec="${g_turbn_exception_ec} ${j}"
    #            done
    #        else
    #            g_turbn_exception_ec="${g_turbn_exception_ec} ${i}"
    #        fi
    #    done
    #    g_turbn_exception_ec=$(echo "${g_turbn_exception_ec}"|sed 's/^\s\+//g')
    #fi

    local t=0
    #Init  g_file_ec:0, 3, 5-8,40,45 -> 0 3 5 6 7 8 40 45
    for((t=0;t<=${g_file_nums};t++))
    do
        g_file_ec[$t]=$(F_formatRange "${g_file_ec[$t]}")
        g_file_SerialNo[$t]=1 #初始化上传文件的开始序号
    done


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

    local tmpStr
    local i
    local tDstDirs it
    for((i=0;i<${g_file_nums};i++))
    do
        tmpStr="${g_upfile_frmName_domain[$i]}${g_upfile_joiner_char[$i]}${g_upfile_fanCode_domain[$i]}*${g_upfile_suffix_domain[$i]}"
        #echo "fusktest2023:F_rmExpiredFile \"${g_dst_result_dir[$i]}\" \"${g_dst_delExpirDays}\" \"${tmpStr}\""
        #多个目标目录用|线分隔
        tDstDirs=$(F_convertVLineToSpace "${g_dst_result_dir[$i]}") 
        for it in ${tDstDirs}
        do
            F_rmExpiredFile "${it}" "${g_dst_delExpirDays}" "${tmpStr}"
        done
    done

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
    echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:${LINENO}:test 11111"
    return 0
}
