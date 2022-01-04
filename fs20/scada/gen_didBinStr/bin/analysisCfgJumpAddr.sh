#!/bin/bash
###############################################################################
#author:fushikai
#time  :2020-07-23_09:14
#Dsc   :分析新版scada配置文件的站点表地址是否有跳号的空点
#         有空点则输出空点的信息
#
###############################################################################

function F_pTips()
{
    local lshName="$1"
    echo -e "\n Input ERROR,please input like:" 
    echo -e "\t ${lshName} <scada配置文件名> [通道号]\n" 
    return 0
}

tShName="$0"
inExename="${tShName##*/}"
if [ $# -lt 1 ];then
    F_pTips "${inExename}"
    exit 1
fi

cfgFile="$1"
if [ ! -e "${cfgFile}" ];then
    F_pTips "${inExename}"
    echo -e "\n\t ERROR: file [ ${cfgFile} ] not exist\n"
    exit 1
fi

tMaxChnNo=$(sed -n '/^\s*<\s*channel\b/p' "${cfgFile}"|wc -l)
if [ $# -ge 2 ];then
    inParChlNo="$2"
    tNumFlag=$(echo "${inParChlNo}"|sed -n '/^\s*[0-9]\+\s*$/p'|wc -l)
    if [ ${tNumFlag} -lt 1 ];then
        F_Tips "$0"
        exit 1
    fi
    if [ ${inParChlNo} -ge ${tMaxChnNo} ];then
        echo -e "\n\t通道号 [ ${inParChlNo} ] 在[${cfgFile}中不存在\n"
        exit 1
    fi
fi

cfgPostN="${cfgFile%.*}"
dstFile="${cfgPostN}_jd_add.txt"
tmpFile="${dstFile}.tmp"

#cfgNName="${cfgPostN##*/}"
#echo "dstFile=[${dstFile}]"
#exit 0

function F_rmExistFile() #Delete file if file exists
{
    local tInParNum=1
    local thisFName="${FUNCNAME}"
    if [ ${tInParNum} -gt  $# ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${thisFName} input parameter num less than  [${tInParNum}]!\n"
        return 1
    fi

    local tFile="$1"
    while [ $# -gt 0 ]
    do
        tFile="$1"
        if [ -e "${tFile}" ];then
            #echo "rm -rf \"${tFile}\""
            rm -rf "${tFile}"
        fi
        shift
    done
    return 0
}



#trap "F_rmExistFile ${tmChFile} ${tmStsFile}  ${tmchphyFile};exit" 0 1 2 3 9 11 13 15
trap "F_rmExistFile ${tmpFile};exit" 0 1 2 3 9 11 13 15

function F_prtOneChlJdAddr()
{
    if [ $# -lt 1 ];then
        echo -e "\n\t\e[1;31mERROR:\e[0m function ${FUNCNAME} in parameters number less 1\n"
        exit 1
    fi

    local tValue[0]=0
    local tValue[1]=0
    local cycIdx=0
    local preIdx=0
    local i=0
    local inChlNo="$1"
    local tMChlN="${tMaxChnNo}"

    let tMChlN--
    

    echo "">>${dstFile}
    echo  "-----judge stationNo=[ ${inChlNo} ] addr begine...">>${dstFile}

    if [ ! -z "${inParChlNo}" ];then
        echo -e "\n\t正在判断站[ ${inChlNo} ] 中的点地址是否有跳号,\e[1;31m可能需要些许时间\e[0m，请稍候!"
    else
        echo -e "\n\t正在判断站[ ${inChlNo}/\e[1;31m${tMChlN}\e[0m ] 中的点地址是否有跳号,\e[1;31m可能需要些许时间\e[0m，请稍候!"
    fi


    sed -n "/^\s*<\s*stationCfg\b.*stationNum\s*=\s*\"\s*${inChlNo}\s*\"/,/^\s*<\s*\/\s*stationCfg\b/ {/^\s*<\s*pntAddr\b/p;/^\s*<\s*\/\s*stationCfg\b/q}" ${cfgFile}|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{
    for(i=1;i<=NF;i++){
            if($0 ~/^ *< *pntAddr\>/ && $i ~/\<remoteAddr\>/){print $(i+1);break;}
        }
    }'|sort -n >${tmpFile}

    local tMinAddr=$(head -1 ${tmpFile})
    local tMaxAddr=$(tail -1 ${tmpFile})

    echo "    最小点地址:[${tMinAddr}] -- 最大点地址:[${tMaxAddr}]" >>${dstFile}
    
    while read tnaa
    do
        cycIdx=$(echo "${i} % 2"|bc)
        preIdx=$(echo "(${i} + 1 ) % 2"|bc)
        tValue[${cycIdx}]=${tnaa}

        if [ ${i} -ge 1 ];then
            local tVdiff=$(echo "${tValue[${cycIdx}]} - ${tValue[${preIdx}]} "|bc)

            if [ ${tVdiff} -gt 1 ];then
                local tbgin=$(echo "${tValue[${preIdx}]} +1"|bc)
                local tend=$(echo "${tValue[${cycIdx}]} - 1"|bc)
                local tdiff=$(echo "${tend} - ${tbgin} + 1"|bc)
                echo "${tbgin} -- ${tend} 这${tdiff}个点是空点" >>${dstFile}
                ##echo "${tnaa}  ---diff ${tVdiff}" >>${dstFile}
                #echo "${tnaa}">>${dstFile}
            #else
            #    echo "${tnaa}">>${dstFile}
            fi
                
        #else
        #    echo "${tnaa}">>${dstFile}
        fi

        let i++
    done<${tmpFile}

    echo  "-----judge stationNo=[ ${inChlNo} ] addr end">>${dstFile}
    echo "">>${dstFile}
    if [ ! -z "${inParChlNo}" ];then
        echo -e "\t判断站[ ${inChlNo} ] 中的点地址是否有跳号,\e[1;31m完成\e[0m!"
    else
        echo -e "\t判断站[ ${inChlNo}/\e[1;31m${tMChlN}\e[0m ] 中的点地址是否有跳号,\e[1;31m完成\e[0m!"
    fi
    return 0
}


>${dstFile}
if [ ! -z "${inParChlNo}" ];then
    F_prtOneChlJdAddr "${inParChlNo}"
    echo -e "\n"
else
    for ((i=0;i<${tMaxChnNo};i++))
    do
        F_prtOneChlJdAddr "${i}"
    done
    echo -e "\n"
fi


exit 0
