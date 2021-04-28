#!/bin/bash
#
############################################################
#
# author : fushikai
# date   : 2021-04-28
# dsc    : 从2.0理论功率的日志文件中取出:校验后的(理论功率,
#           可用功率为,实际功率为)再加上时间，生成csv结果文件
#
# note   : 此脚本写时是依“梅桥镇”风场写的
#
# 日志中需要满足如下搜索结果    
#  grep "\s理论=" Theory_20210426.log
#    2021-04-26 08:36:29=>前 理论=19.942 可用=19.942 受阻=0.000 实际=22.445
#    2021-04-26 08:36:29=>后 理论=23.119 可用=23.119 受阻=0.000
#
# use    :
#        ./$0  or   ./$0 <frm_name>
#
############################################################
#

if [ $# -eq 1 ];then
    rstFPre="$1"
else
    rstFPre="result"
fi

baseDir=$(dirname $0)
tmpDir="${baseDir}/tmp"
errfile="${baseDir}/ERROR_file.txt"
tmpFile="${tmpDir}/tt.txt"

#echo "${tmpDir}"
#exit 0

function F_check()
{
    if [ ! -d "${tmpDir}" ];then
        mkdir -p "${tmpDir}"
    fi
    >"${errfile}"

    return 0
}

function F_judgeIsUtf() #1:utf-8  2:gbk
{
    if [ $# -ne 1 ];then
        return 0
    fi
    local tCsvSrc="$1"
    local tcharset

    tcharset=$(file --mime-encoding ${tCsvSrc} |awk  '{print $2}')
    tcharset="${tcharset%%-*}" 

    #local tCsvSrcUtf="${tCsvSrc%.*}_tmpDo_utf8.${tCsvSrc##*.}"

    if [ "${tcharset}" == "iso" ];then
        #iconv -f gbk -t utf8 "${tCsvSrc}" -o "${tCsvSrcUtf}"
        return 2
    else
        #cp "${tCsvSrc}" "${tCsvSrcUtf}"
        return 1
    fi

    return 0

}

function F_getKeyValue()
{
    if [ $# -ne 2 ];then
        return 1
    fi

    #2021-04-26 08:36:29=>前 理论=19.942 可用=19.942 受阻=0.000 实际=22.445
    local inStr="$1"
    local inKey="$2"
    local retStr=""

    if [ "${inKey}x" = "rqx" ];then
        retStr=$(echo "${inStr}"|awk -F'[ =]' '{print $1,$2}')
    else
        retStr=$(echo "${inStr}"|awk -F'[ =]' '{for(j=1;j<=NF;j++){if($j ~/'${inKey}'/){print $(j+1);break;}}}')
    fi

    echo "${retStr}"

    return 0
}

function F_doOneFile()
{
    if [ $# -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}: input parameters not eq 1!\n"
        return 1
    fi

    local inFile="$1"
    if [ ! -f "${inFile}" ];then
        echo -e "\n\tERROR:${FUNCNAME}:file [ ${inFile} ] not exist!\n"
        return 2
    fi

    local tfname=${inFile##*/}
    local tutfFname="${tmpDir}/${tfname}_utf8"
    local doFile

    local ret=0
    #function F_judgeIsUtf() #1:utf-8  2:gbk
    F_judgeIsUtf "${inFile}"
    ret=$?
    if [ ${ret} -eq 1 ];then
        doFile="${inFile}"
    elif [ ${ret} -eq 2 ];then
        [ -f "${tutfFname}" ] && rm "${tutfFname}"
        iconv -f gbk -t utf8 "${inFile}" -o "${tutfFname}" 2>/dev/null
        ret=$?
        if [ ${ret} -ne 0 ];then
            #echo "${FUNCNAME}:fusktest:iconv [${inFile}] -> [${tutfFname}]">>"${errfile}"
            echo "file [${inFile}] format error">>"${errfile}"
        fi
        doFile="${tutfFname}"
    else
        echo -e "\n\tERROR:${FUNCNAME}:file [ ${inFile} ] call F_judgeIsUtf ERROR!\n"
        return 3
    fi

    #fusktest
    #return 0

    local tnum=0
    tnum=$(grep "\s理论=" "${doFile}"|head -2|wc -l)
    if [ ${tnum} -lt 1 ];then
        echo "file [${doFile}] No data needed">>"${errfile}"
        return 2
    fi

    grep "\s理论="  "${doFile}"|sed 's///g'>"${tmpFile}"

    #local tnum=0
    #tnum=$(wc -l "${tmpFile}"|awk '{print $1}')
    #if [ ${tnum} -lt 1 ];then
    #    return 2
    #fi

    local sjrq1; local sjrq2; local llgl;local kygl;
    local sjgl; local tnaa;
    local i=0; local numSJ=0; local numKY=0;

    while read  tnaa 
    do
        #sjrq1 sjrq2 llgl kygl sjgl
        numSJ=$(echo "${tnaa}"|grep "实际="|wc -l)
        numKY=$(echo "${tnaa}"|grep "可用="|wc -l)

        #echo "${tnaa}"
        if [[ ${numSJ} -eq 1 && ${numKY} -eq 1 ]];then
            sjgl=$(F_getKeyValue "${tnaa}" "实际")
            kygl=0; llgl=0; sjrq1=0;
        elif [[ ${numSJ} -eq 0 && ${numKY} -eq 1 ]];then
            sjrq1=$(F_getKeyValue "${tnaa}" "rq")
            llgl=$(F_getKeyValue "${tnaa}" "理论")
            kygl=$(F_getKeyValue "${tnaa}" "可用")
            echo "${sjrq1},${llgl},${kygl},${sjgl}"

            sjgl=0
        fi

        #echo "${sjrq1} ${sjrq2},${llgl},${kygl},${sjgl}"

    done<"${tmpFile}"

    return 0
}

function F_doAllLogFile()
{
    local fDir="${baseDir}"
    local toFile="${rstFPre}$(date +%Y%m%d).csv"

    if [ $# -eq 2 ];then
        fDir="$1"
        toFile="$2"
    fi

    local tnaa

    >"${toFile}"
    echo "SJRQ,LLGL,KYGL,SJGL" |tee -a "${toFile}"

    #fusktest
    #F_doOneFile "202104/Theory_20210426.log"

    find ${fDir} -name "*.log" -type f -print 2>/dev/null|xargs ls -lrt|awk '{print $NF}'|while read tnaa
    do
        F_doOneFile "${tnaa}" | tee -a "${toFile}"
    done


    return  0
}

main()
{
    F_check
    
    local tnaa; local rstFile="";local fDir=""

    find ${baseDir} -name "*.log" -type f -print 2>/dev/null|awk -F'/' '{print $2}'|sort|uniq|while read tnaa
    do
        rstFile="${rstFPre}_${tnaa}.csv"
        fDir="${baseDir}/${tnaa}"
        #echo "${fDir},${rstFile}"
        F_doAllLogFile "${fDir}" "${rstFile}"
    done

    #F_doAllLogFile

    if [ ! -s "${errfile}" ];then
        rm "${errfile}"
    fi

    return 0
}

main

exit 0
