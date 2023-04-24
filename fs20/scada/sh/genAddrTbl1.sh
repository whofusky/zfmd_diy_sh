#!/bin/bash
#author:fu.sky
#date:2020-06-10_17:12
#desc:
#  此脚本与 genAddrTbl.sh的区别是,本脚本在生成通道点地址时,多个点地址生成在一行，且did名只有一个
#   usage: $0 --help    #获得使用方法


baseDir=$(dirname $0)

function F_printHelp()
{
    local exMShN="$1"
    local prtFlag="$2"
    local tSrNo=1
    if [ ${prtFlag} -eq 0 ];then
        echo -e "\n\tInput \e[1;31mERROR:\e[0m"
        echo -e "\n\t${exMShN} \e[1;31m--help\e[0m                    #获取帮助信息"
    elif [ ${prtFlag} -eq 1 ];then
        echo -e "\n\t本脚本与genAddrTbl.sh的区别是:通道输出点表文件格式更简洁,且结果文件与配置文件同目录"
        echo -e "\n\t(${tSrNo}) ${exMShN}  <\e[1;31mchnl_no\e[0m>  <\e[1;31mcfgfile\e[0m>     #将配置文件cfgfle中通道号为chnl_no的点地址输出到文件"
    elif [ ${prtFlag} -eq 2 ];then
        echo -e "\n\tInput \e[1;31mERROR:\e[0m"
        echo -e "\n\t${exMShN}  <chnl_no>  <cfgfile>     #其中chnl_no\e[1;31m需要是数字\e[0m"
    elif [ ${prtFlag} -eq 3 ];then
        echo -e "\n\tInput \e[1;31mERROR:\e[0m"
        echo -e "\n\t${exMShN}  <chnl_no>  <cfgfile>     #其中cfgfile\e[1;31m需要是存在的文件\e[0m"
    fi
    echo -e "\n"

    return 0;
}

#tInNum1=3
tInLNum=1
tInputNum=$#
if [[ ${tInputNum} -lt ${tInLNum} ]];then
    F_printHelp "$0" 0
    exit 1
fi

opFlag="$1"
if [ "${opFlag}" = "--help" ];then
    F_printHelp "$0" 1
    exit 0
elif [ ${tInputNum} -ne 2 ];then
    F_printHelp "$0" 0
    exit 0
elif [ $(echo "${opFlag}"|sed -n '/^\s*[0-9]\+\s*$/p'|wc -l) -eq 0 ];then
    F_printHelp "$0" 2
    exit 0
elif [ ! -e "$2" ];then
    F_printHelp "$0" 3
    exit 0
fi

inChnNo="$1"
tCfgSrc="$2"

tcharset=$(file --mime-encoding ${tCfgSrc} |awk  '{print $2}')
tcharset="${tcharset%%-*}" 
tCfgSrcUtf="${tCfgSrc%.*}_tmpDo_utf8.${tCfgSrc##*.}"
if [ "${tcharset}" == "iso" ];then
    iconv -f gbk -t utf8 "${tCfgSrc}" -o "${tCfgSrcUtf}"
else
    cp "${tCfgSrc}" "${tCfgSrcUtf}"
fi

edFile="${tCfgSrcUtf}"

function F_getPathName() #get the path value in the path string(the path does not have / at the end)
{
    [ $# -ne 1 ] && return 0
    [  -z "$1" ] && return 0

    local tpath="${1%/*}"
    [ "${tpath}" = "$1" ] && tpath="."
    echo "${tpath}" && return 0
}

dstDir=$(F_getPathName "${tCfgSrc}")


#tmGdidFile="${baseDir}/tmgdid$$"
tmpCsv="${dstDir}/tt.csv"

function F_rmExistFile() #Delete file if file exists
{
    local tInParNum=1
    if [ ${tInParNum} -gt  $# ];then
        echo -e "\n\t\e[1;31mERROR:\e[0m functon F_rmExistFile input parameter num less than  [${tInParNum}]!\n"
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

#trap "F_rmExistFile ${tmChFile} ${tmStsFile} ${tmGdidFile} ${tmchphyFile};exit" 0 1 2 3 9 11 13 15
trap "F_rmExistFile ${edFile} ${tmpCsv};exit" 0 1 2 3 9 11 13 15


haveStaFlag=$(sed -n "/^\s*<\s*stationCfg\b.*stationNum\s*=\s*\"${inChnNo}\"/p" ${edFile} |wc -l)

if [ ${haveStaFlag} -lt 1 ];then
    echo -e "\n\t\e[1;31mERROR\e[0m: 通道号[${inChnNo}]在配置文件[${tCfgSrc}]的站设置中没有找到\n"
    echo "haveStaFlag=[${haveStaFlag}]"
    exit 1
fi

haveChnFlag=$(sed -n "/^\s*<\s*channel\b.*chnNum\s*=\s*\"${inChnNo}\"/p" ${edFile} |wc -l)
if [ ${haveChnFlag} -lt 1 ];then
    echo -e "\n\t\e[1;31mERROR\e[0m: 通道号[${inChnNo}]在配置文件[${tCfgSrc}]的通道设置中没有找到\n"
    echo "haveChnFlag=[${haveChnFlag}]"
    exit 1
fi

function F_getRmtStaName() #get remote station name
{
    local rName
    rName=$(sed -n "/^\s*<\s*stationCfg\b.*stationNum\s*=\s*\"${inChnNo}\"/,/^\s*<\s*\/\s*stationCfg\b/ {/^\s*<\s*remoteStation\b/p}" ${edFile}|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/\<name\>/){print $(i+1);break;}}}'|sort|uniq)
    echo "${rName}"

    return 0
}


function F_getRmtRoleName() #get remote station role name
{
    local rRname
    rRname=$(sed -n "/^\s*<\s*stationCfg\b.*stationNum\s*=\s*\"${inChnNo}\"/,/^\s*<\s*\/\s*stationCfg\b/ {/^\s*<\s*remoteStation\b/p}" ${edFile}|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/\<role\>/){print $(i+1);break;}}}'|sort|uniq)
    echo "${rRname}"

    return 0
}


rName=$(F_getRmtStaName)
echo -e "\n[$(date +%Y-%m-%d_%H:%M:%S.%N)]:取远程站名称为:[\e[1;31m${rName}\e[0m]"
rRname=$(F_getRmtRoleName)
echo -e "\n[$(date +%Y-%m-%d_%H:%M:%S.%N)]:取远程站角色为:[\e[1;31m${rRname}\e[0m]"

outStaFile="${dstDir}/sta_${inChnNo}_${rName}_role_${rRname}.csv"
outChnFile="${dstDir}/chn_${inChnNo}_${rName}_role_${rRname}.csv"


function F_getRmtStaAddTbl() #get remote station point addr table
{
    sed -n "/^\s*<\s*stationCfg\b.*stationNum\s*=\s*\"${inChnNo}\"/,/^\s*<\s*\/\s*stationCfg\b/ {/^\s*<\s*pntAddr\b/p;/^\s*<\s*\/\s*stationCfg\b/q}" ${edFile}|awk -F'"' '{
    for(i=1;i<=NF;i++){
        if($i ~/\<remoteAddr\>/){
            printf "\"%s\",",$(i+1);
            break;
        } 
    }
    for(i=1;i<=NF;i++){
        if($i ~/\<name\>/){
            printf "\"%s\"\n",$(i+1);
            break;
        }
    }
}'>${outStaFile}

    return 0
}


function F_getChnAddTbl() #get chnanel's remote station point addr table
{
    #sed -n "/^\s*<\s*channel\b.*chnNum\s*=\s*\"${inChnNo}\"/,/^\s*<\s*\/\s*channel\b/ {/^\s*<\s*pntAddr\b\|^\s*<\s*dataId\b/p;/^\s*<\s*\/\s*channel\b/q}" ${edFile}|awk -F'"' '{
    sed -n "/^\s*<\s*channel\b.*chnNum\s*=\s*\"${inChnNo}\"/,/^\s*<\s*\/\s*channel\b/ {/^\s*<\s*pntAddr\b\|^\s*<\s*dataId\b/p;/^\s*<\s*\/\s*channel\b/q}" ${edFile}|sed '/^\s*<\s*pntAddr\s/{s/didName\s*=\s*"[^"]*"//g}'|awk -F'"' '{
    for(i=1;i<=NF;i++){
        if($i ~/\<remoteAddr/){
            printf "%s ,",$(i+1);
            break;
        } 
    }

    for(i=1;i<=NF;i++){
        if($i ~/\<didName\>/){
            printf "\",\n\"didName-%s\"\n",$(i+1);
            break;
        }
    }
}'>${outChnFile} 

    return 0
}



function F_mergeDidOneL()
{
    local tnaa
    local hvdIdx=0
    local preLNo=0
    local curLNo=0
    sed -n '/^\s*"\s*didName/=' ${outChnFile}|while read tnaa
    do
        curLNo=$(echo "${tnaa} - ${hvdIdx}"|bc)
        preLNo=$(echo "${curLNo} - 1"|bc)
        sed -i "${preLNo},${curLNo} {N;s/\n/,/g}" ${outChnFile}
        let hvdIdx++
    done
    return 0
}

function F_removeBlank()
{

    sed -i 's/\s\+//g' ${outStaFile}
    sed -i 's/\s\+//g' ${outChnFile}

    iconv -f utf8 -t gbk ${outStaFile} -o "${tmpCsv}"  && mv ${tmpCsv} ${outStaFile}
    iconv -f utf8 -t gbk ${outChnFile} -o "${tmpCsv}"  && mv ${tmpCsv} ${outChnFile}
    return 0
}

echo -e "\n[$(date +%Y-%m-%d_%H:%M:%S.%N)]:从站配置中取点地址配置..."
F_getRmtStaAddTbl
echo -e "[$(date +%Y-%m-%d_%H:%M:%S.%N)]:从通道中取点地址及did对应关系的配置..."
F_getChnAddTbl
echo -e "[$(date +%Y-%m-%d_%H:%M:%S.%N)]:处理与did名的行格式..."
F_mergeDidOneL
echo -e "[$(date +%Y-%m-%d_%H:%M:%S.%N)]:处理掉文件中多余的空格，并转换成gbk编码..."
F_removeBlank
sed -i 's/^/"/g;s/,"/"/g;s/,\{2,\}/,/g;s/,/ ,/g' ${outChnFile} 
echo -e "\n[$(date +%Y-%m-%d_%H:%M:%S.%N)]:提取成最终结果文件如下(注:sta开头的文件是站的;chn开头的是通道的):"
echo -e "\n\toutStaFile=[\e[1;31m${outStaFile}\e[0m]\n\toutChnFile=[\e[1;31m${outChnFile}\e[0m]\n"


exit 0


