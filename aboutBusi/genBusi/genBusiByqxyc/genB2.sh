#!/bin/bash
#
################################################################################
#
#author:fu.sky
#
#date  :2020-12-25
#
#desc  : 合成业务清单（只有一个气象文件和一个预测文件的情况)
#
#      : 根据输入的风场名，然后查找与脚本同目录下的"qxyc/风场名/" 下的气象和预测文件来合成业务清单
#
# Precondition :
#             1. 在脚本的同级目录需要有model文件夹，且"model/风场名"文件夹下有模板文件
#             2. 在脚本同级的目录下的"qxyc/风场名"目录下有气象和预测文件在在
# usage like:  
#            ./$0  "风场名"  [dataId]
#
#
################################################################################
#


if [ $# -lt 1 ];then
    echo -e "\n\t\e[1;31mERROR:\e[0m input should like:\n\t\t$0 <风场名>  [dataId]\n"
    exit 1
fi

fcName="$1"
dataId=0
[ $# -ge 2 ] && dataId="$2"

rDir="result/${fcName}"
if [ ! -d "${rDir}" ];then
    mkdir -p ${rDir}
fi

mdafile="model/${fcName}/a2.model"
mdbfile="model/${fcName}/b2.model"
mdcfile="model/${fcName}/c2.model"

dataDir="qxyc/${fcName}"

if [ ! -f "${mdafile}" ];then
    echo -e "\n\tERROR: file [${mdafile}] not exist!\n"
    exit 2
fi

if [ ! -f "${mdbfile}" ];then
    echo -e "\n\tERROR: file [${mdbfile}] not exist!\n"
    exit 2
fi

if [ ! -f "${mdcfile}" ];then
    echo -e "\n\tERROR: file [${mdcfile}] not exist!\n"
    exit 2
fi

if [ ! -d "${dataDir}" ];then
    echo -e "\n\tERROR: qx and yc file dir [${dataDir}] not exist!\n"
    exit 2
fi


#根据某个气象文件名和预测文件名，生成对应的业务清单
function F_doOneMeteBusi()
{
    if [ $# -lt 1 ];then
        echo -e "\n\t\e[1;31mERROR:\e[0m ${FUNCNAME}: input parameters less 1!\n"
        return 1
    fi

    local  fcName="$1"   #风场名
    local  tQxFile="$2"  #气象文件名
    local  tYcFile="$3"  #预测文件名

    local file_hzNo="$4" #dataID的值
    local datePre1=$(date +%Y%m%d) #20201218
    local fwtTm=$(date +%Y/%m/%d_%H:%M:%S)  #2021/01/11_06:29:56

    #local oldFN="$1"              #Haixun1_2020121818.txt
    #local fcName=${oldFN%%_*}     #Haixun1
    #local tmpHz=${oldFN##*_}      #2020121818.txt
    #local tmpDate=${tmpHz%%.*}    #2020121818
    #local datePre1=${tmpDate:0:8} #20201218
    #local datePre2=${tmpDate:8:2} #18
    #local fwtTm="${tmpDate:0:4}/${tmpDate:4:2}/${tmpDate:6:2}_${tmpDate:8:2}:45:01"
    #local file_hzNo=0
    #if [ "${datePre2}" = "00" ];then
    #    file_hzNo=3
    #elif [ "${datePre2}" = "06" ];then
    #    file_hzNo=4
    #elif [ "${datePre2}" = "12" ];then
    #    file_hzNo=5
    #elif [ "${datePre2}" = "18" ];then
    #    file_hzNo=6
    #fi

    local resultDir="${rDir}"
    if [ ! -d "${resultDir}" ];then
        mkdir -p "${resultDir}"
    fi
    local rslFile="${resultDir}/busilist_${datePre1}_${file_hzNo}.xml"

    echo -e "------rslFile=[${rslFile}]--\n"

    #return 0

    cat ${mdafile} > "${rslFile}"
    cat ${tQxFile} >> "${rslFile}"
    cat ${mdbfile} >> "${rslFile}"
    cat ${tYcFile} >> "${rslFile}"
    cat ${mdcfile} >> "${rslFile}"

    sed  -i  's/\xEF\xBB\xBF//g' "${rslFile}"
    sed -i 's///g' "${rslFile}"
    sed -i '/^\s*<\s*jobData\s*>\s*/{N;s/<\s*jobData\s*>\s*\n\s*/<jobData>/g}' "${rslFile}"
    sed -i "s/<dataID>[0-9]<\/dataID>/<dataID>${file_hzNo}<\/dataID>/g" "${rslFile}"
    sed -i "s=<\s*submitTime\s*>[^>]*<\s*/\s*submitTime\s*>=<submitTime>${fwtTm}</submitTime>=g" "${rslFile}"

    #sed -i "s/${fcName}/zhuanghe/g" "${rslFile}"

    iconv -f utf8 -t gbk "${rslFile}"  -o  $$.txt
    mv $$.txt "${rslFile}" 

}

#判断${dataDir}目录是否有符合要求的气象文件名
num=$(ls -1 ${dataDir}/qx*.txt 2>/dev/null|wc -l)
if [ $num -ne 1 ];then
    echo -e "\n\t\e[1;31mERROR:\e[0m in [${dataDir}] dir not have files like :_qx*.txt\n"
    exit 1
fi
qxfile=$(ls -1 ${dataDir}/qx*.txt 2>/dev/null)

#判断${dataDir}目录是否有符合要求的预测文件名
num=$(ls -1 ${dataDir}/yc*.txt 2>/dev/null|wc -l)
if [ $num -ne 1 ];then
    echo -e "\n\t\e[1;31mERROR:\e[0m in [${dataDir}] dir not have files like :_yc*.txt\n"
    exit 1
fi
ycfile=$(ls -1 ${dataDir}/yc*.txt 2>/dev/null)

#根据风场名 气象文件 预测文件 dataID 生成业务清单文件
echo -e "\n\t风场名  :[${fcName}]"
echo -e "\t气象文件:[${qxfile}]"
echo -e "\t预测文件:[${ycfile}]"
echo -e "\tDataID  :[${dataId}]\n"
F_doOneMeteBusi "${fcName}" "${qxfile}" "${ycfile}" "${dataId}"


exit 0

