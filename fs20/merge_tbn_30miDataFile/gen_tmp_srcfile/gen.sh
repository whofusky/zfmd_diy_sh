#!/bin/bash
#
################################################################################
#
#author:fushikai
#date  :2021-03-15
#desc  :用此脚本生成合成30分钟单风机上传文件对应的1分钟数据文件（模拟真实环境的文件)
#
#Precondition :
#       1. 确认要生成的文件名或文件格式是不是想要的，如果不是需要对此脚本作少量修改
#       2. 文件名及文件内容样式如下:
#          file_name:genwnd_1_20210315_0912.cime
#          charset=utf-8
#          file_content:
#            <风机数据::江西.高龙山 时间='2021-03-15 09:12:00'>
#            @	EC	PPAVG	PQ_AVG	WS_AVG	SF_TBN_OGN	FAULT
#            #	0	5.123	0.000	1.112	13	16,17
#            ...
#            </风机数据::江西.高龙山>
#
# usage like:  
#         ./$0 <YYYMMDD> <HH> <half_flag>
#
#
################################################################################
#


thisShName="$0"
onlyShName=${thisShName##*/}
onlyShPre=${onlyShName%.*}

function F_help()
{
    echo -e "\n  please input like:"
    echo -e "\n\t${onlyShName} <YYYYMMDD> <HH> <half_flag>"
    echo -e "\n\t  参数含义:"
    echo -e "\t\t YYYYMMDD : eg: 20210315"
    echo -e "\t\t HH       : eg: 03"
    echo -e "\t\t half_flag: 0:前30分钟数据 00 -- 29"
    echo -e "\t\t            1:后30分钟数据 30 -- 59"
    echo -e "\n"
    return 0
}

if [ $# -lt 3 ];then
    F_help
    exit 0
fi


##################################################
#Define the files and paths required by the script
##################################################
runDir="$(dirname ${thisShName})"

logDir="${runDir}/log"
logFile="${logDir}/${onlyShPre}_$(date +%Y%m%d).log"

resultDir="${runDir}/result"

#fileDate="$(date +%Y%m%d)"
#fileHour="09"
#halfeFlag="1" #0 生成0-29 30分钟数据; 1 生成30-59 30分钟数据

fileDate="$1"
fileHour="$2"
halfeFlag="$3" #0 生成0-29 30分钟数据; 1 生成30-59 30分钟数据

begineEC=0  #开始风机Ec 号
endEc=45    #结束风机Ec 号

fileHeadStr="<风机数据::江西.高龙山 时间='2021-03-15 09:12:00'>"
fileEndStr="</风机数据::江西.高龙山>"
itemStr="@  EC  PPAVG   PQ_AVG  WS_AVG  SF_TBN_OGN  FAULT"

fileNamePre="genwnd_1_${fileDate}_${fileHour}"
fileNamePos=".cime"

tfaultJinter="^"

fixppavg=5.123
fixpqavg=2.123
fixwsavg=1.232
fixsftbnorgn=1
#fixfault="16,17"
fixfault="16${tfaultJinter}17"

curppavg=5.123
curpqavg=2.123
curwsavg=1.232
cursftbnorgn=1
#curfault="16,17"
curfault="16${tfaultJinter}17"

curitem=""

halfePreMi[0]="00" #前30分钟为 00 -- 29
halfePosMi[0]="30" #后30分钟为 30 -- 59


function F_genhalfeMi()
{
    local inum="0"
    local i=0
    for (( i=0;i<=29;i++))
    do
        inum="${i}"
        [ ${#inum} -eq 1 ] && inum="0${inum}"
        halfePreMi[${i}]="${inum}"
    done

    local j=0
    for (( i=30;i<=59;i++))
    do
        inum="${i}"
        [ ${#inum} -eq 1 ] && inum="0${inum}"
        halfePosMi[${j}]="${inum}"
        let j++
    done

    return 0
}


function F_gencursftbnorgn()
{
    local multiplier=$(shuf -i 0-127 -n 1 )
    cursftbnorgn=$(echo "${fixsftbnorgn} * ${multiplier} "|bc)
    return 0
}


function F_gencurwsavg()
{
    local multiplier=$(shuf -i 1-10 -n 1 )
    curwsavg=$(echo "${fixwsavg} * ${multiplier} "|bc)
    return 0
}

function F_gencurppavg()
{
    local multiplier=$(shuf -i 1-10 -n 1 )
    curppavg=$(echo "${fixppavg} * ${multiplier} "|bc)
    return 0
}

function F_gencurpqavg()
{
    local multiplier=$(shuf -i 1-10 -n 1 )
    curpqavg=$(echo "${fixpqavg} * ${multiplier} "|bc)
    return 0
}

function F_gencuritem()
{
    if [ $# -lt 1 ];then
        echo -e "${FUNCNAME}:input parameters less than 1 is ERROR!\n"
        exit 1
    fi
    local tEcNo="$1"
    F_gencursftbnorgn
    F_gencurwsavg
    F_gencurppavg
    F_gencurpqavg

    curitem="# ${tEcNo} ${curppavg} ${curpqavg} ${curwsavg} ${cursftbnorgn} ${curfault}"
    return 0
}

function F_genOneFile()
{
    if [ $# -lt 1 ];then
        echo -e "${FUNCNAME}:input parameters less than 1 is ERROR!\n"
        exit 1
    fi

    local fName="$1"
    echo "${fileHeadStr}"> "${fName}"

    local i
    for ((i=${begineEC};i<=${endEc};i++))
    do
        F_gencuritem ${i}
        echo "${itemStr}">>"${fName}"
        echo "${curitem}">>"${fName}"
    done

    echo "${fileEndStr}">> "${fName}"

    return 0
}

function F_check()
{
    if [ ! -d "${logDir}" ];then
        mkdir -p "${logDir}"
    fi

    if [ ! -d "${resultDir}" ];then
        mkdir -p "${resultDir}"
    fi

    if [[ -z "${fileHour}" || ${#fileHour} -ne 2 ]];then
        F_help
        exit 0
    fi
    
    if [[ -z "${fileDate}" || ${#fileDate} -ne 8 ]];then
        F_help
        exit 0
    fi

    if [[ "${halfeFlag}" != "0" && "${halfeFlag}" != "1" ]];then
        F_help
        exit 0
    fi

    return 0
}

function F_getDateTimeByFileName()
{
    if [ $# -lt 1 ];then
        echo -e "${FUNCNAME}:input parameters less than 1 is ERROR!\n"
        exit 1
    fi
    local fname="$1"

    local fYear;local fMonth; local fDay; local fHour;
    local fMinu;local fSeconds="00"

    local retStr=""
    fYear=$(echo "${fname}"|cut -b 10-13)
    fMonth=$(echo "${fname}"|cut -b 14-15)
    fDay=$(echo "${fname}"|cut -b 16-17)
    fHour=$(echo "${fname}"|cut -b 19-20)
    fMinu=$(echo "${fname}"|cut -b 21-22)
    retStr="${fYear}-${fMonth}-${fDay} ${fHour}:${fMinu}:${fSeconds}"
    echo "${retStr}"
    return 0
}

function F_formatFile()
{
    if [ $# -lt 1 ];then
        echo -e "ERROR:${FUNCNAME}:input parameters less than 1 \n"
        exit 1
    fi
    local tFile="$1"
    if [ ! -e "${tFile}" ];then
        echo -e "ERROR:${FUNCNAME}: tFile[ ${tFile} ] not exist!\n"
        exit 2
    fi

    sed -i '/^[@#]\s/{s/\s\+/\t/g}' "${tFile}"
    return 0
}

function F_genFiles()
{
    F_genhalfeMi
    local tmpDir="${resultDir}"
    local tmpFilePre="${fileNamePre}"
    local tmpFile1
    local tmpFile
    local strTime
    local i=0

    if [ ${halfeFlag} -eq 0 ];then #生成0-29 30分钟数据
        for ((i=0;i<=29;i++))
        do
            tmpFile1="${tmpFilePre}${halfePreMi[$i]}${fileNamePos}"
            tmpFile="${tmpDir}/${tmpFile1}"
            strTime=$(F_getDateTimeByFileName "${tmpFile1}")
            fileHeadStr=$(echo "${fileHeadStr}"|sed "s='[^']\+'='${strTime}'=g")
            echo "----doing:[${tmpFile}]--strTime=[${strTime}]--"
            F_genOneFile "${tmpFile}"
            F_formatFile "${tmpFile}"
        done
        
    else #生成30-59 30分钟数据
        for ((i=0;i<=29;i++))
        do
            tmpFile1="${tmpFilePre}${halfePosMi[$i]}${fileNamePos}"
            tmpFile="${tmpDir}/${tmpFile1}"
            strTime=$(F_getDateTimeByFileName "${tmpFile1}")
            fileHeadStr=$(echo "${fileHeadStr}"|sed "s='[^']\+'='${strTime}'=g")
            echo "----doing:[${tmpFile}]--strTime=[${strTime}]--"
            F_genOneFile "${tmpFile}"
            F_formatFile "${tmpFile}"
        done
    fi
    return 0
}

main()
{
    local beginSeds=$(date +%s)

    F_check
    F_genFiles

    local endSeds=$(date +%s)
    local diffSeds=$(echo "${endSeds} - ${beginSeds}"|bc)

    echo -e "\n\tIt took [\e[1;31m ${diffSeds}\e[0;m ] seconds in total!\n"

    return 0
}

main

exit 0



