#!/bin/bash
#
################################################################################
#
# author : fu.sky
# date   : 2021-01-13
# desc   :
#        根据现场实际的业务清单文件(有预测与有气象)和要替换的气象数据文件，
#        生成新的业务清单文件
#
# Precondition:
#        1. 从现场下载实际的业务清单文件a(有可能多个)
#        2. 找到要替换的气象数据文件b(一般文件名需要有场站名，日期等要素)
#        3. 在文件b的同级目录下建立子目录result
#        4. 将业务清单a和本脚本放在result下
#        5. 简单修改此脚本（主要是修改业务清单文件名的时间与气象文件名时间的对应,
#           和新业务清单中气象数据中风场名需要替换成为的名)
#        6. 运行此脚本生成新的业务清单
#        7. 将新业务清单发给需要的人员
# use eg:
#       ./$0
#
################################################################################
#


fcName="Lingchuan_2qi_2"  #实际的气象文件名和气象数据中的 风场名（此脚本默认
                          #是一样的，如果不一样还需要简单修改一下此脚本)

newfcName="zhuanghe"      #业务清单中需要替换成为的风场名（一般为了测试需要替换)

#tFile=busilist_20210106_0.xmlbak

function F_calYesterdayByStr()
{
    if [ $# -lt 1  ];then
        echo -e "ERROR:${FUNCNAME}:${LINENO}:input parameters less 1\n"
        return 1
    fi

    local inStr="$1"

    local Hscs8=$(echo "60*60*8"|bc)
    local Hscs24=$(echo "60*60*24"|bc)

    local fstYscs=$(date -d "${inStr}" +%s)

    local yesScs=$(echo "${fstYscs} + ${Hscs8} - ${Hscs24}"|bc)

    local retStr
    retStr=$(date -d "1970-01-01 ${yesScs} sec" +%Y%m%d)

    echo "${retStr}"

    return 0
}

function F_doOneFile()
{
    if [ $# -lt 2 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameters less 2\n"
        return 1
    fi

    local  tFile="$1"
    local  fcName="$2" #Lingchuan_2qi_2
    local  fData1;local fData2
    local qxFile

    #local qxDate2
    #fData1="${tFile:9:6}"  #202101
    #fData2="${tFile:15:2}" #06
    #qxDate2=$(echo "${fData2} -1"|bc)
    #[ ${#qxDate2} -eq 1 ] && qxDate2="0${qxDate2}"
    #qxFile=$(ls -1 ../${fcName}_${fData1}${qxDate2}*.txt)

    local fsrcDate; local ystDate
    fsrcDate="${tFile:9:8}"                       #20210106
    ystDate=$(F_calYesterdayByStr "${fsrcDate}")  #20210105
    qxFile=$(ls -1 ../${fcName}_${ystDate}*.txt)



    echo "${FUNCNAME}:qxFile=[${qxFile}],tFile=[${tFile}]" 

    if [ ! -f "${qxFile}" ];then
        echo -e "\n\tERROR:${FUNCNAME}: file[${qxFile}] not exist!\n"
        return 2
    fi

    if [ ! -f "${tFile}" ];then
        echo -e "\n\tERROR:${FUNCNAME}: file[${tFile}] not exist!\n"
        return 2
    fi

    local i=1
    local lNo; local tbgNo=""; local tedNo="";

    for lNo in $(sed -n '/^\s*<[/]*jobData>/=' ${tFile})
    do
        [ $i -eq 1 ] && tbgNo=$lNo
        [ $i -eq 2 ] && tedNo=$lNo
        #echo $lNo
        let  i++
    done

    #echo "tbgNo=[${tbgNo}],tedNo=[${tedNo}]"

    if [[ -z "${tbgNo}" || -z "${tedNo}" ]];then
        echo -e "\n\tERROR:${FUNCNAME}: file[${tFile}] not have right jobData nodes!\n"
        return 2
    fi

    local bgNo; local edNo
    bgNo=$(echo "${tbgNo} + 1"|bc )
    edNo=$(echo "${tedNo} - 1 "|bc)
    #echo "bgNo=[${bgNo}],edNo=[${edNo}]"

    sed -i "${bgNo},${edNo} d" "${tFile}"
    sed -i "${tbgNo}{s/>.*$/>/g}" "${tFile}"
    sed -i "${tbgNo} r ${qxFile}" "${tFile}"

    sed  -i  's/\xEF\xBB\xBF//g' "${tFile}"
    sed -i 's///g' "${tFile}"
    sed -i '/^\s*<\s*jobData\s*>\s*/{N;s/<\s*jobData\s*>\s*\n\s*/<jobData>/g}' "${tFile}"
    sed -i "s/${fcName}/${newfcName}/g" "${tFile}"


    return 0
}

#F_doOneFile "${tFile}" "Lingchuan_2qi_2"

ls -1 busi*.xml|while read tnaa
do
    echo "doing  file =[${tnaa}]"
    F_doOneFile "${tnaa}" "${fcName}"
done


exit 0
