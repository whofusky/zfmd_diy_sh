#!/bin/bash
#
################################################################################
#
# athor    : fushikai
# date     : 2021-05-28
# dsc      : 根据2.0运算中心配置文件打印一些有用的信息
#
################################################################################
#

inShName="$0"
inExName="${inShName##*/}"
inNum="$#"
inFile="$1" ; tmpFile="" ; tmptmp=""

timeAscFlag="$2"

function F_tips()
{
    echo -e "\n\tuse: ${inExName} <compute_2.0_config.xml> <flag>"
    echo -e "\t\tflag=1 则按时间输出"
    echo -e "\t\tflag=其他值 则按风场输出"
    return 0
}

function F_init()
{
    if [ ${inNum} -ne 2 ];then
        F_tips
        exit 1
    fi
    if [ ! -e "${inFile}" ];then
        echo -e "\n\tERROR:file [ ${inFile} ] not exist!\n"
        exit 2
    fi
    local fileSufix="${inFile##*.}"
    local filePre="${inFile%.*}"
    #echo "filePre=[${filePre}],fileSufix=[${fileSufix}]"
    tmpFile="${filePre}_utf8.${fileSufix}"
    tmptmp="${filePre}.tmp"

    iconv -f gbk -t utf-8 "${inFile}" -o "${tmpFile}"
    sed -i 's///g' "${tmpFile}"
    return 0
}

function F_printInfo()
{
    local tnaa
    local flag=0;
    local taskid=0; local taskname="";local timeHMS="";local imdFlag="";
    local tnum=0

    sed -n '/^\s*<\s*usTaskId\|^\s*<\s*arrTaskName\|^\s*<arrCycle\s\|^\s*<startImdtly\s/p' "${tmpFile}"|sed 's/\s\+<!.*//g'|sed 's/<\/*[a-zA-Z]\+\|>//g'>${tmptmp} 

    while read tnaa
    do
        tnum=$(echo "${tnaa}"|sed -n '/^[0-9]\+$/p'|wc -l)
        if [ ${tnum} -gt 0 ];then
            taskid=${tnaa}
            continue
        fi
        tnum=$(echo "${tnaa}"|sed -n '/^[a-zA-Z_0-9]\+$/p'|wc -l)
        if [ ${tnum} -gt 0 ];then
            taskname=${tnaa}
            continue
        fi
        tnum=$(echo "${tnaa}"|sed -n '/^timeHMS=/p'|wc -l)
        if [ ${tnum} -gt 0 ];then
            #echo "test test--------timeHMS=[${timeHMS}],tnaa=[${tnaa}]"
            if [ -z "${timeHMS}" ];then
                timeHMS="${tnaa}"
            else
                timeHMS="${timeHMS}\n\t${tnaa}"
            fi
            continue
        fi
        tnum=$(echo "${tnaa}"|sed -n '/^imdFlag=/p'|wc -l)
        if [ ${tnum} -gt 0 ];then
            imdFlag="${tnaa}"
            if [ "${timeAscFlag}x" = "1x" ];then
                echo -e "${timeHMS}"|sed 's/^\s\+//g'|sed 's/$/   '"${taskname} ${imdFlag} ${taskid}"'/g'
            else
                echo "------------------------------"
                echo -e "${taskid}\t${taskname}\t${imdFlag}"
                echo "------------------------------"
                echo -e "\t${timeHMS}"
                echo ""
            fi
            taskid=0;taskname="";timeHMS="";imdFlag=""
            continue
        fi

        #echo "${tnaa}"
    done<${tmptmp}

    rm -rf ${tmptmp}

    return 0
}

main()
{
    F_init
    F_printInfo

    return 0
}

main
exit 0
