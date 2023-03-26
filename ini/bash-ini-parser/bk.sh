#!/bin/bash
#
##############################################################################
# Date  : 2023-03-23_09:58:20
# Dsc   : 将此脚本同级目录下的某个文件备份到back目录,
#         备份后的文件名为: 原文件名.YYYY-mm-dd_HH24:MI:SS
# Usage :
#         $0 <文件名>
#
##############################################################################

baseDir="$(dirname $0)"
inNum="$#"; shN="$0"; bFile="$1"

bDir="${baseDir}/back"

#echo "baseDir=[${baseDir}]"

function F_Tips()
{
    echo ""
    echo "  Input like: ${shN} <backup_file>"
    echo ""
}

function F_check()
{
    if [ ${inNum} -ne 1 ];then
        F_Tips
        exit 1
    fi

    if [ ! -f "${bFile}" ];then
        echo ""
        echo "    ERROR: file [ ${bFile} ] dos not exist!"
        echo ""
        exit 2
    fi

    [ ! -d "${bDir}" ] && mkdir -p "${bDir}"

    bDate="$(date +%F_%T)"
}

function F_back()
{
    local tFile="${bFile##*/}.${bDate}"
    \cp -a "${bFile}" "${bDir}/${tFile}"
    echo ""
    echo "cp -a \"${bFile}\" \"${bDir}/${tFile}\""
    echo ""
}
    

main()
{
    F_check
    F_back
}

main
