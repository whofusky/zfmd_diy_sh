
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
    [ $# -ne 1 ] && echo "0" && return 0

    if [ $(echo "$1"|sed -n '/\(^[0-9]$\|^[1-9][0-9]\+$\)/p'|wc -l) -gt 0 ];then 
        echo "1" && return 1
    fi

    echo "0" && return 0
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


#安全拷贝一个文件:
#  先将源文件拷贝到一个临时文件(与源文件同目录:.tmp_copy);
#  然后将临时文件mv到目标目录或目标文件
#用法:
#   F_safeCopy <src_file> <dst_dir1|dst_file1> [dst_dir2|dst_file2] ... [dst_dirn|dst_filen]
#
function F_safeCopy()
{
    if [ $# -lt 2 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|Input parameters are less than 2"
        return 1
    fi 

    #P: path ; F: file

    local srcPF="$1"
    if [ ! -f "${srcPF}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|file [${srcPF}] does not exist"
        return 2
    fi
    local dstP dstPF srcF tmpPF ret
    tmpPF="${srcPF}.tmp_copy"
    srcF="$(F_getFileName "${srcPF}")"

    while [ $# -ge 2 ]; do
        dstP="$2"

        #如果目录最后带有/则去掉/
        dstP="$(echo ${dstP}|sed 's/\/$//')"

        shift

        \cp -a "${srcPF}" "${tmpPF}"
        ret=$?
        if [ $ret -ne 0 ];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cp -a \"${srcPF}\" \"${tmpPF}\" return[$ret]!"
            continue
        fi

        if [ -f "${dstP}" ];then
            #允许目标是文件的情况,所以注释到下面2行代码
            #F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|[${dstP}] should be a directory not a file!"
            #continue

            dstPF="${dstP}"
        else
            F_mkpDir "${dstP}"
            dstPF="${dstP}/${srcF}"
        fi

        mv "${tmpPF}" "${dstPF}"
        ret=$?
        if [ $ret -ne 0 ];then
            F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|mv \"${tmpPF}\" \"${dstPF}\" return[$ret]!"
            continue
        fi
        
    done

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

    #return 0
}


# 将0变成要求精度的0.00 ...
function F_genZeroPointPrecision()
{
    [ $# -ne 1 ] && echo "0" && return 0

    local tscale="$1"
    [ $(F_isDigital "${tscale}") = "0" ] && echo "0" && return 0

    local retStr="0."
    local i=0
    for((i=0;i<${tscale};i++))
    do
        retStr="${retStr}0"
    done

    echo "${retStr}"
    return 0
}


#将类似如下计算值为 
#.123变成0.123 
#-.123变成-0.123
# 0变成0.000
function F_getFloatScaleResult()
{
    [[ $# -ne 2 && $# -ne 3 ]] && return 0

    local tscale tData ret divisor tnum

    tscale="$1" ; tData="$2"

    divisor=1
    [ $# -eq 3 ] && divisor="$3"

    ret=$(echo "scale=${tscale};${tData}/${divisor}"|bc)
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


#在字符串前添加0
#  1. 根据输入宽度要求在不够宽度的字符串前添加0
#       如 宽度4  字符01 则变为 0001
#  2. 当实际字符串长度大于要求宽度时
#    (1)第一个字符是0则将形状的0去掉以达到要求
#       如 宽度4  字符 00001 则变为 0001
#    (2)第一个字符不是0则不对原字符进行入理
#       如 宽度4  字符 10001 则原样输出 10001
function F_add0InFront()
{
    [[ $# -ne 2  ]] && return 0

    local twidth tData 

    twidth="$1"   #总共需要多长的字符串
    tData="$2"    #要处理的字符串
    local tlen="${#tData}"

    if [ ${twidth} -eq ${tlen} ];then
        echo "${tData}"
        return 0
    elif [ ${twidth} -lt ${tlen} ];then
        local pre0Flag=$(echo "${tData}"|sed -n '/^0/p'|wc -l)
        while [[ ${pre0Flag} -gt 0 && ${twidth} -lt ${tlen} ]]
        do
            tData=$(echo "${tData}"|sed 's/^0//')
            tlen="${#tData}"
            pre0Flag=$(echo "${tData}"|sed -n '/^0/p'|wc -l)
        done

        echo "${tData}"
        return 0
    fi

    local tminusVal tt i
    tminusVal=$(echo "${twidth}-${tlen}"|bc)
    tt=""
    for((i=0;i<${tminusVal};i++));do
        tt="0${tt}"
    done

    echo "${tt}${tData}"
}



# 根据入参1 的文件名格式类似:JSDLFD_20110614_1930_CFT.WPD
# 给全局变量赋值
#   varF_date="2011-06-14 19:30"
#   varF_minute="30"
#   varF_ymd="20110614"
#
function F_splitFnameToSome()
{
    if [ $# -ne 1 ];then
        varF_date=""
        varF_minute=""
        varF_ymd=""
        return 1
    fi

    local tfile="$1"
    tfile=$(F_getFileName "${tfile}")
    local tnum=$(echo "$tfile"|awk -F'_' '{print NF}')
    if [ $tnum -ne 4 ];then
        varF_date=""
        varF_minute=""
        varF_ymd=""
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|file[$1] not format like[JSDLFD_20110614_1930_CFT.WPD]"
        return 1
    fi

    varF_ymd=$(echo "${tfile}"|cut -d '_' -f 2)

    local yyyy="${varF_ymd:0:4}"
    local mm="${varF_ymd:4:2}"
    local dd="${varF_ymd:6:2}"

    local hhmi=$(echo "${tfile}"|cut -d '_' -f 3)

    local hh="${hhmi:0:2}"
    local mi="${hhmi:2:2}"

    varF_date="${yyyy}-${mm}-${dd} ${hh}:${mi}"
    varF_minute="${mi}"
    return 0
}


# 时间格式: 2011-06-14_19:30 或 2011-06-14_19:30:00
# 给全局变量赋值
#   varF_date="2011-06-14 19:30"
#   varF_minute="30"
#   varF_ymd="20110614"
#
function F_splitTimeStr1()
{
    if [ $# -ne 1 ];then
        varF_date=""
        varF_minute=""
        varF_ymd=""
        return 1
    fi

    local tStr="$1"
    local tnum=$(echo "$tStr"|awk -F'_' '{print NF}')
    local tnum1=$(echo "$tStr"|awk -F'-' '{print NF}')
    local tnum2=$(echo "$tStr"|awk -F':' '{print NF}')
    if [[ $tnum -ne 2 || $tnum1 -ne 3 || $tnum2 -lt 2 ]];then
        varF_date=""
        varF_minute=""
        varF_ymd=""
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|input string[$1] not format like[2011-06-14_19:30]"
        return 1
    fi

    #get 2011-06-14_19:30 -> 2011-06-14
    local y_m_d="$(echo "${tStr}"|cut -d '_' -f 1)"

    #get 2011-06-14_19:30 -> 19:30
    local h_mi="$(echo "${tStr}"|cut -d '_' -f 2)"

    local yyyy="$(echo ${y_m_d}|awk -F'-' '{print $1}')"
    local mm="$(echo ${y_m_d}|awk -F'-' '{print $2}')"
    local dd="$(echo ${y_m_d}|awk -F'-' '{print $3}')"
    local hh="$(echo ${h_mi}|awk -F':' '{print $1}')"
    local mi="$(echo ${h_mi}|awk -F':' '{print $2}')"

    varF_ymd="${yyyy}${mm}${dd}"
    varF_date="${yyyy}-${mm}-${dd} ${hh}:${mi}"
    varF_minute="${mi}"
    return 0
}



function F_shHaveRunThenExit()  #Exit if a script is already running
{
    if [ $# -lt 1 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|Function input arguments are less than 1!\n"
        exit 1
    fi
    
    local pname="$1"
    local tmpShPid tmpShPNum

    tmpShPid=$(pidof -x ${pname})
    tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
    if [ ${tmpShPNum} -gt 1 ]; then
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|script [${pname}] has been running this startup exit,pidNum=[$tmpShPNum],pid=[${tmpShPid}]!\n"
        exit 0
    fi

    #return 0
}


#此函数只建议在F_cfgFileCheck中使用
function F_notEqGrpNumToExit()
{
    local tname="$1"
    local k
    eval "k=\${#${tname}[*]}"
    if [ ${g_grp_nums} -ne ${k} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}]  ${tname}'s num not eq g_src_dir 's num [${g_grp_nums}]!"
        exit 1
    fi
}


#此函数只建议在F_cfgFileCheck中使用
function F_notSetCfgKeyToExit()
{
    if [ -z "${!1}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"${1}\"!"
        exit 1
    fi
}


function F_cfgFileCheck()
{

    if [ -z "${cfgFile}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|var \"cfgFile\" not set!"
        exit 1
    fi

    if [ ! -f "${cfgFile}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not exist!"
        exit 1
    fi

    local tCfgSec=0;
    tCfgSec=$(stat -c %Y ${cfgFile})

    ##load cfg file
    #. ${cfgFile}

    if [ "${tCfgSec}" != "${v_CfgSec}" ];then
        v_CfgSec="${tCfgSec}"
        . ${cfgFile}

        F_writeLog "$INFO" "\n"
        F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|load ${cfgFile}"
        F_writeLog "$INFO" "\n"
    else
        return 0
    fi

    F_notSetCfgKeyToExit "g_version_no"
    F_notSetCfgKeyToExit "OUT_LOG_LEVEL"
    F_notSetCfgKeyToExit "g_log_delExpirDays"
    F_notSetCfgKeyToExit "g_tmp_delExpirDays"
    F_notSetCfgKeyToExit "g_grp_nums"
    F_notSetCfgKeyToExit "g_fname_wno_len"
    F_notSetCfgKeyToExit "g_fname_ht_len"

    [ "x${g_grp_nums}" = "x0" ] && g_grp_nums="${#g_src_dir[*]}"

    if [ "x${g_grp_nums}" = "x0" ]; then 
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|cfgfile [${cfgFile}] not set \"g_src_dir\"!"
        exit 1
    fi

    F_notEqGrpNumToExit "g_src_file"
    F_notEqGrpNumToExit "g_src_nodePrefix"
    F_notEqGrpNumToExit "g_src_cntAttrItePrefix"
    F_notEqGrpNumToExit "g_dst_dir"
    F_notEqGrpNumToExit "g_dst_file_prefix"
    F_notEqGrpNumToExit "g_dst_file_suffix"
    F_notEqGrpNumToExit "g_dst_file_head"
    F_notEqGrpNumToExit "g_dst_time_resolution"

}



function F_writeVersion()
{
    [ $# -ne 1 ] && return 1

    local tverfile="$1"
    local dirName="$(dirname ${tverfile})"

    [ ! -d "${dirName}" ] && mkdir -p "${dirName}"

    echo -e "\n runtime:[$(date +%y-%m-%d_%H:%M:%S.%N)]\n version:[ ${g_version_no} ] \n">"${tverfile}"

    return 0
}




function F_fuskytest()
{
    echo "$(date +%Y/%m/%d-%H:%M:%S.%N):${FUNCNAME}:${LINENO}:test 11111"
    return 0
}
