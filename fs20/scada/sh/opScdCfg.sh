#!/bin/bash
###############################################################################
#author:fu.sky
#date:2019-10-22_15:19
#desc:
#   usage: $0 --help    #获得使用方法
###############################################################################


tShName="$0"
inExename="${tShName##*/}"

tInLNum=1
tInputNum=$#
if [[ ${tInputNum} -lt ${tInLNum} ]];then
    echo -e "\n\t\e[1;31mERROR\e[0m: $0 in paramas num less than ${tInLNum}  !\n"
    echo -e "\n\tusage: $0 --help    #获得使用方法\n"
    exit 1
fi

opFlag="$1"

opPrt="prt"
opGen="gen"
opSet="set"
opLin="line"
opChCal="chncal"
opMd="mchds"
opMdV="mchdv"
opMdVSByN="mchvs"
opMdGV="mgdv"
opMdSsn="mssn"
opDlGadd="dldpradd"
opMAddr="maddr"
opMRefAddr="mrefadd"
opSorPhy="sorphy"

opArray[0]="${opPrt}"
opParCmmAry[0]='cfgfile     #打印cfgfle中的ip配置'
opParNumAry[0]=2
fileSAry[0]="$2"

opArray[1]="${opGen}"
opParCmmAry[1]='cfgfile     #将cfgfle中的ip配置生成cfg.cfg中要求的内容'
opParNumAry[1]=2
fileSAry[1]="$2"

opArray[2]="${opSet}"
opParCmmAry[2]='cfgfile [set_cfg_file]    #根据cfg.cfg配置文件的配置设置 cfgfile文件'
opParNumAry[2]=2
fileSAry[2]="$2"
[ ${tInputNum} -gt 2 ] && fileSAry[3]="$2 $3"

opArray[3]="${opLin}"
opParCmmAry[3]='cfgfile     #打印cfgfle中每一个通道开始与结束行号'
opParNumAry[3]=2
fileSAry[3]="$2"

opArray[4]="${opChCal}"
opParCmmAry[4]='cfgfile     #打印cfgfle中每一个通道对应 calcMethd 和 hisMaxNum 去重的值'
opParNumAry[4]=2
fileSAry[4]="$2"

opArray[5]="${opMd}"
opParCmmAry[5]='cfgfile     #检查cfgfile中通道配置的did的serialNo在全局did中是否匹配，如果不匹配则修改为正确值(根据通道中的didVal)'
opParNumAry[5]=2
fileSAry[5]="$2"

opArray[6]="${opMdV}"
opParCmmAry[6]='cfgfile     #检查cfgfile中通道配置的did的didVal在全局did中是否匹配，如果不匹配则修改为正确值(根据通道中的serialNo)'
opParNumAry[6]=2
fileSAry[6]="$2"

opArray[7]="${opMdGV}"
opParCmmAry[7]='cfgfile  didStrFile.csv    #根据didStrFile.csv中did名和值更新cfgfile全局did的didVal'
opParNumAry[7]=3
fileSAry[7]="$2 $3"

opArray[8]="${opMdSsn}"
opParCmmAry[8]='cfgfile     #将配置文件cfgfile通道中的会话配置进行适度修改'
opParNumAry[8]=2
fileSAry[8]="$2"

opArray[9]="${opDlGadd}"
opParCmmAry[9]='cfgfile     #将配置文件cfgfile全局站点表配置中重复的remoteAddr节点删除'
opParNumAry[9]=2
fileSAry[9]="$2"

opArray[10]="${opMAddr}"
opParCmmAry[10]='cfgfile stIndex nodeAttrName addVal \"0(站和通道)|1(站)|2(通道)\" \"referName=|>|<|>=|<=referVal\"   #将配置文件cfgfile站号为stIndex的站中pntAddr节点属性为nodeAttrName原值加上addVal(可以为负数)'
opParNumAry[10]=7
fileSAry[10]="$2"

opArray[11]="${opMRefAddr}"
opParCmmAry[11]='cfgfile stIndex nodeAttrName addVal    #将配置文件cfgfile站号为stIndex的站中pntAddr节点属性为<remoteAddr/localAddr>原值在<localAddr/remoteAddr>的值基础上加addVal(可以为负数)'
opParNumAry[11]=5
fileSAry[11]="$2"

opArray[12]="${opSorPhy}"
opParCmmAry[12]='cfgfile <chnNo/all> [begineValue]   #将配置文件cfgfile通道号为chnNo的通道或全部通道的phyType值进行顺序设值'
opParNumAry[12]=3
fileSAry[12]="$2"

opArray[13]="${opMdVSByN}"
opParCmmAry[13]='cfgfile     #检查cfgfile中通道配置的did的didVal和serialNo在全局did中是否匹配，如果不匹配则修改为正确值(根据通道中的didName)'
opParNumAry[13]=2
fileSAry[13]="$2"


opNum="${#opArray[*]}"
opAryStr=$(echo "${opArray[*]}"|sed 's|\s\+|/|g')

function F_help()
{
    local i=0
    local serialNo=0

    echo -e "\n"
    #echo -e "\n ${inExename}用法如下:"
    for ((i=0;i<${opNum};i++))
    do
        let serialNo++
        echo -e "\t(${serialNo}) ${inExename} \e[1;31m${opArray[${i}]}\e[0m   ${opParCmmAry[${i}]}" 
    done

    echo -e "\n"

    return 0
}

if [ "${opFlag}" = "--help" ];then
    F_help
    exit 0
fi

function F_chkInPar()
{
    local findFlag=0
    local findIdx=0
    local i=0

    for ((i=0;i<${opNum};i++))
    do
        if [ "${opFlag}" = "${opArray[$i]}" ];then
            findFlag=1
            findIdx=${i}
            break
        fi
    done
    if [ ${findFlag} -eq 0 ];then
        echo -e "\n输入的第一个参数\e[1;31m错误\e[0m，入参必须是[\n\t${opAryStr}\n\t]中的一个，其参数详细用法如下:"
        F_help
        exit 1
    fi

    if [ ${tInputNum} -lt ${opParNumAry[${findIdx}]} ];then
        echo -e "\t Input parameters number \e[1;31mERROR\e[0m please input like:"
        echo -e "\t ${inExename} \e[1;31m${opArray[${findIdx}]}\e[0m   ${opParCmmAry[${findIdx}]}\n"
        exit 1
    fi

    if [ ! -z "${fileSAry[${findIdx}]}" ];then
        local tFArys=(${fileSAry[${findIdx}]})
        local tF
        for tF in ${tFArys[*]}
        do
            if [ ! -e "${tF}" ];then
                echo -e "\n\t file [ \e[1;31m${tF}\e[0m ] not exist!\n"
                exit 1
            fi
        done
    fi

    return 0
}

F_chkInPar


[ ${tInputNum} -gt 1 ] && edFile="$2"
if [ ! -z "${edFile}" ];then
    if [ ! -e "${edFile}" ];then
        echo -e "\n\t\e[1;31mERROR\e[0m: file [${edFile}] not exist!\n"
        exit 1
    fi
fi

if [ "${opFlag}" = "${opMdGV}" ];then
    tCfgSrc="${edFile}"
    tCsvSrc="$3"    
    if [ ! -e "${tCsvSrc}" ];then
        echo -e "\n\t\e[1;31mERROR\e[0m: file [${tCsvSrc}] not exist!\n"
        exit 1
    fi

    tcharset=$(file --mime-encoding ${tCsvSrc} |awk  '{print $2}')
    tcharset="${tcharset%%-*}" 
    tCsvSrcUtf="${tCsvSrc%.*}_tmpDo_utf8.${tCsvSrc##*.}"
    if [ "${tcharset}" == "iso" ];then
        iconv -f gbk -t utf8 "${tCsvSrc}" -o "${tCsvSrcUtf}"
    else
        cp "${tCsvSrc}" "${tCsvSrcUtf}"
    fi

    tcharset=$(file --mime-encoding ${tCfgSrc} |awk  '{print $2}')
    tcharset="${tcharset%%-*}" 
    tCfgSrcUtf="${tCfgSrc%.*}_tmpDo_utf8.${tCfgSrc##*.}"
    if [ "${tcharset}" == "iso" ];then
        iconv -f gbk -t utf8 "${tCfgSrc}" -o "${tCfgSrcUtf}"
    else
        cp "${tCfgSrc}" "${tCfgSrcUtf}"
    fi

    edFile="${tCfgSrcUtf}"
elif [[ "${opFlag}" = "${opSorPhy}"  ]];then
    inChnNo="$3"
    if [ ${tInputNum} -ge 4 ];then
        phyBgVal="$4"
    else
        phyBgVal=1
    fi
elif [[ "${opFlag}" = "${opMAddr}" ||  "${opFlag}" = "${opMRefAddr}" ]];then
    tInStaNo="$3"
    tInAttrName="$4"
    tInAddVal="$5"
    [ ${tInputNum} -gt 5 ] && inRange="$6"
    [ ${tInputNum} -gt 6 ] && inRefKeyVal="$7"
fi

#echo "opNum=[${opNum}],[${opArray[*]}],[${opAryStr}]"
#exit 0


baseDir=$(dirname $0)
#echo "baseDir=[${baseDir}]"

cfgFile="${baseDir}/cfg.cfg"
if [ "${opFlag}" == "${opSet}" ];then
    [ ${tInputNum} -gt 2 ] && cfgFile="$3"
    if [ ! -e "${cfgFile}" ];then
        echo -e "\n\t\e[1;31mERROR\e[0m: cfg file [${cfgFile}] not exist!\n"
        exit 3
    fi

    #source cfg file
    . ${cfgFile}
fi




tOldCfgFlag=$(echo "${edFile}"|sed -n '/unitMemInit/p'|wc -l)
[ ${tOldCfgFlag} -gt 1 ] && tOldCfgFlag=1


#echo -e "tOldCfgFlag=[${tOldCfgFlag}]\n"

#sed -n '/^\s*<\s*[/]*channel\b/p' ${edFile}

tmChFile="${baseDir}/tmch$$"
tmStsFile="${baseDir}/tmsts$$"
#tmGdidFile="${baseDir}/tmgdid$$"
tmchphyFile="${baseDir}/tmchphy$$"
#echo "tmChFile=[${tmChFile}]"


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


#trap "F_rmExistFile ${tmChFile} ${tmStsFile} ${tmGdidFile} ${tmchphyFile};exit" 0 1 2 3 9 11 13 15
trap "F_rmExistFile ${tmChFile} ${tmStsFile}  ${tmchphyFile};exit" 0 1 2 3 9 11 13 15




function F_fndXmlNodeAttrLNo() #Find xml node's attributes line no
{
    local tLsInNum=2
    local thisFName="${FUNCNAME}"
    if [[ $# -lt ${tLsInNum} ]];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${thisFName} input para nums less than [${tLsInNum}]!\n"
        return 1
    fi

    local opType="$1"

    shift

    local tFile="$1"
    if [ ! -e "${tFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${thisFName} file [${tFile}] not exist!\n"
        return 2
    fi

    local tFlag="$2"

    local tRetMsg

    if [ "${opType}" = "attr" ];then
        if [[ $# -ne 6 && $# -ne 5 ]];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m in functon ${thisFName} attr input paranum not eq 5 nore 6 !\n"
            return 2

        fi
        local tPar1="$3"
        local tPar2="$4"
        local tPar3="$5"
        if [ 6 -eq $# ];then
            local tPar4="$6"
            if [ ${tFlag} -eq 0 ];then
                tRetMsg=$(sed -n "/^\s*<\s*${tPar1}\b/,/^\s*<\s*\/\s*${tPar2}\b/ {/\b${tPar3}\s*=\s*\"\s*${tPar4}\s*\"/=}" ${tFile})
            elif [ ${tFlag} -eq 1 ];then
                tRetMsg=$(sed -n "${tPar1},/^\s*<\s*\/\s*${tPar2}\b/ {/\b${tPar3}\s*=\s*\"\s*${tPar4}\s*\"/=}" ${tFile})
            elif [ ${tFlag} -eq 2 ];then
                tRetMsg=$(sed -n "${tPar1},${tPar2} {/\b${tPar3}\s*=\s*\"\s*${tPar4}\s*\"/=;${tPar2}q}" ${tFile})
            else
                echo "line[${LINENO}]:in function ${thisFName} attr input para flag=[${tFile}] is undefine"
                return 3
            fi
        else
            if [ ${tFlag} -eq 0 ];then
                tRetMsg=$(sed -n "/^\s*<\s*${tPar1}\b/,/^\s*<\s*\/\s*${tPar2}\b/ {/\b${tPar3}\b/=}" ${tFile})
            elif [ ${tFlag} -eq 1 ];then
                tRetMsg=$(sed -n "${tPar1},/^\s*<\s*\/\s*${tPar2}\b/ {/\b${tPar3}\b/=}" ${tFile})
            elif [ ${tFlag} -eq 2 ];then
                tRetMsg=$(sed -n "${tPar1},${tPar2} {/\b${tPar3}\b/=;${tPar2}q}" ${tFile})
            else
                echo "line[${LINENO}]:in function ${thisFName} attr input para flag=[${tFile}] is undefine"
                return 3
            fi

        fi
    elif [ "${opType}" = "node" ];then
        if [[ $#  -ne 5 ]];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m in functon ${thisFName} node input paranum not eq 5  !\n"
            return 2
        fi
        local tPar1="$3"
        local tPar2="$4"
        local tPar3="$5"
        if [ ${tFlag} -eq 0 ];then #begine
            tRetMsg=$(sed -n "${tPar1},${tPar2} {/^\s*<\s*${tPar3}\b/=;${tPar2}q}" ${tFile})
        elif [ ${tFlag} -eq 1 ];then #end
            tRetMsg=$(sed -n "${tPar1},${tPar2} {/^\s*<\s*\/\s*${tPar3}\b/=;${tPar2}q}" ${tFile})
        elif [ ${tFlag} -eq 2 ];then #begine and end
            tRetMsg=$(sed -n "${tPar1},${tPar2} {/^\s*<\s*[\/]*\s*${tPar3}\b/=;${tPar2}q}" ${tFile})
        elif [ ${tFlag} -eq 3 ];then #//begine
            tRetMsg=$(sed -n "${tPar1},/^\s*<\s*\/\s*${tPar2}\b/ {/^\s*<\s*${tPar3}\b/=}" ${tFile})
        elif [ ${tFlag} -eq 4 ];then #//end
            tRetMsg=$(sed -n "${tPar1},/^\s*<\s*\/\s*${tPar2}\b/ {/^\s*<\s*\/\s*${tPar3}\b/=}" ${tFile})
        elif [ ${tFlag} -eq 5 ];then #//begine and end
            tRetMsg=$(sed -n "${tPar1},/^\s*<\s*\/\s*${tPar2}\b/ {/^\s*<\s*[\/]*\s*${tPar3}\b/=}" ${tFile})
        else
            echo "line[${LINENO}]:in function ${thisFName} node input para flag=[${tFile}] is undefine"
            return 3
        fi
    else
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${thisFName} input para opType=[${opType}] is undefine !\n"
        return 1
    fi

    echo "${tRetMsg}"
    return 0
}


function F_prtNodeLinNos()
{
    local inNum=5
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    
    local tBL="$1"
    local tEL="$2"
    local tFlag="$3"
    local tKey="$4"
    local tEdFile="$5"
    if [ ! -e "${tEdFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function ${thisFName} file [${tEdFile}] not exist!\n"
        return 1
    fi

    local tmpStr
    
    if [ ${tFlag} -eq 0 ];then
        tmpStr=$(sed -n "${tBL},${tEL}{/<\s*${tKey}\s*>[^>]*<\s*\/\s*${tKey}\s*>/=;${tEL}q}" ${tEdFile})
    elif [ ${tFlag} -eq 1 ];then
        tmpStr=$(sed -n "${tBL},${tEL}{/<\s*${tKey}\b/=;${tEL}q}" ${tEdFile})
    else
        tmpStr=$(sed -n "${tBL},${tEL}{/<\s*${tKey}\b/p;${tEL}q}" ${tEdFile})
    fi
    echo "${tmpStr}"

    return 0
}


function F_prtEchoNdVl()
{
    local inNum=2
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    local tKey="$1"
    local tmpStr="$2"
    
    tmpStr=$(echo "${tmpStr}"|awk -F'[><]' '{for(i=1;i<=NF;i++){if($i ~/'${tKey}'/){print $(i+1);break;}}}')
    echo "${tmpStr}"

    return 0
}

function F_prtNodeVals()
{
    local inNum=4
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    
    local tBL="$1"
    local tEL="$2"
    local tKey="$3"
    local tEdFile="$4"
    if [ ! -e "${tEdFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function ${thisFName} file [${tEdFile}] not exist!\n"
        return 1
    fi

    local tmpStr
    
    tmpStr=$(sed -n "${tBL},${tEL}{/<\s*${tKey}\s*>[^>]*<\s*\/\s*${tKey}\s*>/p;${tEL}q}" ${tEdFile}|awk -F'[><]' '{for(i=1;i<=NF;i++){if($i ~/'${tKey}'/){print $(i+1);break;}}}')
    echo "${tmpStr}"

    return 0
}


function F_prtfindKeyVal()
{
    local inNum=2
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    
    local tKey="$1"
    local tmpStr="$2"
    
    #echo -e "${tmpStr}"|awk -F'[= "]'  '{for(i=1;i<=NF;i++){if($i ~/'${tKey}'/ ){print $(i+2);break;} }}'
    #tDidName=$(sed -n "${tDidLinNo} p" ${tcfgFile}|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/(name|didName)/){print $(i+1);break;}}}')
    #echo -e "${tmpStr}"|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/\<'${tKey}'\>/){print $(i+1);break;}}}'
    echo -e "${tmpStr}"|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/ +'${tKey}'\s*=/){print $(i+1);break;}}}'

    return 0
}

function F_setFixLNdVal()
{
    local inNum=4
    local thisFName="${FUNCNAME}"
    if [ $# -lt ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num less than ${inNum}!\n"
        return 1
    fi
    
    local tLine="$1"
    local tKey="$2"
    local tVal="$3"
    local tEdFile="$4"
    if [ $# -gt 4 ];then
        local proCont="$5"
    fi

    if [ ! -e "${tEdFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in function ${thisFName} edit file [${tEdFile}] not exist!\n"
        return 2
    fi

    local tmpStr=$(sed -n "${tLine} {p;q}" ${tEdFile})
    local tOldVal=$(F_prtEchoNdVl "${tKey}" "${tmpStr}")

    if [ "${tOldVal}" == "${tVal}" ];then
        #echo "[${tOldVal}] eq [${tVal}]"
        return 0
    fi

    tmpStr=$(echo "${tmpStr}"|sed -e 's///g' -e 's/^\s\+//g')
    echo -e "line[${LINENO}]:file:[${tEdFile}] \e[1;31m${proCont}\e[0m line:[${tLine}] content:[${tmpStr}] ,modify [\e[1;31m${tKey}\e[0m]'s value [\e[1;31m${tOldVal}\e[0m] to [\e[1;31m${tVal}\e[0m]  "

    #sed -i "${tLine} s/\b${tKey}\b\s*=\s*\"[^\"]*\"/${tKey}=\"${tVal}\"/g" ${tEdFile}
    sed -i "${tLine}{s/<\s*${tKey}\s*>[^>]*<\s*\/\s*${tKey}\s*>/<${tKey}>${tVal}<\/${tKey}>/}" ${tEdFile} 
    

    return 0
}


function F_setFixLinKeyVal()
{
    local inNum=4
    local thisFName="${FUNCNAME}"
    if [ $# -lt ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num less than ${inNum}!\n"
        return 1
    fi
    
    local tLine="$1"
    local tKey="$2"
    local tVal="$3"
    local tEdFile="$4"
    if [ $# -gt 4 ];then
        local proCont="$5"
    fi

    if [ $# -gt 5 ];then
        local nodeName="$6"
    fi

    if [ ! -e "${tEdFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in function ${thisFName} edit file [${tEdFile}] not exist!\n"
        return 2
    fi

    local tmpStr=$(sed -n "${tLine} {p;q}" ${tEdFile})
    local tOldVal=$(F_prtfindKeyVal "${tKey}" "${tmpStr}")

    if [ "${tOldVal}" == "${tVal}" ];then
        #echo "[${tOldVal}] eq [${tVal}]"
        return 0
    fi

    local tnum=$(echo "${tmpStr}"|sed -n "/\b${tKey}\b\s*=/p"|wc -l)

    tmpStr=$(echo "${tmpStr}"|sed -e 's///g' -e 's/^\s\+//g')

    if [ ${tnum} -gt 0 ];then
        echo -e "line[${LINENO}]:file:[${tEdFile}] \e[1;31m${proCont}\e[0m line:[${tLine}] content:[${tmpStr}] ,modify [\e[1;31m${tKey}\e[0m]'s value [\e[1;31m${tOldVal}\e[0m] to [\e[1;31m${tVal}\e[0m]  "
        sed -i "${tLine} s/\b${tKey}\b\s*=\s*\"[^\"]*\"/${tKey}=\"${tVal}\"/g" ${tEdFile}
    else
        if [ ! -z "${nodeName}" ];then
            sed -i "${tLine} s/^\s*<\s*\b${nodeName}\b/& ${tKey}=\"${tVal}\"/g" ${tEdFile}
            echo -e "line[${LINENO}]:file:[${tEdFile}] \e[1;31m${proCont}\e[0m line:[${tLine}] content:[${tmpStr}] ,\e[1;31madd\e[0m attribute's value [\e[1;31m${tKey}=\"${tVal}\"\e[0m] "
        else
            echo -e "\n\t ${FUNCNAME}:LINE[${LINENO}] function input parmameter number error you shoud add xml's node name\n"
        fi
    fi
    

    return 0
}
#return statas: 0，不满足；1，满足
function F_judgeIfXmlAttr() #判断xml某个节点的属性值是否满足某个条件
{
    [ $# -ne 2 ] && return 0

    local xmlNodeAtrStr="$1"
    local tfindIf="$2"

    local retStat=0

    [ -z "${xmlNodeAtrStr}" ] && return 0
    [ -z "${tfindIf}" ] && return 0

    #If there is a filter condition value,the condition is judged

    local tNumEq=$(echo "${tfindIf}"|sed -n '/\b=\b/p'|wc -l)
    local tNumGt=$(echo "${tfindIf}"|sed -n '/\b>\b/p'|wc -l)
    local tNumLt=$(echo "${tfindIf}"|sed -n '/\b<\b/p'|wc -l)
    local tNumGe=$(echo "${tfindIf}"|sed -n '/\b>=\b/p'|wc -l)
    local tNumLe=$(echo "${tfindIf}"|sed -n '/\b<=\b/p'|wc -l)
    local tNumNe=$(echo "${tfindIf}"|sed -n '/\b!=\b/p'|wc -l)
    if [[ ${tNumEq} -eq 0 && ${tNumGt} -eq 0 && ${tNumLt} -eq 0 && ${tNumGe} -eq 0 && ${tNumLe} -eq 0 && ${tNumNe} -eq 0 ]];then
        return 0
    fi

    local tmpInfdIf="${tfindIf}"
    local tCtOpr
    if [ ${tNumEq} -gt 0 ];then
        tCtOpr="ne"
    elif [ ${tNumGt} -gt 0 ];then
        tCtOpr="le"
        tmpInfdIf=$(echo "${tfindIf}"|sed 's/>/=/g')
    elif [ ${tNumLt} -gt 0 ];then
        tCtOpr="ge"
        tmpInfdIf=$(echo "${tfindIf}"|sed 's/</=/g')
    elif [ ${tNumGe} -gt 0 ];then
        tCtOpr="lt"
        tmpInfdIf=$(echo "${tfindIf}"|sed 's/>//g')
    elif [ ${tNumLe} -gt 0 ];then
        tCtOpr="gt"
        tmpInfdIf=$(echo "${tfindIf}"|sed 's/<//g')
    elif [ ${tNumNe} -gt 0 ];then
        tCtOpr="eq"
        tmpInfdIf=$(echo "${tfindIf}"|sed 's/!//g')
    fi

    local tfindName=$(echo "${tmpInfdIf}"|cut -d'=' -f1)
    [ -z "${tfindName}" ] && return 0
    local tfindVal=$(echo "${tmpInfdIf}"|cut -d'=' -f2)
    [ -z "${tfindVal}" ] && return 0

    local tCurFdVal=$(F_prtfindKeyVal "${tfindName}" "${xmlNodeAtrStr}") 
    retStat=$?
    [ ${retStat} -ne 0 ] && return 0
    [ -z "${tCurFdVal}" ] && return 0
    [ ${tCurFdVal} -${tCtOpr} ${tfindVal} ] && return 0

    return 1
}

function F_addXmlNdAttVal() #Find xml node's attributes and add some values
{
    local tLsInNum=6
    local thisFName="${FUNCNAME}"
    if [[ $# -lt ${tLsInNum} ]];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${thisFName} input para nums less than [${tLsInNum}]!\n"
        return 1
    fi


    local tFile="$1"
    if [ ! -e "${tFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${thisFName} file [${tFile}] not exist!\n"
        return 2
    fi

    local tLineNo="$2"
    local tNodeName="$3"
    local tAttrName="$4" 
    local tAddVal="$5" 
    local toBeAddVal="$6"  #指定被加数

    local tmpStr=$(sed -n "${tLineNo} {/^\s*<\s*${tNodeName}\b/ {p;q} }" ${tFile})
    if [ -z "${tmpStr}" ];then
        return 0
    fi

    [ $# -gt 6 ] && local tfindIf="$7"

    local retStat=0

    local i
    #If there is a filter condition value,the condition is judged
    if [ ! -z "${tfindIf}" ];then
        local tfdIfAry=(${tfindIf})
        
        for ((i=0;i<${#tfdIfAry[*]};i++))
        do
            F_judgeIfXmlAttr "${tmpStr}" "${tfdIfAry[$i]}"
            retStat=$?
            [ ${retStat} -eq 0 ] && return 0
        done
    fi


    #F_setFixLinKeyVal "${tBL}" "actFlag" "1" "${edFile}" "${tmpPtCmt}"
    #local ssnMode=$(F_prtfindKeyVal "ssnMode" "${tmpStr}")

    local oldVal
    if [ -z "${toBeAddVal}" ];then
        oldVal=$(F_prtfindKeyVal "${tAttrName}" "${tmpStr}")
        if [ -z "${oldVal}" ];then
            return 0
        fi
    else
        oldVal="${toBeAddVal}"
    fi

    local newVal=$(echo "${oldVal} + ${tAddVal}"|bc)
    if [ ${newVal} -lt 0 ];then
        echo -e "\tline[${LINENO}]:\e[1;31mWARNIGN:\e[0m file[ ${tFile} ] line[${tLineNo}] node[${tNodeName}]\e[1;31m${tAttrName}\e[0m's new value=[\e[1;31m${newVal}\e[0m]"
    fi

    local tmpPtCmt="node[${tNodeName}]"

    F_setFixLinKeyVal "${tLineNo}" "${tAttrName}" "${newVal}" "${tFile}" "${tmpPtCmt}"

    return 0
}

function F_prtDataCtIp()
{
    local inNum=3
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi

    local daInIpBL="$1"
    local daOutIpBL="$2"

    local edFile="$3"

    local tmpStr=$(sed -n "${daInIpBL} {p;q}" ${edFile})
    local llcalPort=$(F_prtfindKeyVal "lcalPort" "${tmpStr}")
    local lrmtPort=$(F_prtfindKeyVal "rmtPort" "${tmpStr}")
    local llcalIp=$(F_prtfindKeyVal "lcalIp" "${tmpStr}")
    local lrmtIp=$(F_prtfindKeyVal "rmtIp" "${tmpStr}")
    
    tmpStr=$(sed -n "${daOutIpBL} {p;q}" ${edFile})
    local rlcalPort=$(F_prtfindKeyVal "lcalPort" "${tmpStr}")
    local rrmtPort=$(F_prtfindKeyVal "rmtPort" "${tmpStr}")
    local rlcalIp=$(F_prtfindKeyVal "lcalIp" "${tmpStr}")
    local rrmtIp=$(F_prtfindKeyVal "rmtIp" "${tmpStr}")
    
    if [ "${opFlag}" == "${opPrt}" ];then
        printf "\nData Center\n"
        printf "\tIn:  lcalIp=%-16s lcalPort=%-5s rmtIp=%-16s rmtPort=%-5s \n" "${llcalIp}" "${llcalPort}" "${lrmtIp}" "${lrmtPort}"
        printf "\tOut: lcalIp=%-16s lcalPort=%-5s rmtIp=%-16s rmtPort=%-5s \n" "${rlcalIp}" "${rlcalPort}" "${rrmtIp}" "${rrmtPort}"
    fi
    if [ "${opFlag}" == "${opGen}" ];then
        echo -e "\n#数据中心配置            "
        echo -e "#入库                    "
        echo -e "InlcalPort=${llcalPort}          "
        echo -e "InlcalIp=\"${llcalIp}\" "
        echo -e "InrmtPort=${lrmtPort}           "
        echo -e "InrmtIp=\"${lrmtIp}\"   "
        echo -e "#出库                    "
        echo -e "OutlcalPort=${rlcalPort}         "
        echo -e "OutlcalIp=\"${rlcalIp}\""
        echo -e "OutrmtPort=${rrmtPort}          "
        echo -e "OutrmtIp=\"${rrmtIp}\"  \n"
    fi

    return 0
}

function F_prtOneStCfg()
{
    if [ ${tOldCfgFlag} -eq 1 ];then
        return 0
    fi

    local inNum=9
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function   ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
        local stCfgBL="$1"
        local stCfgEL="$2"
        local stCfgLclBL="$3"
        local stCfgLclEL="$4"
        local stCfgLclNL="$5"
        local stCfgRmtBL="$6"
        local stCfgRmtEL="$7"
        local stCfgRmtNL="$8"
    
        local edFile="$9"

        local tmpStr=$(sed -n "${stCfgBL} {p;q}" ${edFile})
        local stnNo=$(F_prtfindKeyVal "stationNum" "${tmpStr}")
        
        tmpStr=$(sed -n "${stCfgLclBL} {p;q}" ${edFile})
        local lrole=$(F_prtfindKeyVal "role" "${tmpStr}")
        local lname=$(F_prtfindKeyVal "name" "${tmpStr}")
        local leupId=$(F_prtfindKeyVal "equipmentID" "${tmpStr}")

        tmpStr=$(sed -n "${stCfgLclNL} {p;q}" ${edFile})
        local lport=$(F_prtfindKeyVal "port" "${tmpStr}")
        local lip=$(F_prtfindKeyVal "ip" "${tmpStr}")

        tmpStr=$(sed -n "${stCfgRmtBL} {p;q}" ${edFile})
        local rrole=$(F_prtfindKeyVal "role" "${tmpStr}")
        local rname=$(F_prtfindKeyVal "name" "${tmpStr}")
        local reupId=$(F_prtfindKeyVal "equipmentID" "${tmpStr}")

        tmpStr=$(sed -n "${stCfgRmtNL} {p;q}" ${edFile})
        local rport=$(F_prtfindKeyVal "port" "${tmpStr}")
        local rip=$(F_prtfindKeyVal "ip" "${tmpStr}")

        printf "\nstationCfg stationNum:%-2s\n" "${stnNo}"
        printf "\tlocal:  role=%-2s equipmentID=%-3s ip=%-16s port=%-5s\n" "${lrole}" "${leupId}" "${lip}" "${lport}"
        printf "\tremote: role=%-2s equipmentID=%-3s ip=%-16s port=%-5s\n" "${rrole}" "${reupId}" "${rip}" "${rport}"
    

    return 0
}

function F_prtOneChnl()
{
    local inNum=11
    local thisFName="${FUNCNAME}"
    if [ $# -lt ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num less than ${inNum}!\n"
        return 1
    fi

    local tNum=0

    local chBL="$1"
    local chEL="$2"

    local stnNoL="$3"

    #local station
    local lclStnBL="$4"
    local lclStnEL="$5"
    local lclNetL="$6"

    #remote station
    local rmtStnBL="$7"
    local rmtStnEL="$8"
    local rmtNetL="$9"

    local prtlBL="${10}"
    local edFile="${11}"
    if [ "${opFlag}" == "${opGen}" ];then
        local tIdx="${12}"
    fi

    local grpSpeStr

    local tmpStr=$(sed -n "${chBL} {p;q}" ${edFile})
    local chnNo=$(F_prtfindKeyVal "chnNum" "${tmpStr}")

    tmpStr=$(sed -n "${chBL},${chEL}{/^\s*<\s*putStagFlag\b/p;${chEL}q}" ${edFile})
    local tStorFlag=$(F_prtEchoNdVl "putStagFlag" "${tmpStr}")

    if [ ${tOldCfgFlag} -eq 0 ];then
        tmpStr=$(sed -n "${prtlBL} {p;q}" ${edFile})
        local prtlNo=$(F_prtfindKeyVal "prtlNo" "${tmpStr}")

        tmpStr=$(sed -n "${stnNoL} {p;q}" ${edFile})
        local stnNo=$(F_prtfindKeyVal "stationNum" "${tmpStr}")
        
    else
        tmpStr=$(sed -n "${chBL},${chEL}{/^\s*<\s*otherChnProp\b/=;${chEL}q}" ${edFile})
        tNum=$(echo "${tmpStr}"|wc -l)
        if [ ${tNum} -ne 1 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] chnNo=[${chnNo}] <otherChnProp> nodes configuration error!\n"
            return 1
        fi
        local tchOthBL=${tmpStr}
        tmpStr=$(sed -n "${chBL},${chEL}{/^\s*<\s*\/\s*otherChnProp\b/=;${chEL}q}" ${edFile})
        tNum=$(echo "${tmpStr}"|wc -l)
        if [ ${tNum} -ne 1 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] chnNo=[${chnNo}] </otherChnProp> nodes configuration error!\n"
            return 1
        fi
        local tchOthEL=${tmpStr}

        local prtlNo=$(F_prtNodeVals "${tchOthBL}" "${tchOthEL}" "ptclMdlNum" "${edFile}")

        local stnNo=" "
    fi
    
    if [ "${opFlag}" == "${opLin}" ];then
        printf "\nchNo:%-2s stationNum:%-2s prtlNo:%-4s \n" "${chnNo}" "${stnNo}" "${prtlNo}"
        printf "\t start_line=%-6s end_line=%-6s\n" "${chBL}" "${chEL}"
        return 0
    fi

    if [ ${tOldCfgFlag} -eq 0 ];then
        tmpStr=$(sed -n "${lclStnBL} {p;q}" ${edFile})
        local lrole=$(F_prtfindKeyVal "role" "${tmpStr}")
        local lname=$(F_prtfindKeyVal "name" "${tmpStr}")
        local leupId=$(F_prtfindKeyVal "equipmentID" "${tmpStr}")

        tmpStr=$(sed -n "${lclNetL} {p;q}" ${edFile})
        local lport=$(F_prtfindKeyVal "port" "${tmpStr}")
        local lip=$(F_prtfindKeyVal "ip" "${tmpStr}")

        tmpStr=$(sed -n "${rmtStnBL} {p;q}" ${edFile})
        local rrole=$(F_prtfindKeyVal "role" "${tmpStr}")
        local rname=$(F_prtfindKeyVal "name" "${tmpStr}")
        local reupId=$(F_prtfindKeyVal "equipmentID" "${tmpStr}")

        tmpStr=$(sed -n "${rmtNetL} {p;q}" ${edFile})
        local rport=$(F_prtfindKeyVal "port" "${tmpStr}")
        local rip=$(F_prtfindKeyVal "ip" "${tmpStr}")

        #if [ -z "${reupId}" ];then
        #    reupId=""
        #fi

        grpSpeStr=$(sed -n "${chBL},${chEL}{/^\s*<\s*grpSpe\b/p;${chEL}q}" ${edFile}|sed  's/^\s\+//g')
    else

        local lrole=$(F_prtNodeVals "${tchOthBL}" "${tchOthEL}" "role" "${edFile}")
        lrole=$(echo "${lrole}"|head -1)
        local lname=" "
        local leupId=$(F_prtNodeVals "${tchOthBL}" "${tchOthEL}" "equipmentID" "${edFile}")

        tmpStr=$(F_prtNodeLinNos "${tchOthBL}" "${tchOthEL}" "2" "remoteIP" "${edFile}")
        #echo "tmpStr=[${tmpStr}]"
        local lport=$(F_prtfindKeyVal "localport" "${tmpStr}")
        local lip=$(F_prtfindKeyVal "localip" "${tmpStr}")
        local rport=$(F_prtfindKeyVal "port" "${tmpStr}")
        local rip=$(F_prtfindKeyVal "ip" "${tmpStr}")

        local rrole=$(F_prtNodeVals "${tchOthBL}" "${tchOthEL}" "stnRole" "${edFile}")
        local rname=" "
        local reupId=" "

    fi

    if [ "${opFlag}" == "${opPrt}" ];then
        #echo -e "\nrole=[${lrole}]"
        printf "\nchNo:%-2s stationNum:%-2s prtlNo:%-4s  putStagFlag:%-2s \n" "${chnNo}" "${stnNo}" "${prtlNo}" "${tStorFlag}"
        [ ! -z "${grpSpeStr}" ] && printf "\t\t%s\n" "${grpSpeStr}"
        printf "\tlocal:  role=%-2s equipmentID=%-3s ip=%-16s port=%-5s\n" "${lrole}" "${leupId}" "${lip}" "${lport}"
        printf "\tremote: role=%-2s equipmentID=%-3s ip=%-16s port=%-5s\n" "${rrole}" "${reupId}" "${rip}" "${rport}"
    fi

    if [ "${opFlag}" == "${opChCal}" ];then
        printf "\nchNo:%-2s stationNum:%-2s prtlNo:%-4s \n" "${chnNo}" "${stnNo}" "${prtlNo}"
        sed -n "${chBL},${chEL}{/^\s*<\s*phyObjVal\b/p;${chEL}q}" ${edFile}|awk -F'[ ><]' 'BEGIN{fdIdx=0;str1="";str2="";} {for(i=1;i<=NF;i++){if($i ~/calcMethd/){str1=$i;fdIdx++;} if($i ~/hisMaxNum/){str2=$i;fdIdx++;} if(fdIdx==2){print str1,str2;fdIdx=0;break}}}'|sort|uniq -c
    fi

    if [ "${opFlag}" == "${opGen}" ];then
        #echo -e "\n"
        echo -e "doChnNo[${tIdx}]=${chnNo}                      "
        echo -e 'index=${doChnNo['${tIdx}']}               '
        echo -e 'lclStnIP[${index}]="'${lip}'"'
        echo -e 'lclStnPort[${index}]='${lport} '           '
        echo -e 'lclEquipID[${index}]='${leupId}'           '
        echo -e 'rmtStnIP[${index}]="'${rip}'"'
        echo -e 'rmtStnPort[${index}]='${rport} '         '
        #echo -e "\n"
    fi
    

    return 0
}

function F_mdOneSsn() # modify one channl's sessionCfgList
{
    if [ ${tOldCfgFlag} -eq 1 ];then
        return 0
    fi

    local thisFName="${FUNCNAME}"
    local inNum=6
    if [ $# -lt ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num less than ${inNum}!\n"
        return 1
    fi

    local tNum=0
    local tRet=0
    local i=0
    local j=0

    local edFile="$1"
    local chnNo="$2"
    shift
    local tPlNo="$2"
    local lrole="$3"
    local tBL="$4"
    local tEL="$5"

    local tmpStr
    local tmpStr1

    tmpStr=$(sed -n "${tBL} {p;q}" ${edFile})    
    local ssnDscNo=$(F_prtfindKeyVal "ssnDscNo" "${tmpStr}")
    local actFlag=$(F_prtfindKeyVal "actFlag" "${tmpStr}")
    local ssnMode=$(F_prtfindKeyVal "ssnMode" "${tmpStr}")

    local tmpPtCmt="chnl:[${chnNo}],ssnDscNo:[${ssnDscNo}]"

    local tTID
    local tCOT
    local idx

    #echo "edFile=[${edFile}]"
    #echo -e "\tchnNo=[${chnNo}],lrole=[${lrole}],tPlNo=[${tPlNo}],ssnDscNo=[${ssnDscNo}],actFlag=[${actFlag}],ssnMode=[${ssnMode}],tBL=[${tBL}],tEL=[${tEL}]"
    echo -e "\t\tline[${LINENO}]:ssnDscNo=[${ssnDscNo}],actFlag=[${actFlag}],ssnMode=[${ssnMode}],tBL=[${tBL}],tEL=[${tEL}]"

    if [ "${tPlNo}" = "104" ];then
        if [ "${lrole}" = "1" ];then #主动站
            if [ "${ssnDscNo}" = "4" ];then #突发
                F_setFixLinKeyVal "${tBL}" "actFlag" "1" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -lt 1 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                    return 1
                fi
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "1" "${edFile}" "${tmpPtCmt}"
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 1 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                    return 1
                fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "storORload" "2" "${edFile}" "${tmpPtCmt}"
                    tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    for j in ${tmpStr1}
                    do
                        F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "COT" "3" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "TID" "13" "${edFile}" "${tmpPtCmt}"
                    done 
                    let idx++
                done

            elif [ "${ssnDscNo}" = "15" ];then #激活
                F_setFixLinKeyVal "${tBL}" "actFlag" "0" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 1 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                    return 1
                fi
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "0" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "cmnAddr" "1" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "addrStart" "0" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "instNo" "0" "${edFile}" "${tmpPtCmt}"
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 2 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                    return 1
                fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "storORload" "0" "${edFile}" "${tmpPtCmt}"
                    if [ $(echo "${idx}%2"|bc) -eq 1 ];then
                        F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "reqORres" "1" "${edFile}" "${tmpPtCmt}"
                    fi
                    tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    for j in ${tmpStr1}
                    do
                        F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "COT" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "TID" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "objNum" "1" "${edFile}" "${tmpPtCmt}"
                    done 
                    let idx++
                done
            elif [ "${ssnDscNo}" = "17" ];then #测试
                F_setFixLinKeyVal "${tBL}" "actFlag" "1" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 1 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                    return 1
                fi
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "1" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "cmnAddr" "1" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "addrStart" "0" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "instNo" "0" "${edFile}" "${tmpPtCmt}"
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 2 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                    return 1
                fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "storORload" "0" "${edFile}" "${tmpPtCmt}"
                    if [ $(echo "${idx}%2"|bc) -eq 1 ];then
                        F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "reqORres" "1" "${edFile}" "${tmpPtCmt}"
                    fi
                    tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    for j in ${tmpStr1}
                    do
                        F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "COT" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "TID" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "objNum" "1" "${edFile}" "${tmpPtCmt}"
                    done 
                    let idx++
                done
            elif [ "${ssnDscNo}" = "6" ];then #站召唤
                F_setFixLinKeyVal "${tBL}" "actFlag" "0" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi

                #tNum=$(echo "${tmpStr}"|wc -l)
                #if [ ${tNum} -lt 1 ];then
                #    echo -e "\n\t\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                #    return 1
                #fi

                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "1" "${edFile}" "${tmpPtCmt}"
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 4 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                    return 1
                fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    if [ ${idx} -ne 3 ];then
                        F_setFixLinKeyVal "$i" "storORload" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "storORload" "2" "${edFile}" "${tmpPtCmt}"
                    fi
                    if [ ${idx} -eq 1 ];then
                        F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "reqORres" "1" "${edFile}" "${tmpPtCmt}"
                    fi
                    tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    tNum=$(echo "${tmpStr1}"|wc -l)
                    if [[ ${idx} -ne 3 && ${tNum} -ne 1 ]];then
                        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] step[${idx}] frame node cfg error !\n"
                        return 1
                    fi
                    for j in ${tmpStr1}
                    do
                        if [ ${idx} -eq 1 ];then
                            F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "COT" "6" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "TID" "100" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "objNum" "1" "${edFile}" "${tmpPtCmt}"
                        elif [ ${idx} -eq 2 ];then
                            F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "COT" "7" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "TID" "100" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "objNum" "1" "${edFile}" "${tmpPtCmt}"
                        elif [ ${idx} -eq 3 ];then
                            F_setFixLinKeyVal "$j" "COT" "20" "${edFile}" "${tmpPtCmt}"
                        elif [ ${idx} -eq 4 ];then
                            F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "COT" "10" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "TID" "100" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "objNum" "1" "${edFile}" "${tmpPtCmt}"
                        fi
                    done 
                    let idx++
                done
            else
                F_setFixLinKeyVal "${tBL}" "actFlag" "0" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                #tNum=$(echo "${tmpStr}"|wc -l)
                #if [ ${tNum} -lt 1 ];then
                #    echo -e "\n\t\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                #    return 1
                #fi
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "1" "${edFile}" "${tmpPtCmt}"
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                #tNum=$(echo "${tmpStr}"|wc -l)
                #if [ ${tNum} -ne 2 ];then
                #    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                #    return 1
                #fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    #F_setFixLinKeyVal "$i" "storORload" "0" "${edFile}" "${tmpPtCmt}"
                    if [ $(echo "${idx}%2"|bc) -eq 1 ];then
                        F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "reqORres" "1" "${edFile}" "${tmpPtCmt}"
                    fi
                    #tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    #for j in ${tmpStr1}
                    #do
                    #    F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                    #    F_setFixLinKeyVal "$j" "COT" "0" "${edFile}" "${tmpPtCmt}"
                    #    F_setFixLinKeyVal "$j" "TID" "0" "${edFile}" "${tmpPtCmt}"
                    #done 
                    let idx++
                done
            fi
        elif [ "${lrole}" = "2" ];then #被动站
            if [ "${ssnDscNo}" = "4" ];then #突发
                F_setFixLinKeyVal "${tBL}" "actFlag" "0" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -lt 1 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                    return 1
                fi
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "1" "${edFile}" "${tmpPtCmt}"
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 1 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                    return 1
                fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "storORload" "2" "${edFile}" "${tmpPtCmt}"
                    tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    for j in ${tmpStr1}
                    do
                        F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "COT" "3" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "TID" "13" "${edFile}" "${tmpPtCmt}"
                    done 
                    let idx++
                done

            elif [ "${ssnDscNo}" = "15" ];then #激活
                F_setFixLinKeyVal "${tBL}" "actFlag" "1" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 1 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                    return 1
                fi
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "1" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "cmnAddr" "1" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "addrStart" "0" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "instNo" "0" "${edFile}" "${tmpPtCmt}"
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 2 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                    return 1
                fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "storORload" "0" "${edFile}" "${tmpPtCmt}"
                    if [ $(echo "${idx}%2"|bc) -eq 1 ];then
                        F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "reqORres" "1" "${edFile}" "${tmpPtCmt}"
                    fi
                    tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    for j in ${tmpStr1}
                    do
                        F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "COT" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "TID" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "objNum" "1" "${edFile}" "${tmpPtCmt}"
                    done 
                    let idx++
                done
            elif [ "${ssnDscNo}" = "17" ];then #测试
                F_setFixLinKeyVal "${tBL}" "actFlag" "1" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 1 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                    return 1
                fi
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "1" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "cmnAddr" "1" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "addrStart" "0" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "instNo" "0" "${edFile}" "${tmpPtCmt}"
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 2 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                    return 1
                fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "storORload" "0" "${edFile}" "${tmpPtCmt}"
                    if [ $(echo "${idx}%2"|bc) -eq 1 ];then
                        F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "reqORres" "1" "${edFile}" "${tmpPtCmt}"
                    fi
                    tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    for j in ${tmpStr1}
                    do
                        F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "COT" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "TID" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "objNum" "1" "${edFile}" "${tmpPtCmt}"
                    done 
                    let idx++
                done
            elif [ "${ssnDscNo}" = "6" ];then #站召唤
                F_setFixLinKeyVal "${tBL}" "actFlag" "1" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi

                #tNum=$(echo "${tmpStr}"|wc -l)
                #if [ ${tNum} -lt 1 ];then
                #    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                #    return 1
                #fi

                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "1" "${edFile}" "${tmpPtCmt}"
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 4 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                    return 1
                fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    if [ ${idx} -ne 3 ];then
                        F_setFixLinKeyVal "$i" "storORload" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "storORload" "3" "${edFile}" "${tmpPtCmt}"
                    fi
                    if [ ${idx} -eq 1 ];then
                        F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "reqORres" "1" "${edFile}" "${tmpPtCmt}"
                    fi
                    tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    tNum=$(echo "${tmpStr1}"|wc -l)
                    if [[ ${idx} -ne 3 && ${tNum} -ne 1 ]];then
                        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] step[${idx}] frame node cfg error !\n"
                        return 1
                    fi
                    for j in ${tmpStr1}
                    do
                        if [ ${idx} -eq 1 ];then
                            F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "COT" "6" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "TID" "100" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "objNum" "1" "${edFile}" "${tmpPtCmt}"
                        elif [ ${idx} -eq 2 ];then
                            F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "COT" "7" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "TID" "100" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "objNum" "1" "${edFile}" "${tmpPtCmt}"
                        elif [ ${idx} -eq 3 ];then
                            F_setFixLinKeyVal "$j" "COT" "20" "${edFile}" "${tmpPtCmt}"
                        elif [ ${idx} -eq 4 ];then
                            F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "COT" "10" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "TID" "100" "${edFile}" "${tmpPtCmt}"
                            F_setFixLinKeyVal "$j" "objNum" "1" "${edFile}" "${tmpPtCmt}"
                        fi
                    done 
                    let idx++
                done
            else
                F_setFixLinKeyVal "${tBL}" "actFlag" "0" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                #tNum=$(echo "${tmpStr}"|wc -l)
                #if [ ${tNum} -lt 1 ];then
                #    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                #    return 1
                #fi
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "1" "${edFile}" "${tmpPtCmt}"
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                #tNum=$(echo "${tmpStr}"|wc -l)
                #if [ ${tNum} -ne 2 ];then
                #    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                #    return 1
                #fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    #F_setFixLinKeyVal "$i" "storORload" "0" "${edFile}" "${tmpPtCmt}"
                    if [ $(echo "${idx}%2"|bc) -eq 1 ];then
                        F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "reqORres" "1" "${edFile}" "${tmpPtCmt}"
                    fi
                    #tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    #for j in ${tmpStr1}
                    #do
                    #    F_setFixLinKeyVal "$j" "VSQ_SQ" "0" "${edFile}" "${tmpPtCmt}"
                    #    F_setFixLinKeyVal "$j" "COT" "0" "${edFile}" "${tmpPtCmt}"
                    #    F_setFixLinKeyVal "$j" "TID" "0" "${edFile}" "${tmpPtCmt}"
                    #done 
                    let idx++
                done
            fi
        fi
    elif [ "${tPlNo}" = "106" ];then
        if [ "${lrole}" = "1" ];then #主动站
            if [[ "${ssnDscNo}" = "4" || "${ssnDscNo}" = "3" || "${ssnDscNo}" = "1" ]];then #功能码3
                F_setFixLinKeyVal "${tBL}" "actFlag" "0" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi

                #tNum=$(echo "${tmpStr}"|wc -l)
                #if [ ${tNum} -lt 1 ];then
                #    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                #    return 1
                #fi

                idx=0
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "1" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "instNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    #F_setFixLinKeyVal "$i" "cmnAddr" "1" "${edFile}" "${tmpPtCmt}"
                    let idx++
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 2 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                    return 1
                fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    if [ $(echo "${idx}%2"|bc) -eq 1 ];then
                        F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$i" "storORload" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "reqORres" "1" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$i" "storORload" "1" "${edFile}" "${tmpPtCmt}"
                    fi
                    tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    tNum=$(echo "${tmpStr1}"|wc -l)
                    if [[ ${idx} -ne 3 && ${tNum} -ne 1 ]];then
                        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] step[${idx}] frame node cfg error !\n"
                        return 1
                    fi
                    for j in ${tmpStr1}
                    do
                        F_setFixLinKeyVal "$j" "tidORfuncode" "${ssnDscNo}" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "objNum" "0" "${edFile}" "${tmpPtCmt}"
                    done 
                    let idx++
                done
            fi
        elif [ "${lrole}" = "2" ];then #被动站
            if [[ "${ssnDscNo}" = "4" || "${ssnDscNo}" = "3" || "${ssnDscNo}" = "1" ]];then #功能码3
                F_setFixLinKeyVal "${tBL}" "actFlag" "1" "${edFile}" "${tmpPtCmt}"
                F_setFixLinKeyVal "${tBL}" "ssnMode" "0" "${edFile}" "${tmpPtCmt}"
                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "sessionInst")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi

                #tNum=$(echo "${tmpStr}"|wc -l)
                #if [ ${tNum} -lt 1 ];then
                #    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] sessionInst node cfg error !\n"
                #    return 1
                #fi

                idx=0
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "collMethods" "1" "${edFile}" "${tmpPtCmt}"
                    F_setFixLinKeyVal "$i" "instNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    #F_setFixLinKeyVal "$i" "cmnAddr" "1" "${edFile}" "${tmpPtCmt}"
                    let idx++
                done

                tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "ptclStep")
                tRet=$?
                if [ ${tRet} -ne 0 ];then
                    echo "${tmpStr}"
                    return ${tRet}
                fi
                tNum=$(echo "${tmpStr}"|wc -l)
                if [ ${tNum} -ne 2 ];then
                    echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] ptclStep node cfg error !\n"
                    return 1
                fi
                idx=1
                for i in ${tmpStr}
                do
                    F_setFixLinKeyVal "$i" "stepNo" "${idx}" "${edFile}" "${tmpPtCmt}"
                    if [ $(echo "${idx}%2"|bc) -eq 1 ];then
                        F_setFixLinKeyVal "$i" "reqORres" "0" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$i" "storORload" "0" "${edFile}" "${tmpPtCmt}"
                    else
                        F_setFixLinKeyVal "$i" "reqORres" "1" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$i" "storORload" "1" "${edFile}" "${tmpPtCmt}"
                    fi
                    tmpStr1=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 3 "$i" "ptclStep" "frame")
                    tNum=$(echo "${tmpStr1}"|wc -l)
                    if [[ ${idx} -ne 3 && ${tNum} -ne 1 ]];then
                        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ssnDscNo[${ssnDscNo}] step[${idx}] frame node cfg error !\n"
                        return 1
                    fi
                    for j in ${tmpStr1}
                    do
                        F_setFixLinKeyVal "$j" "tidORfuncode" "${ssnDscNo}" "${edFile}" "${tmpPtCmt}"
                        F_setFixLinKeyVal "$j" "objNum" "0" "${edFile}" "${tmpPtCmt}"
                    done 
                    let idx++
                done
            fi
        fi
    fi


    return 0
}

function F_mdOneApduDsc() # modify one channl's APDU_DSCR
{
    if [ ${tOldCfgFlag} -eq 1 ];then
        return 0
    fi

    local thisFName="${FUNCNAME}"
    local inNum=6
    if [ $# -lt ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num less than ${inNum}!\n"
        return 1
    fi

    local tNum=0
    local tRet=0
    local i=0
    local j=0

    local edFile="$1"
    local chnNo="$2"
    shift
    local tPlNo="$2"
    local lrole="$3"
    local tBL="$4"
    local tEL="$5"

    local tmpStr
    local tmpStr1

    tmpStr=$(sed -n "${tBL} {p;q}" ${edFile}|sed -e 's///g;s/^\s\+//g;s/\s\+$//g')    
    local tmpPtCmt="chnl:[${chnNo}],lrole:[${lrole}]"

    #echo "edFile=[${edFile}]"
    echo -e "\t\t${tmpStr}"

    local chkStr="APCI ASDU_TID ASDU_LNG ASDU_VSQ ASDU_COT ASDU_ADDR BODY_TID BODY_ADDR BODY_SET BODY_TSP ASDU_TSP"

    local lineNo_apci
    local lineNo_tid
    local lineNo_lng
    local lineNo_vsq
    local lineNo_cot
    local lineNo_addr
    local lineNo_btid
    local lineNo_baddr
    local lineNo_bset
    local lineNo_btsp
    local lineNo_tsp

    local tidx
    local i=1
    for tidx in ${chkStr}
    do
        tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 0 "${tBL}" "${tEL}" "${tidx}")
        tRet=$?
        if [ ${tRet} -ne 0 ];then
            echo "${tmpStr}"
            return ${tRet}
        fi
        tNum=$(echo "${tmpStr}"|wc -l)
        if [ ${tNum} -ne 1 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s ${tidx} node cfg error !\n"
            return 1
        fi

        if [ $i -eq 1 ];then
            lineNo_apci=${tmpStr}
        elif [ $i -eq 2 ];then
            lineNo_tid=${tmpStr}
        elif [ $i -eq 3 ];then
            lineNo_lng=${tmpStr}
        elif [ $i -eq 4 ];then
            lineNo_vsq=${tmpStr}
        elif [ $i -eq 5 ];then
            lineNo_cot=${tmpStr}
        elif [ $i -eq 6 ];then
            lineNo_addr=${tmpStr}
        elif [ $i -eq 7 ];then
            lineNo_btid=${tmpStr}
        elif [ $i -eq 8 ];then
            lineNo_baddr=${tmpStr}
        elif [ $i -eq 9 ];then
            lineNo_bset=${tmpStr}
        elif [ $i -eq 10 ];then
            lineNo_btsp=${tmpStr}
        elif [ $i -eq 11 ];then
            lineNo_tsp=${tmpStr}
        fi

        let i++
    done


    if [ "${tPlNo}" = "104" ];then
        if [ "${lrole}" = "1" ];then #主动站
            F_setFixLinKeyVal "${tBL}" "ASDU_TID" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${tBL}" "asduCmtbNum" "11" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${tBL}" "InfoEleLng" "5" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_apci}" "value" "6" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_tid}" "value" "1" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_lng}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_vsq}" "value" "1" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_cot}" "value" "2" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_addr}" "value" "2" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_btid}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_baddr}" "value" "3" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_bset}" "value" "48" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_btsp}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_tsp}" "value" "0" "${edFile}" "${tmpPtCmt}"
        elif [ "${lrole}" = "2" ];then #被动站
            F_setFixLinKeyVal "${tBL}" "ASDU_TID" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${tBL}" "asduCmtbNum" "11" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${tBL}" "InfoEleLng" "5" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_apci}" "value" "6" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_tid}" "value" "1" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_lng}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_vsq}" "value" "1" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_cot}" "value" "2" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_addr}" "value" "2" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_btid}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_baddr}" "value" "3" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_bset}" "value" "48" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_btsp}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_tsp}" "value" "0" "${edFile}" "${tmpPtCmt}"
        fi
    elif [ "${tPlNo}" = "106" ];then
        if [ "${lrole}" = "1" ];then #主动站
            F_setFixLinKeyVal "${tBL}" "ASDU_TID" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${tBL}" "asduCmtbNum" "11" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${tBL}" "InfoEleLng" "1" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_apci}" "value" "7" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_tid}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_lng}" "value" "1" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_vsq}" "value" "248" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_cot}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_addr}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_btid}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_baddr}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_bset}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_btsp}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_tsp}" "value" "0" "${edFile}" "${tmpPtCmt}"
        elif [ "${lrole}" = "2" ];then #被动站
            F_setFixLinKeyVal "${tBL}" "ASDU_TID" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${tBL}" "asduCmtbNum" "11" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${tBL}" "InfoEleLng" "1" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_apci}" "value" "7" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_tid}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_lng}" "value" "1" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_vsq}" "value" "248" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_cot}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_addr}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_btid}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_baddr}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_bset}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_btsp}" "value" "0" "${edFile}" "${tmpPtCmt}"
            F_setFixLinKeyVal "${lineNo_tsp}" "value" "0" "${edFile}" "${tmpPtCmt}"
        fi
    fi

    return 0
}

function F_mdOneChlSome() # modify one channl's some detail node
{
    if [ ${tOldCfgFlag} -eq 1 ];then
        return 0
    fi

    local thisFName="${FUNCNAME}"
    local inNum=11
    if [ $# -lt ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num less than ${inNum}!\n"
        return 1
    fi

    local tNum=0
    local tRet=0
    local i=0

    local chBL="$1"
    local chEL="$2"

    local stnNoL="$3"

    #local station
    local lclStnBL="$4"
    local lclStnEL="$5"
    local lclNetL="$6"

    #remote station
    local rmtStnBL="$7"
    local rmtStnEL="$8"
    local rmtNetL="$9"

    local prtlBL="${10}"
    local edFile="${11}"

    local tmpStr=$(sed -n "${chBL} {p;q}" ${edFile})
    local chnNo=$(F_prtfindKeyVal "chnNum" "${tmpStr}")

    tmpStr=$(sed -n "${prtlBL} {p;q}" ${edFile})
    local prtlNo=$(F_prtfindKeyVal "prtlNo" "${tmpStr}")

    #tmpStr=$(sed -n "${stnNoL} {p;q}" ${edFile})
    #local stnNo=$(F_prtfindKeyVal "stationNum" "${tmpStr}")
    

    tmpStr=$(sed -n "${lclStnBL} {p;q}" ${edFile})
    local lrole=$(F_prtfindKeyVal "role" "${tmpStr}")

    #local lname=$(F_prtfindKeyVal "name" "${tmpStr}")
    #local leupId=$(F_prtfindKeyVal "equipmentID" "${tmpStr}")

    #tmpStr=$(sed -n "${lclNetL} {p;q}" ${edFile})
    #local lport=$(F_prtfindKeyVal "port" "${tmpStr}")
    #local lip=$(F_prtfindKeyVal "ip" "${tmpStr}")

    #tmpStr=$(sed -n "${rmtStnBL} {p;q}" ${edFile})
    #local rrole=$(F_prtfindKeyVal "role" "${tmpStr}")
    #local rname=$(F_prtfindKeyVal "name" "${tmpStr}")
    #local reupId=$(F_prtfindKeyVal "equipmentID" "${tmpStr}")

    #tmpStr=$(sed -n "${rmtNetL} {p;q}" ${edFile})
    #local rport=$(F_prtfindKeyVal "port" "${tmpStr}")
    #local rip=$(F_prtfindKeyVal "ip" "${tmpStr}")

    if [[ "${prtlNo}" != "104" && "${prtlNo}" != "106" ]];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s prtlNo=[${prtlNo}} is undefined !\n"
        return 1
    fi

    if [[ "${lrole}" != "1" && "${lrole}" != "2" ]];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s lrole=[${lrole}} is undefined !\n"
        return 1
    fi

    tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 2 "${chBL}" "${chEL}" "APDU_DSCR" )
    tRet=$?
    if [ ${tRet} -ne 0 ];then
        echo "${tmpStr}"
        return ${tRet}
    fi
    tNum=$(echo "${tmpStr}"|wc -l)
    if [ ${tNum} -ne 2 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s APDU_DSCR node cfg error !\n"
        return 1
    fi
    local apduDscBL=$(echo "${tmpStr}"|head -1)
    local apduDscEL=$(echo "${tmpStr}"|tail -1)

    tmpStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 2 "${chBL}" "${chEL}" "sessionCfgList" )
    tRet=$?
    if [ ${tRet} -ne 0 ];then
        echo "${tmpStr}"
        return ${tRet}
    fi
    tNum=$(echo "${tmpStr}"|wc -l)
    if [ ${tNum} -ne 2 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s sessionCfgList node cfg error !\n"
        return 1
    fi

    local ssnLstBL=$(echo "${tmpStr}"|head -1)
    local ssnLstEL=$(echo "${tmpStr}"|tail -1)

    local sCfgStr=$(F_fndXmlNodeAttrLNo "node" "${edFile}" 2 "${ssnLstBL}" "${ssnLstEL}" "sessionCfg" )
    tRet=$?
    if [ ${tRet} -ne 0 ];then
        echo "${sCfgStr}"
        return ${tRet}
    fi
    tNum=$(echo "${sCfgStr}"|wc -l)
    if [ ${tNum} -lt 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chnNo[${chnNo}]'s sessionCfg node cfg error !\n"
        return 1
    fi

    local machIdx=0
    local tOneBl
    local tOneEl
    local tRetMsg
    echo -e "\tchnNo=[\e[1;31m${chnNo}\e[0m],lrole=[\e[1;31m${lrole}\e[0m],tPlNo=[\e[1;31m${prtlNo}\e[0m]"

    F_mdOneApduDsc ${edFile} ${chnNo} ${prtlNo} ${lrole} ${apduDscBL} ${apduDscEL}

    for i in ${sCfgStr}
    do
        if [[ ${machIdx} -eq 0 || ${machIdx} -gt 2 ]];then
            tOneBl=$i
            machIdx=1
        else
            tOneEl=$i
            #tRetMsg=$(F_mdOneSsn ${edFile} ${chnNo} ${prtlNo} ${lrole} ${tOneBl} ${tOneEl})
            F_mdOneSsn ${edFile} ${chnNo} ${prtlNo} ${lrole} ${tOneBl} ${tOneEl}
            tRet=$?
            if [ ${tRet} -ne 0 ];then
                #echo "${tRetMsg}"
                #return 1
                continue
            fi
        fi
        let machIdx++
    done
    
    return 0
}





if [ "${opFlag}" != "${opMdGV}" ];then
    #F_setFixLinKeyVal "1513" "port" "0" "${edFile}"

    #echo "tOldCfgFlag=[${tOldCfgFlag}]"

    sed -n '/^\s*<\s*[/]*channel\b/=' ${edFile} >${tmChFile}
    if [ ${tOldCfgFlag} -eq 0 ];then
        sed -n '/^\s*<\s*[/]*stations\b/=' ${edFile} >${tmStsFile}
        stsBL=$(sed -n '1{p;q}' ${tmStsFile})
        stsEL=$(sed -n '2{p;q}' ${tmStsFile})
        #echo "stsBL=$stsBL stsEL=$stsEL "
        sed -n "${stsBL},${stsEL}{/^\s*<\s*[/]*stationCfg\b/=;${stsEL}q}" ${edFile} >${tmStsFile}
    fi



    #######prepare datacenter
    #daInIpBL=$(sed -n '/^\s*<\s*dataInIP\b/=' ${edFile})
    #daOutIpBL=$(sed -n '/^\s*<\s*dataOutIP\b/=' ${edFile})
    daInIpBL=$(sed -n '/^\s*<\s*dataInIP\b/{=;/^\s*<\s*\/\s*sysCfg\b/q}' ${edFile})
    daOutIpBL=$(sed -n '/^\s*<\s*dataOutIP\b/{=;/^\s*<\s*\/\s*sysCfg\b/q}' ${edFile})


    #######prepare stationCfg
    i=0
    arrIdx=0
    if [[ "${opFlag}" != "${opMd}" &&  "${opFlag}" != "${opMdV}" && "${opFlag}" != "${opMdVSByN}" && ${tOldCfgFlag} -eq 0 ]];then 
        while read tnaa
        do
            if [[ $i -eq 0 || $i -gt 1 ]];then
                stCfgBL[${arrIdx}]=${tnaa}
                i=0
            else
                stCfgEL[${arrIdx}]=${tnaa}

                #stCfgNoL[${arrIdx}]="stCfgBL[${arrIdx}]"
                tmpStr=$(sed -n "${stCfgBL[${arrIdx}]} {p;q}" ${edFile})
                stCfgNo[${arrIdx}]=$(F_prtfindKeyVal "stationNum" "${tmpStr}")

                #local station
                stCfgLclBL[${arrIdx}]=$(sed -n "${stCfgBL[${arrIdx}]},${stCfgEL[${arrIdx}]}{/^\s*<\s*localStation\b/=;${stCfgEL[${arrIdx}]}q}" ${edFile})
                stCfgLclEL[${arrIdx}]=$(sed -n "${stCfgBL[${arrIdx}]},${stCfgEL[${arrIdx}]}{/^\s*<\s*\/\s*localStation\b/=;${stCfgEL[${arrIdx}]}q}" ${edFile})
                stCfgLclNL[${arrIdx}]=$(sed -n "${stCfgLclBL[${arrIdx}]},${stCfgLclEL[${arrIdx}]}{/^\s*<\s*netAddr\b/=;${stCfgLclEL[${arrIdx}]}q}" ${edFile})

                #remote station
                stCfgRmtBL[${arrIdx}]=$(sed -n "${stCfgBL[${arrIdx}]},${stCfgEL[${arrIdx}]}{/^\s*<\s*remoteStation\b/=;${stCfgEL[${arrIdx}]}q}" ${edFile})
                stCfgRmtEL[${arrIdx}]=$(sed -n "${stCfgBL[${arrIdx}]},${stCfgEL[${arrIdx}]}{/^\s*<\s*\/\s*remoteStation\b/=;${stCfgEL[${arrIdx}]}q}" ${edFile})
                stCfgRmtNL[${arrIdx}]=$(sed -n "${stCfgRmtBL[${arrIdx}]},${stCfgRmtEL[${arrIdx}]}{/^\s*<\s*netAddr\b/=;${stCfgRmtEL[${arrIdx}]}q}" ${edFile})

                let arrIdx++
            fi
            let i++
        done<${tmStsFile}
    fi
    stCfgNum=${#stCfgBL[*]}


    #####prepare channels
    i=0
    arrIdx=0
    while read tnaa
    do
        if [[ $i -eq 0 || $i -gt 1 ]];then
            chBL[${arrIdx}]=${tnaa}
            i=0
        else
            chEL[${arrIdx}]=${tnaa}

            if [ ${tOldCfgFlag} -eq 0 ];then
                stnNoL[${arrIdx}]=$(sed -n "${chBL[${arrIdx}]},${chEL[${arrIdx}]}{/^\s*<\s*stationCfg\b/=;${chEL[${arrIdx}]}q}" ${edFile})
                tmpStr=$(sed -n "${stnNoL[${arrIdx}]} {p;q}" ${edFile})
                stnNo[${arrIdx}]=$(F_prtfindKeyVal "stationNum" "${tmpStr}")

                #local station
                lclStnBL[${arrIdx}]=$(sed -n "${chBL[${arrIdx}]},${chEL[${arrIdx}]}{/^\s*<\s*localStation\b/=;${chEL[${arrIdx}]}q}" ${edFile})
                lclStnEL[${arrIdx}]=$(sed -n "${chBL[${arrIdx}]},${chEL[${arrIdx}]}{/^\s*<\s*\/\s*localStation\b/=;${chEL[${arrIdx}]}q}" ${edFile})
                lclNetL[${arrIdx}]=$(sed -n "${lclStnBL[${arrIdx}]},${lclStnEL[${arrIdx}]}{/^\s*<\s*netAddr\b/=;${lclStnEL[${arrIdx}]}q}" ${edFile})

                #remote station
                rmtStnBL[${arrIdx}]=$(sed -n "${chBL[${arrIdx}]},${chEL[${arrIdx}]}{/^\s*<\s*remoteStation\b/=;${chEL[${arrIdx}]}q}" ${edFile})
                rmtStnEL[${arrIdx}]=$(sed -n "${chBL[${arrIdx}]},${chEL[${arrIdx}]}{/^\s*<\s*\/\s*remoteStation\b/=;${chEL[${arrIdx}]}q}" ${edFile})
                rmtNetL[${arrIdx}]=$(sed -n "${rmtStnBL[${arrIdx}]},${rmtStnEL[${arrIdx}]}{/^\s*<\s*netAddr\b/=;${rmtStnEL[${arrIdx}]}q}" ${edFile})

                #prtl
                prtlBL[${arrIdx}]=$(sed -n "${chBL[${arrIdx}]},${chEL[${arrIdx}]}{/^\s*<\s*prtl\b/=;${chEL[${arrIdx}]}q}" ${edFile})
            fi

            let arrIdx++
        fi
        let i++
    done<${tmChFile}

    chNum=${#chBL[*]}

    #echo "arrIdx=[${arrIdx}],chNum=[${chNum}]"
fi








#此函数应该在 preare stationCfg 及 chanels 之后，因为函数里直接用到了上面的输出值
function F_setDataCtIP()
{

    local thisFName="${FUNCNAME}"
    if [ -z "${daInIpBL}" ];then
        echo -e "\n\tline[${LINENO}]: not exist dataInIP xml local station\n"
        return 2
    fi
    if [ -z "${daOutIpBL}" ];then
        echo -e "\n\tline[${LINENO}]: not exist dataOutIP xml local station\n"
        return 3
    fi

    local tmpPtCmt="In Data Center"
    #Data Center
    [ ! -z "${InlcalPort}" ] && F_setFixLinKeyVal "${daInIpBL}" "lcalPort" "${InlcalPort}" "${edFile}" "${tmpPtCmt}"
    [ ! -z "${InlcalIp}" ] && F_setFixLinKeyVal "${daInIpBL}" "lcalIp" "${InlcalIp}" "${edFile}" "${tmpPtCmt}"
    [ ! -z "${InrmtPort}" ] && F_setFixLinKeyVal "${daInIpBL}" "rmtPort" "${InrmtPort}" "${edFile}" "${tmpPtCmt}"
    [ ! -z "${InrmtIp}" ] && F_setFixLinKeyVal "${daInIpBL}" "rmtIp" "${InrmtIp}" "${edFile}" "${tmpPtCmt}"

    [ ! -z "${OutlcalPort}" ] && F_setFixLinKeyVal "${daOutIpBL}" "lcalPort" "${OutlcalPort}" "${edFile}" "${tmpPtCmt}"
    [ ! -z "${OutlcalIp}" ] && F_setFixLinKeyVal "${daOutIpBL}" "lcalIp" "${OutlcalIp}" "${edFile}" "${tmpPtCmt}"
    [ ! -z "${OutrmtPort}" ] && F_setFixLinKeyVal "${daOutIpBL}" "rmtPort" "${OutrmtPort}" "${edFile}" "${tmpPtCmt}"
    [ ! -z "${OutrmtIp}" ] && F_setFixLinKeyVal "${daOutIpBL}" "rmtIp" "${OutrmtIp}" "${edFile}" "${tmpPtCmt}"

    return 0
}


#此函数应该在 preare stationCfg 及 chanels 之后，因为函数里直接用到了上面的输出值
function F_setOneChnAbtIP()
{
    local inNum=1
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi

    local tChnNo="$1"
    local tmpStr

    if [ ${tOldCfgFlag} -eq 0 ];then
        if [ -z "${lclStnIP[${tChnNo}]}" ];then
            echo -e "\n\tline[${LINENO}]: not exist channel[${tChnNo}] 's cfg\n"
            return 2
        fi
        if [ -z "${lclStnBL[${tChnNo}]}" ];then
            echo -e "\n\tline[${LINENO}]: not exist channel[${tChnNo}] 's xml local station\n"
            return 3
        fi

        local tmpPtCmt="chnl:${tChnNo} stationNo:${stnNo[${tChnNo}]}"
    else
        local tmpPtCmt="chnl:${tChnNo} "

        tmpStr=$(sed -n "${chBL[${tChnNo}]},${chEL[${tChnNo}]}{/^\s*<\s*otherChnProp\b/=;${chEL[${tChnNo}]}q}" ${edFile})
        tNum=$(echo "${tmpStr}"|wc -l)
        if [ ${tNum} -ne 1 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] chnNo=[${chnNo}] <otherChnProp> nodes configuration error!\n"
            return 1
        fi
        local tchOthBL=${tmpStr}
        tmpStr=$(sed -n "${chBL[${tChnNo}]},${chEL[${tChnNo}]}{/^\s*<\s*\/\s*otherChnProp\b/=;${chEL[${tChnNo}]}q}" ${edFile})
        tNum=$(echo "${tmpStr}"|wc -l)
        if [ ${tNum} -ne 1 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] chnNo=[${chnNo}] </otherChnProp> nodes configuration error!\n"
            return 1
        fi
        local tchOthEL=${tmpStr}
        local tOldStLin=$(F_prtNodeLinNos "${tchOthBL}" "${tchOthEL}" "1" "remoteIP" "${edFile}") 

        #echo "tchOthBL=[${tchOthBL}],tchOthEL=[${tchOthEL}],tOldStLin=[${tOldStLin}]"
        #reutrn 0
    fi

    #change channel
    local tLin
    if [ ! -z "${lclEquipID[${tChnNo}]}" ];then 
        if [ ${tOldCfgFlag} -eq 0 ];then
            F_setFixLinKeyVal "${lclStnBL[${tChnNo}]}" "equipmentID" "${lclEquipID[${tChnNo}]}" "${edFile}" "${tmpPtCmt}"
        else
            tLin=$(F_prtNodeLinNos "${tchOthBL}" "${tchOthEL}" "0" "equipmentID" "${edFile}")
            F_setFixLNdVal "${tLin}" "equipmentID" "${lclEquipID[${tChnNo}]}" "${edFile}" "${tmpPtCmt}"
        fi
    fi
    if [ ! -z "${lclStnIP[${tChnNo}]}" ];then
        if [ ${tOldCfgFlag} -eq 0 ];then
            F_setFixLinKeyVal "${lclNetL[${tChnNo}]}" "ip" "${lclStnIP[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
        else
            F_setFixLinKeyVal "${tOldStLin}" "localip" "${lclStnIP[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
        fi
    fi
    if [ ! -z "${lclStnPort[${tChnNo}]}" ];then
        if [ ${tOldCfgFlag} -eq 0 ];then
            F_setFixLinKeyVal "${lclNetL[${tChnNo}]}" "port" "${lclStnPort[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
        else
            F_setFixLinKeyVal "${tOldStLin}" "localport" "${lclStnPort[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
        fi
    fi
    if [ ! -z "${rmtStnIP[${tChnNo}]}" ];then
        if [ ${tOldCfgFlag} -eq 0 ];then
            F_setFixLinKeyVal "${rmtNetL[${tChnNo}]}" "ip" "${rmtStnIP[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
        else
            F_setFixLinKeyVal "${tOldStLin}" "ip" "${rmtStnIP[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
        fi
    fi
    if [ ! -z "${rmtStnPort[${tChnNo}]}" ];then
        if [ ${tOldCfgFlag} -eq 0 ];then
            F_setFixLinKeyVal "${rmtNetL[${tChnNo}]}" "port" "${rmtStnPort[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
        else
            F_setFixLinKeyVal "${tOldStLin}" "port" "${rmtStnPort[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
        fi
    fi

    if [ ${tOldCfgFlag} -eq 0 ];then
        #find channel's about station cfg
        local fIdx=99999
        for ((i=0;i<${stCfgNum};i++))
        do
            if [ "${stnNo[${tChnNo}]}" == "${stCfgNo[$i]}" ];then
                fIdx=$i
                break
            fi
        done

        tmpPtCmt="stnCfg stationNo:${stnNo[${tChnNo}]}"
        #change channel's about station cfg
        if [ ${fIdx} -lt 99999 ];then
            [ ! -z "${lclEquipID[${tChnNo}]}" ] && F_setFixLinKeyVal "${stCfgLclBL[${tChnNo}]}" "equipmentID" "${lclEquipID[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
            [ ! -z "${lclStnIP[${tChnNo}]}" ] && F_setFixLinKeyVal "${stCfgLclNL[${tChnNo}]}" "ip" "${lclStnIP[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
            [ ! -z "${lclStnPort[${tChnNo}]}" ] && F_setFixLinKeyVal "${stCfgLclNL[${tChnNo}]}" "port" "${lclStnPort[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
            [ ! -z "${rmtStnIP[${tChnNo}]}" ] && F_setFixLinKeyVal "${stCfgRmtNL[${tChnNo}]}" "ip" "${rmtStnIP[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
            [ ! -z "${rmtStnPort[${tChnNo}]}" ] && F_setFixLinKeyVal "${stCfgRmtNL[${tChnNo}]}" "port" "${rmtStnPort[${tChnNo}]}" "${edFile}"  "${tmpPtCmt}"
        fi
    fi

    return 0
}

function F_addPntAdNdAttrVal() #修改新配置文件scdCfg.xml中pntAddr 结点的属性值，在原值的基础上+tAddVal
{
    if [ ${tOldCfgFlag} -eq 1 ];then
        return 0
    fi

    local inNum=4
    local thisFName="${FUNCNAME}"
    if [ $# -lt ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num less than ${inNum}!\n"
        return 1
    fi
    local edFile="$1"
    if [ ! -e "${edFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] not exist!\n"
        return 3
    fi
    
    if [[ -z "${stCfgNum}" || ${stCfgNum} -lt 1 ]];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] global station stCfgNum=[${stCfgNum}] !\n"
        return 3
    fi
    if [[ -z "${chNum}" || ${chNum} -lt 1 ]];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] channel chNum=[${chNum}] !\n"
        return 3
    fi

    local tStationNo="$2"
    local tAttrName="$3"
    local tAddVal="$4"
    local tRange=0
    [ $# -gt 4 ] && local tRange="$5"
    [ $# -gt 5 ] && local refStr="$6"

    echo -e "\n\t\e[1;31mTIPS:\e[0m edit file=[${edFile}],tStationNo[${tStationNo}],tAttrName=[${tAttrName}],tAddVal=[${tAddVal}]\n"

    local i=0
    local tMchGIdx=-1
    local tMchChIdx=-1
    #find global stations idx
    if [[ ${tRange} -eq 0 || ${tRange} -eq 1 ]];then
        for ((i=0;i<${stCfgNum};i++))
        do
            if [ ${stCfgNo[$i]} -eq ${tStationNo} ];then
                tMchGIdx="$i"
                break
            fi
        done

        if [ ${tMchGIdx} -lt 0 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m tStationNo[${tStationNo}] in global stations not find" 
            return 0
        fi
    fi

    #find channel stations idx
    if [[ ${tRange} -eq 0 || ${tRange} -eq 2 ]];then
        for ((i=0;i<${chNum};i++))
        do
            if [ ${stnNo[$i]} -eq ${tStationNo} ];then
                tMchChIdx="$i"
                break
            fi
        done
        if [ ${tMchChIdx} -lt 0 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m tStationNo[${tStationNo}] in channel stations not find" 
            return 0
        fi
    fi


    local tnaa
    #modify global stations 
    if [[ ${tRange} -eq 0 || ${tRange} -eq 1 ]];then
        sed -n "${stCfgBL[${tMchGIdx}]},${stCfgEL[${tMchGIdx}]} {/^\s*<\s*pntAddr\b/=;${stCfgEL[${tMchGIdx}]}q}" ${edFile}|while read tnaa
        do
            F_addXmlNdAttVal "${edFile}" "${tnaa}" "pntAddr" "${tAttrName}" "${tAddVal}" "" "${refStr}"
        done
    fi

    #modify channel stations 
    if [[ ${tRange} -eq 0 || ${tRange} -eq 2 ]];then
        sed -n "${chBL[${tMchChIdx}]},${chEL[${tMchChIdx}]} {/^\s*<\s*pntAddr\b/=;${chEL[${tMchChIdx}]}q}" ${edFile}|while read tnaa
        do
            F_addXmlNdAttVal "${edFile}" "${tnaa}" "pntAddr" "${tAttrName}" "${tAddVal}" "" "${refStr}"
    done
    fi


    return 0

}

function F_mdAdvalRefOside() #修改新配置文件scdCfg.xml中pntAddr 结点的remoteAddr属性值，在localAddr原值的基础上+tAddVal;或修改localAddr属性值，在remoteAddr原值的基础上+tAddVal;
{
    if [ ${tOldCfgFlag} -eq 1 ];then
        return 0
    fi

    local inNum=4
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    local edFile="$1"
    if [ ! -e "${edFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] not exist!\n"
        return 3
    fi
    
    if [[ -z "${stCfgNum}" || ${stCfgNum} -lt 1 ]];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] global station stCfgNum=[${stCfgNum}] !\n"
        return 3
    fi
    if [[ -z "${chNum}" || ${chNum} -lt 1 ]];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] channel chNum=[${chNum}] !\n"
        return 3
    fi

    local tStationNo="$2"
    local tAttrName="$3"
    local tAddVal="$4"

    #Trim()
    tAttrName=$(echo "${tAttrName}"|sed -e 's/^\s*//g;s/\s*$//g')
    if [[ "${tAttrName}" != "remoteAddr" && "${tAttrName}" != "localAddr" ]];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} input para tAttrName=[${tAttrName}] non-compliant !\n"
        return 3
    fi

    local toBeAddAttrN="remoteAddr"
    if [  "${tAttrName}" = "remoteAddr" ];then
        toBeAddAttrN="localAddr"
    fi

    echo -e "\n\t\e[1;31mTIPS:\e[0m edit file=[${edFile}],tStationNo[${tStationNo}],tAttrName=[${tAttrName}],tAddVal=[${tAddVal}],toBeAddAttrN=[${toBeAddAttrN}]\n"

    local i=0
    local tMchGIdx=-1
    local tMchChIdx=-1
    #find global stations idx
    for ((i=0;i<${stCfgNum};i++))
    do
        if [ ${stCfgNo[$i]} -eq ${tStationNo} ];then
            tMchGIdx="$i"
            break
        fi
    done

    if [ ${tMchGIdx} -lt 0 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m tStationNo[${tStationNo}] in global stations not find" 
        return 0
    fi

    #find channel stations idx
    for ((i=0;i<${chNum};i++))
    do
        if [ ${stnNo[$i]} -eq ${tStationNo} ];then
            tMchChIdx="$i"
            break
        fi
    done
    if [ ${tMchChIdx} -lt 0 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m tStationNo[${tStationNo}] in channel stations not find" 
        return 0
    fi


    local tnaa
    local toBeAddVal
    local tmpStr
    local tNodeName="pntAddr"

    #modify global stations 
    sed -n "${stCfgBL[${tMchGIdx}]},${stCfgEL[${tMchGIdx}]} {/^\s*<\s*${tNodeName}\b/=;${stCfgEL[${tMchGIdx}]}q}" ${edFile}|while read tnaa
    do
        tmpStr=$(sed -n "${tnaa} {p;q}" ${edFile})
        toBeAddVal=$(F_prtfindKeyVal "${toBeAddAttrN}" "${tmpStr}")
        if [ -z "${toBeAddVal}" ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m line[${tnaa}] tStationNo[${tStationNo}] [${toBeAddAttrN}] not find" 
            continue
        fi
        F_addXmlNdAttVal "${edFile}" "${tnaa}" "${tNodeName}" "${tAttrName}" "${tAddVal}" "${toBeAddVal}" ""
    done

    #modify channel stations 
    sed -n "${chBL[${tMchChIdx}]},${chEL[${tMchChIdx}]} {/^\s*<\s*${tNodeName}\b/=;${chEL[${tMchChIdx}]}q}" ${edFile}|while read tnaa
    do
        tmpStr=$(sed -n "${tnaa} {p;q}" ${edFile})
        toBeAddVal=$(F_prtfindKeyVal "${toBeAddAttrN}" "${tmpStr}")
        if [ -z "${toBeAddVal}" ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m line[${tnaa}] tStationNo[${tStationNo}] [${toBeAddAttrN}] not find" 
            continue
        fi
        F_addXmlNdAttVal "${edFile}" "${tnaa}" "${tNodeName}" "${tAttrName}" "${tAddVal}" "${toBeAddVal}" ""
    done


    return 0

}


function F_setChnPhyOrderVal() #修改新配置文件scdCfg.xml中某个或全部通道的phyType值（按某个值递增）
{
    #if [ ${tOldCfgFlag} -eq 1 ];then
    #    return 0
    #fi

    local inNum=4
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    local edFile="$1"
    if [ ! -e "${edFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] not exist!\n"
        return 3
    fi
    
    if [[ -z "${chNum}" || ${chNum} -lt 1 ]];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] channel chNum=[${chNum}] !\n"
        return 3
    fi

    local chnNo="$2"
    local tBgVal="$3"
    local tAddVal="$4"


    echo -e "\n\t\e[1;31mTIPS:\e[0m edit file=[${edFile}],chnNo[${chnNo}] \n"

    local i=0
    local tMchChIdx=-1

    local tFixChnNo
    local tmpStr
    local tnaa
    local newVal
    local tmpPtCmt

    if [ "${chnNo}" != "all" ];then
        tmpPtCmt="chnNo:${chnNo}"
        #find channel stations idx
        for ((i=0;i<${chNum};i++))
        do
            tmpStr=$(sed -n "${chBL[$i]} {p;q}" ${edFile}) 
            tFixChnNo=$(F_prtfindKeyVal "chnNum" "${tmpStr}")
            if [ ${tFixChnNo} -eq ${chnNo} ];then
                tMchChIdx="$i"
                break
            fi
        done
        if [ ${tMchChIdx} -lt 0 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m chnNo[${chnNo}] in channel stations not find" 
            return 0
        fi
        sed -n "${chBL[${tMchChIdx}]},${chEL[${tMchChIdx}]}{/^\s*<\s*phyObjVal\b/=;${chEL[${tMchChIdx}]}q}" ${edFile} >${tmchphyFile}
        newVal=${tBgVal}
        while read tnaa
        do
            F_setFixLinKeyVal "${tnaa}" "phyType" "${newVal}" "${edFile}" "${tmpPtCmt}"
            let newVal+=${tAddVal}
        done<${tmchphyFile}
    else
        #find channel stations idx
        for ((i=0;i<${chNum};i++))
        do
            tmpStr=$(sed -n "${chBL[$i]} {p;q}" ${edFile}) 
            tFixChnNo=$(F_prtfindKeyVal "chnNum" "${tmpStr}")
            tmpPtCmt="chnNo:${tFixChnNo}"
            echo -e "\n\tdoing \e[1;31m${tmpPtCmt}\e[0m\n"

            sed -n "${chBL[${i}]},${chEL[${i}]}{/^\s*<\s*phyObjVal\b/=;${chEL[${i}]}q}" ${edFile} >${tmchphyFile}

            newVal=${tBgVal}

            while read tnaa
            do
                F_setFixLinKeyVal "${tnaa}" "phyType" "${newVal}" "${edFile}" "${tmpPtCmt}"
                let newVal+=${tAddVal}
            done<${tmchphyFile}
        done
    fi


    return 0

}


function F_delGStDumpRmtadd() #删除新配置文件scdCfg.xml中全局站配置中remoteAddr的属性值相同的节点
{
    if [ ${tOldCfgFlag} -eq 1 ];then
        return 0
    fi

    local inNum=1
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    local edFile="$1"
    if [ ! -e "${edFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] not exist!\n"
        return 3
    fi
    if [[ -z "${stCfgNum}" || ${stCfgNum} -lt 1 ]];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] global station stCfgNum=[${stCfgNum}] !\n"
        return 3
    fi

    local edTmpLNo=${stCfgBL[0]}
    local tOneStTab="stationCfg"
    local tGStTab="stations"

    local tGstEndFlag=0
    local tOneStEdFlag=0
    local tNeedDoFlag=0
    local tmpStr
    local tmpVal
    local outStr
    local doOnceFlag=0

    local dlNexLNo=0

    local tmpCalArry[0]
    local tmpCalArry[1]
    local idx=1
    local t=0
    local total=0
    local noUniqTotal=0
    local tlnum=0
    local tlnumNoU=0
    local i
    for i in $(sed -n '/^\s*<\s*stations\b/,/^\s*<\s*\/\s*stations\b/{/^\s*<\s*[\/]*\s*stationSon\b/=;/^\s*<\s*\/\s*stations\b/q}' ${edFile})
    do
        t=$(echo "(${idx}+1)%2"|bc)
        tmpCalArry[${t}]=$i
        if [ ${t} -eq 1 ];then
            #echo "tmpCalArry[0]=${tmpCalArry[0]},tmpCalArry[1]=${tmpCalArry[1]}"
            tlnum=$(sed -n "${tmpCalArry[0]},${tmpCalArry[1]}{/\s*<\s*pntAddr\b/p;${tmpCalArry[1]}q}" ${edFile}|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/remoteAddr/){print $(i+1)}}}'|sort -n|uniq|wc -l)
            tlnumNoU=$(sed -n "${tmpCalArry[0]},${tmpCalArry[1]}{/\s*<\s*pntAddr\b/p;${tmpCalArry[1]}q}" ${edFile}|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/remoteAddr/){print $(i+1)}}}'|wc -l)
            let total+=${tlnum}
            let noUniqTotal+=${tlnumNoU}
            #echo -e "\ntotal=[${total}]"
        fi
        let idx++
    done 


    if [ ${total} -ne ${noUniqTotal} ];then
        #echo -e "\n--------edTmpLNo=[${edTmpLNo}]-----\n"
        i=1
        
        while [ ${tGstEndFlag} -eq 0 ]
        do
            let edTmpLNo++
            tmpStr=$(sed -n "${edTmpLNo} {p;q}" ${edFile}|sed -e 's///g' -e 's/^\s\+//g')

            tNeedDoFlag=$(echo "${tmpStr}"|sed -n "/^\s*<\s*pntAddr\b/p"|wc -l)
            if [ ${tNeedDoFlag} -gt 0 ];then
                tmpVal=$(F_prtfindKeyVal "remoteAddr" "${tmpStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')

                #echo "--------edTmpLNo=[${edTmpLNo}],remoteAddr=[${tmpVal}]-----"
                printf "\r\t--------edTmpLNo=[%d],remoteAddr=[%d]---doing lines: [ %d/%d ]-----" ${edTmpLNo} ${tmpVal} ${i} ${total}

                dlNexLNo=${edTmpLNo}
                let dlNexLNo++
                outStr=$(sed -n "${dlNexLNo},/^\s*<\s*\/\s*${tOneStTab}\b/ {/\bremoteAddr\s*=\s*\"\s*${tmpVal}\s*\"/ p}" ${edFile})
                if [ ! -z "${outStr}" ];then
                    doOnceFlag=1
                    echo -e "\n will delete [\n${outStr}\n]\n"
                fi
                sed -i "${dlNexLNo},/^\s*<\s*\/\s*${tOneStTab}\b/ {/\bremoteAddr\s*=\s*\"\s*${tmpVal}\s*\"/ d}" ${edFile}

                let i++
            fi
            tGstEndFlag=$(echo "${tmpStr}"|sed -n "/^\s*<\s*\/\s*${tGStTab}\b/p"|wc -l)
        done
    fi

    if [ ${doOnceFlag} -eq 0 ];then
        echo -e "\n\t\e[1;31MTIPS\e[0m:Threr are no dumplicate pntAddr nodes to delete! \n"
    fi

    return 0

}

function F_mdGDidVal() 
{
    if [ ${tOldCfgFlag} -eq 1 ];then
        return 0
    fi

    local inNum=2
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    local csvFile="$1"
    local edFile="$2"
    if [ ! -e "${csvFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${csvFile}] not exist!\n"
        return 2
    fi
    if [ ! -e "${edFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] not exist!\n"
        return 3
    fi

    echo -e "\n\t\e[1;31mTIPS:\e[0m csv file=[${csvFile}];cfg file=[${edFile}]\n"

    #sed -n "${tchBg},${tchEd}{/^\s*<\s*dataId\b/=}" ${edFile} >${tmchphyFile}
    #sed -n '/\s*<\s*didInfo\s*>/,/\s*<\s*\/\s*didInfo\s*>/ {/\s*<\s*dataId\b/=}' ${edFile}>${tmGdidFile}
    local tNum=0
    local tSria
    local tVal
    local tStr

    tStr=$(sed -n '/\s*<\s*didInfo\s*>/=' ${edFile})
    tNum=$(echo "${tStr}"|wc -l)
    if [ ${tNum} -ne 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] <didInfo> nots error!\n"
        return 3
    fi
    local tGdBL=${tStr}
    tStr=$(sed -n '/\s*<\s*\/\s*didInfo\s*>/=' ${edFile})
    tNum=$(echo "${tStr}"|wc -l)
    if [ ${tNum} -ne 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] </didInfo> nots error!\n"
        return 3
    fi
    local tGdEL=${tStr}

    tNum=$(wc -l ${csvFile}|awk '{print $1}')
    if [ ${tNum} -lt 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${csvFile}] line number less than 1!\n"
        return 3
    fi


    local tGSria
    local tchDStr
    local tGVal

    local tGdline=0
    local tCsvDval
    local tCsvDname

    local changeNum=0
    local todoBg=1
    local todoEd=$(sed -n '$=' ${csvFile})
    echo -e "\n\tline[${LINENO}]:\e[1;31m[notes]:\e[0m to do line [\e[1;31m${todoBg}\e[0m] to line [\e[1;31m${todoEd}\e[0m]\n"
    local tmpLinIdx=0
    while read tnaa
    do
        let tmpLinIdx++
        echo -n "[${tmpLinIdx}]"

        tnaa=$(echo "${tnaa}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g' -e 's///g')

        tNum=$(echo "${tnaa}"|awk -F'"' '{print NF}')
        if [ ${tNum} -ne 5 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${csvFile}] line [${tmpLinIdx}] content not need format!\n"
            continue
        fi
        tCsvDname=$(echo "${tnaa}"|awk -F'"' '{print $2}'|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        tCsvDval=$(echo "${tnaa}"|awk -F'"' '{print $4}'|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        tGdline=$(sed -n "${tGdBL},${tGdEL} {/\bdidName\s*=\"\s*\b${tCsvDname}\b\s*\"/=;${tGdEL}q}"  ${edFile})
        if [ -z "${tGdline}" ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] didName=[${tCsvDname}] not find in global didInfo!\n"
            continue
        fi
        tNum=$(echo "${tGdline}"|wc -l)
        if [ ${tNum} -gt 1 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] didName=[${tCsvDname}]  not quniq in global didInfo!\n"
            continue
        fi

        tStr=$(sed -n "${tGdline} {p;q}"  ${edFile}|sed -e 's///g' -e 's/^\s\+//g')

        #tchDStr=$(sed -n "${tnaa} {p;q}" ${edFile})
        #tSria=$(F_prtfindKeyVal "serialNo" "${tchDStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        tGVal=$(F_prtfindKeyVal "didVal" "${tStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        if [ -z "${tGVal}" ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] line[${tGdline}] didName=[${tCsvDname}]didVal is null!\n"
            continue
        fi

        if [ "${tGVal}" == "${tCsvDval}" ];then
            continue
        fi

        tchDStr="${tStr}"
        echo -e "\nfile:[${edFile}]  line:[${tGdline}] content:[${tchDStr}] ,modify [\e[1;31mdidVal\e[0m]'s value [\e[1;31m${tGVal}\e[0m] to [\e[1;31m${tCsvDval}\e[0m]  "

        sed -i "${tGdline} s/\bdidVal\b\s*=\s*\"[^\"]*\"/didVal=\"${tCsvDval}\"/g" ${edFile}

        let changeNum++
       
    done<${csvFile}

    if [ ${changeNum} -eq 0 ];then
        echo -e "\n\t\e[1;31mTIPS:\e[0m no need to modify\n"
    else
        echo -e "\n\t\e[1;31mTIPS:\e[0m a total of \e[1;31m${changeNum}\e[0m rows of data have been modifyed\n"
    fi

    return 0

}

function F_mdChnDidVal() #根据通道中的did名称 serialNo的值查找全局did对应serialNo值的didVal 然后把当前通道中didVal不相符合的值修改正确
{
    if [ ${tOldCfgFlag} -eq 1 ];then
        return 0
    fi

    local inNum=1
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    if [ ${chNum} -lt 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chNum=[${chNum}] cannot be less than 1!\n"
        return 2
    fi
    local edFile="$1"
    if [ ! -e "${edFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] not exist!\n"
        return 3
    fi

    local tchIdx=${chNum}
    let tchIdx--
    local tchBg="${chBL[0]}"
    local tchEd="${chEL[${tchIdx}]}"

    sed -n "${tchBg},${tchEd}{/^\s*<\s*dataId\b/=;${tchEd}q}" ${edFile} >${tmchphyFile}
    #sed -n '/\s*<\s*didInfo\s*>/,/\s*<\s*\/\s*didInfo\s*>/ {/\s*<\s*dataId\b/=}' ${edFile}>${tmGdidFile}
    local tNum=0
    local tSria
    local tVal
    local tStr

    tStr=$(sed -n '/\s*<\s*didInfo\s*>/=' ${edFile})
    tNum=$(echo "${tStr}"|wc -l)
    if [ ${tNum} -ne 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] <didInfo> nots error!\n"
        return 3
    fi
    local tGdBL=${tStr}
    tStr=$(sed -n '/\s*<\s*\/\s*didInfo\s*>/=' ${edFile})
    tNum=$(echo "${tStr}"|wc -l)
    if [ ${tNum} -ne 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] </didInfo> nots error!\n"
        return 3
    fi
    local tGdEL=${tStr}

    local tGSria
    local tchDStr
    local tGVal

    local changeNum=0
    local todoBg=$(head -1 ${tmchphyFile})
    local todoEd=$(tail -1 ${tmchphyFile})
    echo -e "\n\t\e[1;31m[notes]:\e[0m to do line [\e[1;31m${todoBg}\e[0m] to line [\e[1;31m${todoEd}\e[0m]\n"
    while read tnaa
    do
        #echo -n "[${tnaa}]"
        printf "\r\t--------doing lines: [ %d/%d ]" ${tnaa} ${todoEd}
        tchDStr=$(sed -n "${tnaa} {p;q}" ${edFile})
        tSria=$(F_prtfindKeyVal "serialNo" "${tchDStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        tVal=$(F_prtfindKeyVal "didVal" "${tchDStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        if [ -z "${tVal}" ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] line [${tnaa}] didVal is null!\n"
            continue
        fi
        #echo "tSria=[${tSria}],tVal=[${tVal}]"
        tStr=$(sed -n "${tGdBL},${tGdEL} {/\bserialNo\s*=\"\s*\b${tSria}\b\s*\"/p;${tGdEL}q}"  ${edFile})
        if [ -z "${tStr}" ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] line [${tnaa}] serialNo=[${tVal}] not find in global didInfo!\n"
            continue
        fi
        tNum=$(echo "${tStr}"|wc -l)
        if [ ${tNum} -gt 1 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] line [${tnaa}] serialNo=[${tVal}] not quniq in global didInfo!\n"
            continue
        fi
        tGVal=$(F_prtfindKeyVal "didVal" "${tStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')

        if [ "${tGVal}" == "${tVal}" ];then
            continue
        fi

        tchDStr=$(echo "${tchDStr}"|sed -e 's///g' -e 's/^\s\+//g')
        echo -e "\nfile:[${edFile}]  line:[${tnaa}] content:[${tchDStr}] ,modify [\e[1;31mdidVal\e[0m]'s value [\e[1;31m${tVal}\e[0m] to [\e[1;31m${tGVal}\e[0m]  "

        sed -i "${tnaa} s/\bdidVal\b\s*=\s*\"[^\"]*\"/didVal=\"${tGVal}\"/g" ${edFile}

        let changeNum++
       
    done<${tmchphyFile}

    if [ ${changeNum} -eq 0 ];then
        echo -e "\n\t\e[1;31mTIPS:\e[0m no need to modify\n"
    else
        echo -e "\n\t\e[1;31mTIPS:\e[0m a total of \e[1;31m${changeNum}\e[0m rows of data have been modifyed\n"
    fi

    return 0

}

function F_mdChlDidVSBynNme() #根据通道中的did名称 didName 查找全局did中对应值的 serialNo及didVal 然后把当前通道中此名称不相符合的两个值修改正确
{
    if [ ${tOldCfgFlag} -eq 1 ];then
        return 0
    fi

    local inNum=1
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    if [ ${chNum} -lt 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chNum=[${chNum}] cannot be less than 1!\n"
        return 2
    fi
    local edFile="$1"
    if [ ! -e "${edFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] not exist!\n"
        return 3
    fi

    local tcharset=$(file --mime-encoding ${edFile} |awk  '{print $2}')
    tcharset="${tcharset%%-*}" 
    if [ "${tcharset}" != "utf" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] encoding not utf-8!\n"
        exit 1
    fi


    local tchIdx=${chNum}
    let tchIdx--
    local tchBg="${chBL[0]}"
    local tchEd="${chEL[${tchIdx}]}"

    sed -n "${tchBg},${tchEd}{/^\s*<\s*dataId\b/=;${tchEd}q}" ${edFile} >${tmchphyFile}
    #sed -n '/\s*<\s*didInfo\s*>/,/\s*<\s*\/\s*didInfo\s*>/ {/\s*<\s*dataId\b/=}' ${edFile}>${tmGdidFile}
    local tNum=0
    local tSria
    local tVal
    local tdidName
    local tStr

    tStr=$(sed -n '/\s*<\s*didInfo\s*>/=' ${edFile})
    tNum=$(echo "${tStr}"|wc -l)
    if [ ${tNum} -ne 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] <didInfo> nots error!\n"
        return 3
    fi
    local tGdBL=${tStr}
    tStr=$(sed -n '/\s*<\s*\/\s*didInfo\s*>/=' ${edFile})
    tNum=$(echo "${tStr}"|wc -l)
    if [ ${tNum} -ne 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] </didInfo> nots error!\n"
        return 3
    fi
    local tGdEL=${tStr}

    local tGSria
    local tchDStr
    local tGVal
    local tGDidName

    local changeNum=0
    local todoBg=$(head -1 ${tmchphyFile})
    local todoEd=$(tail -1 ${tmchphyFile})
    echo -e "\n\t\e[1;31m[notes]:\e[0m to do line [\e[1;31m${todoBg}\e[0m] to line [\e[1;31m${todoEd}\e[0m]\n"
    while read tnaa
    do
        #echo -n "[${tnaa}]"
        printf "\r\t--------doing lines: [ %d/%d ]" ${tnaa} ${todoEd}

        tchDStr=$(sed -n "${tnaa} {p;q}" ${edFile})
        tSria=$(F_prtfindKeyVal "serialNo" "${tchDStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        tVal=$(F_prtfindKeyVal "didVal" "${tchDStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        tdidName=$(F_prtfindKeyVal "didName" "${tchDStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        if [ -z "${tdidName}" ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] line [${tnaa}] didName is null!\n"
            continue
        fi
        #echo "tSria=[${tSria}],tVal=[${tVal}]"
        tStr=$(sed -n "${tGdBL},${tGdEL} {/\bdidName\s*=\"\s*\b${tdidName}\b\s*\"/p;${tGdEL}q}"  ${edFile})
        if [ -z "${tStr}" ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] line [${tnaa}] didName=[${tdidName}] not find in global didInfo!\n"
            continue
        fi
        tNum=$(echo "${tStr}"|wc -l)
        if [ ${tNum} -gt 1 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] line [${tnaa}] didName=[${tdidName}] not quniq in global didInfo!\n"
            continue
        fi

        tGSria=$(F_prtfindKeyVal "serialNo" "${tStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        tGVal=$(F_prtfindKeyVal "didVal" "${tStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')

        if [[ "${tGSria}" == "${tSria}" && "${tGVal}" == "${tVal}" ]];then
            continue
        fi

        tchDStr=$(echo "${tchDStr}"|sed -e 's///g' -e 's/^\s\+//g')
        if [ "${tGVal}" != "${tVal}" ];then
            echo -e "\nfile:[${edFile}]  line:[${tnaa}] content:[${tchDStr}] ,modify [\e[1;31mdidVal\e[0m]'s value [\e[1;31m${tVal}\e[0m] to [\e[1;31m${tGVal}\e[0m]  "
            sed -i "${tnaa} s/\bdidVal\b\s*=\s*\"[^\"]*\"/didVal=\"${tGVal}\"/g" ${edFile}
        fi
        if [ "${tGSria}" != "${tSria}" ];then
            echo -e "\nfile:[${edFile}]  line:[${tnaa}] content:[${tchDStr}] ,modify [\e[1;31mserialNo\e[0m]'s value [\e[1;31m${tSria}\e[0m] to [\e[1;31m${tGSria}\e[0m]  "
            sed -i "${tnaa} s/\bserialNo\b\s*=\s*\"[^\"]*\"/serialNo=\"${tGSria}\"/g" ${edFile}
        fi

        let changeNum++
       
    done<${tmchphyFile}

    if [ ${changeNum} -eq 0 ];then
        echo -e "\n\t\e[1;31mTIPS:\e[0m no need to modify\n"
    else
        echo -e "\n\t\e[1;31mTIPS:\e[0m a total of \e[1;31m${changeNum}\e[0m rows of data have been modifyed\n"
    fi

    return 0

}

function F_mdChnDidSeri() #根据通道中did的didVal在全局did中查找对应的serialNo并与此相比较，不相同则将通道中的serialNo修改成与全局一致 
{
    if [ ${tOldCfgFlag} -eq 1 ];then
        return 0
    fi

    local inNum=1
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    if [ ${chNum} -lt 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} chNum=[${chNum}] cannot be less than 1!\n"
        return 2
    fi
    local edFile="$1"
    if [ ! -e "${edFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] not exist!\n"
        return 3
    fi

    local tchIdx=${chNum}
    let tchIdx--
    local tchBg="${chBL[0]}"
    local tchEd="${chEL[${tchIdx}]}"

    sed -n "${tchBg},${tchEd}{/^\s*<\s*dataId\b/=;${tchEd}q}" ${edFile} >${tmchphyFile}
    #sed -n '/\s*<\s*didInfo\s*>/,/\s*<\s*\/\s*didInfo\s*>/ {/\s*<\s*dataId\b/=}' ${edFile}>${tmGdidFile}
    local tNum=0
    local tSria
    local tVal
    local tStr

    tStr=$(sed -n '/\s*<\s*didInfo\s*>/=' ${edFile})
    tNum=$(echo "${tStr}"|wc -l)
    if [ ${tNum} -ne 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] <didInfo> nots error!\n"
        return 3
    fi
    local tGdBL=${tStr}
    tStr=$(sed -n '/\s*<\s*\/\s*didInfo\s*>/=' ${edFile})
    tNum=$(echo "${tStr}"|wc -l)
    if [ ${tNum} -ne 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} file [${edFile}] </didInfo> nots error!\n"
        return 3
    fi
    local tGdEL=${tStr}

    local tGSria
    local tchDStr

    local changeNum=0
    local todoBg=$(head -1 ${tmchphyFile})
    local todoEd=$(tail -1 ${tmchphyFile})
    echo -e "\n\t\e[1;31m[notes]:\e[0m to do line [\e[1;31m${todoBg}\e[0m] to line [\e[1;31m${todoEd}\e[0m]\n"
    while read tnaa
    do
        #echo -n "[${tnaa}]"
        printf "\r\t--------doing lines: [ %d/%d ]" ${tnaa} ${todoEd}
        tchDStr=$(sed -n "${tnaa} {p;q}" ${edFile})
        tSria=$(F_prtfindKeyVal "serialNo" "${tchDStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        tVal=$(F_prtfindKeyVal "didVal" "${tchDStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')
        if [ -z "${tVal}" ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] line [${tnaa}] didVal is null!\n"
            continue
        fi
        #echo "tSria=[${tSria}],tVal=[${tVal}]"
        tStr=$(sed -n "${tGdBL},${tGdEL} {/\"\s*\b${tVal}\b\s*\"/p;${tGdEL}q}"  ${edFile})
        if [ -z "${tStr}" ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] line [${tnaa}] val=[${tVal}] not find in global didInfo!\n"
            continue
        fi
        tNum=$(echo "${tStr}"|wc -l)
        if [ ${tNum} -gt 1 ];then
            echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in file [${edFile}] line [${tnaa}] val=[${tVal}] not quniq in global didInfo!\n"
            continue
        fi
        tGSria=$(F_prtfindKeyVal "serialNo" "${tStr}"|sed -e 's/^\s\+//g'  -e  's/\s\+$//g')

        if [ "${tGSria}" == "${tSria}" ];then
            continue
        fi

        tchDStr=$(echo "${tchDStr}"|sed -e 's///g' -e 's/^\s\+//g')
        echo -e "\nfile:[${edFile}]  line:[${tnaa}] content:[${tchDStr}] ,modify [\e[1;31mserialNo\e[0m]'s value [\e[1;31m${tSria}\e[0m] to [\e[1;31m${tGSria}\e[0m]  "

        sed -i "${tnaa} s/\bserialNo\b\s*=\s*\"[^\"]*\"/serialNo=\"${tGSria}\"/g" ${edFile}

        let changeNum++
       
    done<${tmchphyFile}

    if [ ${changeNum} -eq 0 ];then
        echo -e "\n\t\e[1;31mTIPS:\e[0m no need to modify\n"
    else
        echo -e "\n\t\e[1;31mTIPS:\e[0m a total of \e[1;31m${changeNum}\e[0m rows of data have been modifyed\n"
    fi

    return 0

}









#set
if [ "${opFlag}" == "${opSet}" ];then
    doChnNums=${#doChnNo[*]}
    for ((i=0;i<${doChnNums};i++))
    do
       F_setOneChnAbtIP "${doChnNo[$i]}" 
    done
    F_setDataCtIP
fi

#print
if [[ "${opFlag}" == "${opPrt}" || "${opFlag}" == "${opChCal}" || "${opFlag}" == "${opLin}" ]];then

    if [ "${opFlag}" == "${opPrt}" ];then
        ##print DataCener
        echo -e "---------------------------------------------\e[1;31mprint Data Center\e[0m----"
        F_prtDataCtIp "${daInIpBL}" "${daOutIpBL}" "${edFile}"


        if [ ${tOldCfgFlag} -eq 0 ];then
            ##print stationCfg
            echo -e "---------------------------------------------\e[1;31mprint stationCfg\e[0m--begine-->"
            for ((i=0;i<${stCfgNum};i++))
            do
                F_prtOneStCfg "${stCfgBL[$i]}" "${stCfgEL[$i]}" "${stCfgLclBL[$i]}" "${stCfgLclEL[$i]}" "${stCfgLclNL[$i]}" "${stCfgRmtBL[$i]}" "${stCfgRmtEL[$i]}" "${stCfgRmtNL[$i]}" "${edFile}" 

            done
            echo -e "<---------------------------------------------print stationCfg--end-----\n"
        fi
    fi

    ##print channels
    echo -e "-----------------------------------------------\e[1;31mprint channels\e[0m--begine-->"
    for ((i=0;i<${chNum};i++))
    do
        #echo "chBL[$i]=${chBL[$i]},chEL[$i]=${chEL[$i]}"
        #echo "stnNoL[$i]=${stnNoL[$i]} lclStnBL[$i]=${lclStnBL[$i]} lclStnEL[$i]=${lclStnEL[$i]} lclNetL[$i]=${lclNetL[$i]}"
        F_prtOneChnl  "${chBL[$i]}" "${chEL[$i]}" "${stnNoL[$i]}" "${lclStnBL[$i]}" "${lclStnEL[$i]}" "${lclNetL[$i]}" "${rmtStnBL[$i]}" "${rmtStnEL[$i]}" "${rmtNetL[$i]}"  "${prtlBL[$i]}" "${edFile}"
        #echo -e "\n"
    done
    echo -e "<-------------------------------------------------print channels--end--\n"

fi

#gen
if [ "${opFlag}" == "${opGen}" ];then

    ##gen DataCener
    F_prtDataCtIp "${daInIpBL}" "${daOutIpBL}" "${edFile}"


    ##gen channels
    for ((i=0;i<${chNum};i++))
    do
        echo  ""
        F_prtOneChnl  "${chBL[$i]}" "${chEL[$i]}" "${stnNoL[$i]}" "${lclStnBL[$i]}" "${lclStnEL[$i]}" "${lclNetL[$i]}" "${rmtStnBL[$i]}" "${rmtStnEL[$i]}" "${rmtNetL[$i]}"  "${prtlBL[$i]}" "${edFile}" "$i"
        echo  ""
    done

fi

#md
if [[ "${opFlag}" == "${opMd}" ]];then
    #echo "null null"
    if [ ${tOldCfgFlag} -eq 0 ];then
        F_mdChnDidSeri "${edFile}"
    else
        echo -e "\n\t null null \n"
    fi

fi

#md
if [[ "${opFlag}" == "${opMdV}" ]];then
    #echo "null null"
    if [ ${tOldCfgFlag} -eq 0 ];then
        F_mdChnDidVal "${edFile}"
    else
        echo -e "\n\t null null \n"
    fi

fi

if [[ "${opFlag}" == "${opMdVSByN}" ]];then
    #echo "null null"
    if [ ${tOldCfgFlag} -eq 0 ];then
        F_mdChlDidVSBynNme  "${edFile}"
    else
        echo -e "\n\t null null \n"
    fi

fi

if [[ "${opFlag}" == "${opMdGV}" ]];then
    #echo "null null"
    if [ ${tOldCfgFlag} -eq 0 ];then
        F_mdGDidVal "${tCsvSrcUtf}" "${edFile}"
    else
        echo -e "\n\t null null \n"
    fi

fi

if [[ "${opFlag}" == "${opMdSsn}" ]];then
    #echo "null null"
    if [ ${tOldCfgFlag} -eq 0 ];then
        echo -e "\n\t in edFile[ ${edFile} ] \e[1;31mtotal chnNum=[${chNum}]\e[0m \n"
        for ((i=0;i<${chNum};i++))
        do
            echo -e "\n-----check chn \e[1;31midx =[${i}]\e[0m"
            F_mdOneChlSome  "${chBL[$i]}" "${chEL[$i]}" "${stnNoL[$i]}" "${lclStnBL[$i]}" "${lclStnEL[$i]}" "${lclNetL[$i]}" "${rmtStnBL[$i]}" "${rmtStnEL[$i]}" "${rmtNetL[$i]}"  "${prtlBL[$i]}" "${edFile}"
            echo -e "-----check chn \e[1;31midx =[${i}] complete \e[0m\n"
        done
    else
        echo -e "\n\t null null \n"
    fi

fi

if [[ "${opFlag}" == "${opDlGadd}" ]];then
    #echo "null null"
    if [ ${tOldCfgFlag} -eq 0 ];then
        F_delGStDumpRmtadd  "${edFile}"
    else
        echo -e "\n\t null null \n"
    fi
fi

if [[ "${opFlag}" == "${opMAddr}" ]];then
    #echo "null null"
    echo "F_addPntAdNdAttrVal  ${edFile} ${tInStaNo} ${tInAttrName} ${tInAddVal} \"${inRange}\" \"${inRefKeyVal}\""
    if [ ${tOldCfgFlag} -eq 0 ];then
        F_addPntAdNdAttrVal  "${edFile}" "${tInStaNo}" "${tInAttrName}" "${tInAddVal}" "${inRange}" "${inRefKeyVal}"
    else
        echo -e "\n\t null null \n"
    fi
fi

if [[ "${opFlag}" == "${opMRefAddr}" ]];then
    #echo "null null"
    echo "F_mdAdvalRefOside  ${edFile} ${tInStaNo} ${tInAttrName} ${tInAddVal}"
    if [ ${tOldCfgFlag} -eq 0 ];then
        F_mdAdvalRefOside  "${edFile}" "${tInStaNo}" "${tInAttrName}" "${tInAddVal}"
    else
        echo -e "\n\t null null \n"
    fi
fi

if [[ "${opFlag}" == "${opSorPhy}" ]];then
    F_setChnPhyOrderVal "${edFile}" "${inChnNo}" "${phyBgVal}" "1"
fi


exit 0


