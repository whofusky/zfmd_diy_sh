#!/bin/bash
######################################################################
#
# author  : fu.sky
# date    : 2021-04-03
# Des     : 从脚本同目录下的业务清单文件（名类似busilist_20210402_0.xml）
#           的文件中取对应的整场数据到结果文件(名类似result_20210402_0_frm.txt)
# use     :
#         ./$0 <type> <域号>
#
#
######################################################################

baseDir=$(dirname $0)

thisShName="$0"
onlyShName=${thisShName##*/}
onlyShPre=${onlyShName%.*}
inParNum=$#

inType=$1
fieldNo=$2



resultDir="${baseDir}/result"
tmpDir="${baseDir}/tmp"
resultFile=""

function F_init()
{
   #v_HeadStr="2021-04-04_00:15:00"
    v_HeadStr=""
    v_HeadStr[0]="日期时刻"  ; v_HdStrLen[0]="-20" ; v_HdVal[0]=0;

    v_HeadStr[1]="风机容量"  ; v_HdStrLen[1]="-11" ; v_HdVal[1]=0;
    v_HeadStr[2]="平均风速"  ; v_HdStrLen[2]="-11" ; v_HdVal[2]=0;
    v_HeadStr[3]="平均功率"  ; v_HdStrLen[3]="-11" ; v_HdVal[3]=0;
    v_HeadStr[4]="最小功率"  ; v_HdStrLen[4]="-11" ; v_HdVal[4]=0;
    v_HeadStr[5]="最大功率"  ; v_HdStrLen[5]="-11" ; v_HdVal[5]=0;
    v_HeadStr[6]="发电量"    ; v_HdStrLen[6]="-11" ; v_HdVal[6]=0;
    v_HeadStr[7]="最小发电量"; v_HdStrLen[7]="-11" ; v_HdVal[7]=0;
    v_HeadStr[8]="最大发电量"; v_HdStrLen[8]="-11" ; v_HdVal[8]=0;

    return 0
}

function F_replaceCommaToSpace()
{
    [ $# -ne 1 ] && return 0
    local inP="$1"
    local rst=$(echo "${inP}"|sed 's/,/ /g')

    echo "${rst}"
    return 0
}

function F_judgeCharset()
{
    [ $# -ne 1 ] && return 1
    local tFile="$1"
    [ ! -f "${tFile}" ] && return 2
    local tcharset
    tcharset=$(file --mime-encoding ${tFile} |awk  '{print $2}')
    tcharset="${tcharset%%-*}" 
    echo "${tcharset}"

    return 0
}


function F_Tips()
{
    echo ""
    echo "  Please input like:"
    echo ""
    echo "    ${onlyShName} <type> <域号>  #从业务清单取整场数据"
    echo ""
    echo "        type: 0 结果文件用txt形式; 1结果文件用csv形式"
    echo ""
    echo "        域号: 0 取全部整场数据"
    echo ""
    echo "          非0值可以有多值，但用逗号分隔且值在如下小范围:"
    echo ""
    echo "              1 取整场的第1个域数据:${v_HeadStr[1]}"
    echo "              2 取整场的第2个域数据:${v_HeadStr[2]}"
    echo "              3 取整场的第3个域数据:${v_HeadStr[3]}"
    echo "              4 取整场的第4个域数据:${v_HeadStr[4]}"
    echo "              5 取整场的第5个域数据:${v_HeadStr[5]}"
    echo "              6 取整场的第6个域数据:${v_HeadStr[6]}"
    echo "              7 取整场的第7个域数据:${v_HeadStr[7]}"
    echo "              8 取整场的第8个域数据:${v_HeadStr[8]}"
    echo ""
    
    return 0
}

function F_check()
{
    if [ ${inParNum} -ne 2 ];then
        F_Tips
        exit 0
    fi

    if [[ "${inType}x" != "0x"  && "${inType}x" != "1x" ]];then
        F_Tips
        exit 1
    fi

    local tnum=0
    if [ "${fieldNo}x" != "0x" ];then
        local tmpStr=$(F_replaceCommaToSpace "${fieldNo}")
        local i
        for i in ${tmpStr}
        do
            tnum=$(echo "${i}"|sed -n '/^[1-8]$/p'|wc -l)
            if [ ${tnum} -eq 0 ];then
                F_Tips
                exit 1
            fi
        done
        fieldNo="${tmpStr}"
    else
        fieldNo=$(seq 1 8)
    fi

    tnum=$(ls -1 ${baseDir}/busilist*.xml 2>/dev/null|wc -l)
    
    if [ ${tnum} -eq 0 ];then
        echo -e "\n\t not have ${baseDir}/busilist*.xml files\n"
        exit 1
    fi

    [ ! -d "${resultDir}" ] && mkdir -p "${resultDir}"
    [ ! -d "${tmpDir}" ] && mkdir -p "${tmpDir}"

    return 0
}


function F_printTitle()
{
    local tLeng=0
    tLeng="-${#v_HeadStr[0]}"
    tLeng=$(echo "${tLeng} + ${v_HdStrLen[0]}"|bc)
    #printf "%${v_HdStrLen[0]}s " ${v_HeadStr[0]}
    printf "%${tLeng}s" ${v_HeadStr[0]}

    local i
    for i in ${fieldNo}
    do
        tLeng="-${#v_HeadStr[$i]}"
        tLeng=$(echo "${tLeng} + ${v_HdStrLen[$i]}"|bc)
        #printf "%${v_HdStrLen[$i]}s " ${v_HeadStr[$i]}
        printf "%${tLeng}s" ${v_HeadStr[$i]}
    done

    printf "\n"

    return 0
}

function F_printOneItem()
{
    printf "%${v_HdStrLen[0]}s" ${v_HdVal[0]}

    local i
    for i in ${fieldNo}
    do
        printf "%${v_HdStrLen[$i]}s" ${v_HdVal[$i]}
    done

    printf "\n"

    return 0
}

function F_doOneBusiFile()
{
    if [ $# -ne 1 ];then
        return 1
    fi
    local tInFile="$1"
    if [ ! -e "${tInFile}" ];then
        echo -e "\n\tERROR:${FUNCNAME}:file [${tInFile}] not exist!\n"
        return 2
    fi
    local tcharset
    tcharset=$(F_judgeCharset "${tInFile}")
    if [[ "${tcharset}x" != "isox" && "${tcharset}x" != "utfx" ]];then
        echo -e "\n\tERROR:${FUNCNAME}:file [${tInFile}] char set is \"${tcharset}\" not iso nor utf\n"
        return 3
    fi

    local onlyFName=${tInFile##*/}
    local tFPreName=${onlyFName%.*}

    local tsrcUtf="${tmpDir}/${tFPreName}_utf.txt"

    if [ "${tcharset}x" = "isox" ];then
        iconv -f gbk -t utf-8 ${tInFile} -o ${tsrcUtf}
    else
        cp "${tInFile}" "${tsrcUtf}"
    fi
    local tFDate=$(echo "${tFPreName}"|cut -b10- )

    local ttmpFile="${tmpDir}/tmp${tFDate}.txt"
    egrep "(^风电场|^[0-9]+)" ${tsrcUtf}|egrep -B1 "^风电场" >${ttmpFile}
    
    local tnum=0
    tnum=$(wc -l ${ttmpFile}|awk '{print $1}')
    if [ ${tnum} -eq 0 ];then
        echo -e "\n\tERROR:${FUNCNAME}:file [${tInFile}] not have farm data\n"
        return 4
    fi

    sed -i 'N;s/\(^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).*\n\s*风电场\(\s.*\)/\1 \2/g' ${ttmpFile}

    resultFile="${resultDir}/${tFDate}_frm.txt"
    resultFileCsv="${resultDir}/${tFDate}_frm.csv"
    [ -f "${resultFile}" ] && rm ${resultFile}
    [ -f "${resultFileCsv}" ] && rm ${resultFileCsv}

    >${resultFile}

    F_printTitle >>${resultFile}

    while read v_HdVal[0] v_HdVal[1] v_HdVal[2] v_HdVal[3] v_HdVal[4] v_HdVal[5] v_HdVal[6] v_HdVal[7] v_HdVal[8]
    do
        F_printOneItem >>${resultFile}
    done<${ttmpFile}

    if [[ "${inType}x" = "1x" ]];then
        sed -i 's/^\s*/"/g;s/\s*$/"/g;s/\s\+/","/g' "${resultFile}"
        mv "${resultFile}" "${resultFileCsv}"
        echo "----get farm date from [${tInFile}]---result file [ ${resultFileCsv} ]"
    else
        echo "----get farm date from [${tInFile}]---result file [ ${resultFile} ]"
    fi


    return 0
}

function F_doAllBusiFile()
{
    local tnum=0
    tnum=$(ls -1 ${baseDir}/busilist*.xml 2>/dev/null|wc -l)
    if [ ${tnum} -lt 1 ];then
        return 0
    fi

    local tnaa
    ls -1 ${baseDir}/busilist*.xml |while read tnaa
    do
        F_doOneBusiFile "${tnaa}"
    done

    return 0
}

function F_test()
{
    local a="日期时刻" 
    local b=202.023
    local t1="-20"
    local t2="10"
    #printf "[%${t1}s] [%${t2}s]\n", $a $b

    local tmpStr="a,b,1,2"
    local rst=$(F_replaceCommaToSpace "${tmpStr}")
    echo "0tmpStr=[${tmpStr}],rst=[${rst}]"
    F_printTitle


    return 0
}

main()
{
    F_init
    F_check
    F_doAllBusiFile
    #F_test

    return 0
}

main

exit 0
