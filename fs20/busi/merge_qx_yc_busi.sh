#!/bin/bash
#
##############################################################################
# author  :  fu.sky
# date    :  2023-05-31
# brief   :  将给定的气象和预测文件(只支持1个气象和1个预测文件)合成业务清单文件
#
##############################################################################
#


ThisShName="$0"; inParNums="$#"; inPar1="$1"; inPar2="$2"

submitTime="$(date +%Y/%m/%d_%T)"

#---------result file name define
rstf_jiner="_"
rstf_pre="busilist"
rstf_date="$3"     #20230531
rstf_serial="$4"   #0
rstf_suffix=".xml"

#如果没有指定则默认值
[ -z "${rstf_date}" ] && rstf_date="$(date +%Y%m%d)"
[ -z "${rstf_serial}" ] && rstf_serial="0"

#echo "submitTime=[${submitTime}]" #2023/05/31_13:56:16

#业务清单文件内容头1
busi_cnt_head_1='<?xml version="1.0" encoding="gb2312"?>
<!--业务清单文件-->
<file>
    <submitter>1</submitter>
    <coordinate>100</coordinate>
    <submitTime>2023/05/31_05:14:34</submitTime>
    <taskID>1</taskID>
    <jobNumber>2</jobNumber>
    <jobDescList>
        <jobItemDesc>
            <jobID>0110</jobID>
            <featureCode>0021</featureCode>
            <statisticalRange>0</statisticalRange>
            <validAralID>00</validAralID>
            <dataComeIntoTime>2017-07-10:16-00-00</dataComeIntoTime>
            <dataTimeFeature>0084-15-0001</dataTimeFeature>
            <postProcessCode>00-00-00-0-0</postProcessCode>
        </jobItemDesc>
        <jobItemDesc>
            <jobID>0210</jobID>
            <featureCode>0021</featureCode>
            <statisticalRange>0</statisticalRange>
            <validAralID>00</validAralID>
            <dataComeIntoTime>2017-07-10:16-00-00</dataComeIntoTime>
            <dataTimeFeature>0084-15-0001</dataTimeFeature>
            <postProcessCode>00-00-00-0-0</postProcessCode>
        </jobItemDesc>
    </jobDescList>
    <jobDataList>
        <jobItemData>
            <jobID>0110</jobID>
            <dataID>0</dataID>
            <jobData>'
busi_cnt_head_2='</jobData>
        </jobItemData>
        <jobItemData>
            <jobID>0210</jobID>
            <dataID>0</dataID>
            <jobData>'
busi_cnt_head_3='</jobData>
        </jobItemData>
    </jobDataList>
</file>'

function F_checkSysCmd() #call eg: F_checkSysCmd "cmd1" "cmd2" ... "cmdn"
{
    [ $# -lt 1 ] && return 0

    local errFlag=0
    while [ $# -gt 0 ]
    do
        which $1 >/dev/null 2>&1
        if [ $? -ne 0 ];then 
            echo -e "${LINENO}|${FUNCNAME}|ERROR|The system command \"$1\" does not exist in the current environment!"
            errFlag=1
        fi
        shift
    done

    [ ${errFlag} -eq 1 ] && exit 1
}


function F_getEncode()
{
    if [ $# -ne 1 ];then
        echo -e "\n\t${LINENO}|${FUNCNAME}|ERROR|input parameters not eq 1\n"
        exit 1
    fi
    local tfile="$1"
    if [ ! -f "${tfile}" ];then
        echo -e "\n\t${LINENO}|${FUNCNAME}|ERROR|file [ ${tfile} ] not exist!\n"
        exit 1
    fi
    echo $(file --mime-encoding ${tfile} |awk  '{print $2}')
}

function F_Tips()
{
    local tshanme=${ThisShName##*/}
    #echo "tshanme=[${tshanme}]"
    echo -e "\n"
    echo -e " 功能TIPS: 将给定的气象和预测文件(只支持1个气象和1个预测文件)合成业务清单文件\n"
    echo -e "\tInput like:"
    echo -e "\t\t${tshanme} <qxsj_file> <ycsj_file> [file_name_date] [file_name_serial]"
    echo -e "\n"
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

function F_check()
{
    F_checkSysCmd "iconv"

    if [ ${inParNums} -lt 2 ];then
        F_Tips
        exit 1
    fi
    qxfile="${inPar1}"
    ycfile="${inPar2}"
    if [[ -z "${qxfile}" || -z "${ycfile}" ]];then
        F_Tips
        exit 1
    fi

    if [ ! -f "${ycfile}" ];then
        echo -e "\n\t${LINENO}|${FUNCNAME}|ERROR|file [ ${ycfile} ] not exist!\n"
        exit 1
    fi
    if [ ! -f "${qxfile}" ];then
        echo -e "\n\t${LINENO}|${FUNCNAME}|ERROR|file [ ${qxfile} ] not exist!\n"
        exit 1
    fi
    local tencodeqx=$(F_getEncode "${qxfile}")
    if [[ "${tencodeqx}" != "us-ascii" && "${tencodeqx}" != "utf-8" ]];then
        echo -e "${LINENO}|${FUNCNAME}|ERROR| 文件${qxfile}编码为[${tencodeqx}]需要是us-ascii或utf-8编码!\n"
        exit 2
    fi
    local tencodeyc=$(F_getEncode "${ycfile}")
    if [[ "${tencodeyc}" != "us-ascii" && "${tencodeyc}" != "utf-8" ]];then
        echo -e "${LINENO}|${FUNCNAME}|ERROR| 文件${ycfile}编码为[${tencodeyc}]需要是us-ascii或utf-8编码!\n"
        exit 2
    fi

    #结果文件与气象文件同目录
    rstf_dir=$(F_getPathName "${qxfile}")

    #校验气象及预测文件名前缀是否对
    #气象文件名需要是:qxsj开头
    #预设文件名需要是:ycsj开头
    local tname=$(F_getFileName "${qxfile}")
    if [ "${tname:0:4}" != "qxsj" ];then
        F_Tips
        echo -e "\n${LINENO}|${FUNCNAME}|ERROR|其中qxsj_file[${qxfile}]文件名需要是qxsj开头!\n"
        exit 1
    fi
    tname=$(F_getFileName "${ycfile}")
    if [ "${tname:0:4}" != "ycsj" ];then
        F_Tips
        echo -e "\n${LINENO}|${FUNCNAME}|ERROR|其中ycsj_file[${ycfile}]文件名需要是ycsj开头!\n"
        exit 1
    fi
}


function F_merge()
{
    busi_cnt_head_1=$(echo "${busi_cnt_head_1}"|sed "s+submitTime>[^<]*<+submitTime>${submitTime}<+")
    #echo "[${busi_cnt_head_1}]"

    local rstFname="${rstf_dir}/${rstf_pre}${rstf_jiner}${rstf_date}${rstf_jiner}${rstf_serial}${rstf_suffix}"
    #echo "rstFname=[${rstFname}]"
    echo "${busi_cnt_head_1}">"${rstFname}"
    cat "${qxfile}">>"${rstFname}"
    echo "${busi_cnt_head_2}">>"${rstFname}"
    cat "${ycfile}">>"${rstFname}"
    echo "${busi_cnt_head_3}">>"${rstFname}"

    #将<jobData>节点与下一行合并
    sed -i '/\s*<\s*jobData\s*>\s*$/{N;s/\s*\n//}' "${rstFname}"

    #将文件最后的回车符去掉
    sed -i 's///g' "${rstFname}"

    local tmpFile="${rstFname}.tmp"
    #将文件转换成gbk
    iconv -f utf-8 -t gb18030 "${rstFname}" -o "${tmpFile}"
    if [ $? -ne 0 ];then
        echo -e "\n\t${LINENO}|${FUNCNAME}|ERROR|iconv -f utf-8 -t gb18030 ${rstFname} -o ${tmpFile},return ERROR!\n"
        exit 2
    fi

    mv "${tmpFile}" "${rstFname}"

    echo -e "\n  由"
    echo -e "\t气象文件[ ${qxfile} ]"
    echo -e "\t气象文件[ ${qxfile} ]"
    echo -e "  生成的业务清单文件为:[ ${rstFname} ]"
    echo -e "\n"

}

main()
{
    F_check
    F_merge
}
main
