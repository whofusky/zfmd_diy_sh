#!/bin/bash
##############################################################################
#file   : genFanCsvByOnefan.sh
#
#author : fu.sky
#date   : 2022-06-29
#
#brief  : 此工具配合scada配置文件自动生成工具使用，用于将一个风机的csv设置变成
#         多个风机的csv文件
#
#note   : 模板风机的设置要求是:csv文件没有标头,且文件需要是utf-8编码
#usege  : ./$0  <模板文件名> <开始风机号> <结束风机号>
#
#version: v.0.0.1 @2022-06-29
#
##############################################################################
#                                                  # 
#     风机模板文件内容类似如下(忽略#和#号后的格式) # 
#                                                  # 
####################################################
#  0,1号风机风速,风机,1,风速,,1,0,1,3,,0#167#0#1#0,0#169#0#1#0,,,,0#169#0#1#0,,,0#169#0#1#0,
#  2,1号风机风向,风机,1,风向,,1,0,1,3,,0#167#0#1#0,0#168#2#1#0,,,,0#168#2#1#0,,,0#168#2#1#0,
#  4,1号风机有功功率,风机,1,有功功率,,1,0,1,3,,0#167#0#1#0,0#169#0#1#0,,,,0#169#0#1#0,,,0#169#0#1#0,
#  6,1号风机无功功率,风机,1,无功功率,,1,0,1,3,,0#167#0#1#0,0#169#0#1#0,,,,0#169#0#1#0,,,0#169#0#1#0,
#  8,1号风机发电机转速,风机,1,发电机转速,,1,0,1,3,,0#167#0#1#0,,,,,,,,,
#  10,1号风机风机状态,风机,1,风机状态float,,1,0,1,3,0#167#0#1#0,,,,,,,,,,
####################################################

inNums=$#; shName="$0"; inFile="$1"; beginNo="$2"; endNo="$3"

baseDir=$(dirname $0)
tmpDir="${baseDir}/tmp"

function F_isDigit()
{
    if [ $# -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameters number not eq 1!\n"
        exit 1
    fi
    local tnum=$(echo "$1"|sed -n '/^[0-9]\+$/p'|wc -l)
    if [ $tnum -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameters [$1] is not digital!\n"
        exit 1
    fi

    return 0
}

function F_check()
{
    if [ ${inNums} -ne 3 ];then
        echo -e "\n\tERROR:please input like:\n\t  ${shName} <模板文件名> <开始风机号> <结束风机号>\n"
        exit 1
    fi
    if [ ! -f "${inFile}" ];then
        echo -e "\n\tERROR:模板文件[${inFile}] not exist!\n"
        exit 1
    fi
    local tcharset=$(file --mime-encoding ${inFile} |awk  '{print $2}')
    local tcharset="${tcharset%%-*}" 
    local tCfgSrcUtf="${tCfgSrc%.*}_tmpDo_utf8.${tCfgSrc##*.}"
    if [ "${tcharset}" == "iso" ];then
        echo -e "\n\tERROR:模板文件[${inFile}] 不是utf-8编码,现不支持,请手动用iconv转换!\n"
        exit 1
    fi

    local tureFlag=$(echo "${beginNo}<${endNo}"|bc)
    if [ ${tureFlag} -eq 0 ];then
        echo -e "\n\tERROR:开始风机小 必须小于 结束风机号!\n"
        exit 1
    fi
    F_isDigit "${beginNo}"
    F_isDigit "${endNo}"
    if [ ! -d "${tmpDir}" ];then
        mkdir -p "${tmpDir}"
    fi

    return 0
}


main()
{
    F_check
    local tF1="${tmpDir}/t1.csv"
    local tF2="${tmpDir}/t2.csv"
    local rstF="${baseDir}/allFan.csv"
    cp "${inFile}" "${tF1}"
    local i=0
    >"${tF2}"
    local allLineNo=0; local tnaa; local addr=0;
    for((i=${beginNo};i<=${endNo};i++))
    do
        cp "${inFile}" "${tF1}"
        sed -i "s/,[0-9]\+号风机/,${i}号风机/g;s/风机,[0-9]\+,/风机,${i},/g" "${tF1}"
        
        echo -n "${FUNCNAME}:INFO:--处理风机[${i}]:点地址["
        while read tnaa
        do
            addr=$(echo "${allLineNo}*2"|bc)

            echo -n "${addr} "

            #echo "${tnaa}"|sed "s/^\s*[0-9]\+/${addr}/" |tee -a "${tF2}"
            echo "${tnaa}"|sed "s/^\s*[0-9]\+/${addr}/" >> "${tF2}"
            let allLineNo++
        done<"${tF1}"

        echo  "]"

    done

    cp -a "${tF2}" "${rstF}"
    echo -e "\n\n\t结果文件为: [ ${rstF} ]\n"
    return 0
}
main
exit 0

