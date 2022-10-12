#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20181213
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Generate a simple description of the custom function
#    
#
#############################################################################

baseDir=$(dirname $0)

descFile=${baseDir}/readme.txt

fncFile[0]=${baseDir}/diyFuncBysky.func
fncFile[1]=${baseDir}/shfunclib.sh
fncfilenum=${#fncFile[*]}


function F_genDescFile()
{
    [ $# -lt 1 ] && return 1

    local tfile="$1"
    local tname="${tfile##*/}"

    echo "">>${descFile}
    echo "/*************************************************">>${descFile}
    echo "*">>${descFile}
    echo "*  date:`date +%Y/%m/%d-%H:%M:%S.%N`">>${descFile}
    echo "*">>${descFile}
    echo "*  desc:The list of functions in file ">>${descFile}
    echo "*       ${tname}">>${descFile}
    echo "*">>${descFile}
    echo "*************************************************/">>${descFile}

    echo "">>${descFile}
    echo "">>${descFile}

    echo "-----------------------------------------------">>${descFile}

    local linenum=1
    local tnaa
    #sed -n "/[ \t]*\<function\>[ \t]\+.*\([ \t]*\)[ \t]*/p" ${tfile}|while read tnaa
    sed -n "/^\s*\<function\>\s\+.*\(\s*\)\s*/p" ${tfile}|while read tnaa
    do
        echo "-${linenum}- : ${tnaa} ">>${descFile}
        linenum=$((${linenum}+1))
    done

    echo "-----------------------------------------------">>${descFile}

    echo "">>${descFile}
    return 0
}

main()
{
    >${descFile}
    local i 

    for((i=0;i<${fncfilenum};i++))
    do
        F_genDescFile "${fncFile[$i]}"
    done

    return 0
}
main


