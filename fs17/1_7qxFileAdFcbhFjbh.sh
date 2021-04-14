#!/bin/bash
#
######################################################################
#
#author : fushikai
#date   : 2021-04-08
#des    : 1.7气象预测文件(文件名类似fjw-L9-01.CSV)添加FCBH和FJBH列
#use    : 
#         在有fjw-*文件同目录下放入此脚本，然后打开终端运行(./todo.sh)
#         即可
#
######################################################################
#

function F_addColumnInFile() # add some column in file
{
    if [ $# -ne 3 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameters nuber not eq 3\n"
        exit 1
    fi
    local tFile="$1"
    if [ ! -f "${tFile}" ];then
        echo -e "\n\tERROR:${FUNCNAME}:file [ ${tFile} ] not exits!\n"
        return 1
    fi
    local tAddTitle="$2"
    local tAddContent="$3"

    local tnum=0
    tnum=$(grep -w "${tAddTitle}" ${tFile}|wc -l)
    if [ ${tnum} -eq 0 ];then
        #tAddContent=$(echo "${tFile}"|cut -d'-' -f 2)
        sed -i "s///g;s/$/,${tAddContent}/g;1{s/\b${tAddContent}\b/${tAddTitle}/g}"  ${tFile}
        echo "---${FUNCNAME}:file [${tFile}] add [ ${tAddTitle}:${tAddContent} ]"
    else
        return 9
    fi

    return 0
}

main()
{
    local tnaa  ;  local fjbh  ;  local i=0   ;
    local bgTm=0;  local edTm=0;  local dfTm=0;

    bgTm=$(date +%s)

    local tmpFile="tmpMain.tmp"

    ls -1 fjw* >${tmpFile}

    while read tnaa
    do

       echo -e "\n---do:[${tnaa}]"

       fjbh=$(echo "${tnaa}"|cut -d'-' -f 2)
       F_addColumnInFile "${tnaa}" "FJBH" "${fjbh}"
       F_addColumnInFile "${tnaa}" "FCBH" "123"

       let i++

    done<${tmpFile}

    rm -rf ${tmpFile}

    edTm=$(date +%s)
    dfTm=$(echo "${edTm} - ${bgTm}"|bc)

    echo -e "\n\tIt took [ \e[1;31m${dfTm}\e[0m ] seconds to process [ \e[1;31m${i}\e[0m ] files in total\n"


    return 0
}

main

exit 0
