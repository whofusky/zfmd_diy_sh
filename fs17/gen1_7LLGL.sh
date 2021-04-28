#!/bin/bash
#
############################################################
#
# author : fushikai
# date   : 2021-04-27
# dsc    : 从1.7理论功率的日志文件中取出:校验后的(理论功率,
#           可用功率为,实际功率为)再加上时间，生成csv结果文件
#
############################################################
#

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

    grep "\s校验后" "${doFile}"|sed 's/校验后,理论功率为=//g;s/,可用功率为=/ /g;s/,实际功率为:/ /g;s///g' >"${tmpFile}"

    local tnum=0
    tnum=$(wc -l "${tmpFile}"|awk '{print $1}')
    if [ ${tnum} -lt 1 ];then
        return 2
    fi

    local sjrq1; local sjrq2; local llgl;local kygl;
    local sjgl;
    while read  sjrq1 sjrq2 llgl kygl sjgl
    do
        echo "${sjrq1} ${sjrq2},${llgl},${kygl},${sjgl}"
    done<"${tmpFile}"

    return 0
}

function F_doAllLogFile()
{
    local tnaa

    echo "SJRQ,LLGL,KYGL,SJGL"
    find ${baseDir} -name "*.log" -type f -print 2>/dev/null|xargs ls -lrt|awk '{print $NF}'|while read tnaa
    do
        F_doOneFile "${tnaa}"
    done

    return  0
}

main()
{
    F_check
    F_doAllLogFile
    return 0
}

main

exit 0
