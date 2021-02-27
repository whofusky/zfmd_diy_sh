#!/bin/bash
#
################################################################################
#
#author:fu.sky
#
#date  :2020-12-25
#
#desc  : 合成业务清单（fczx 多次气象)
#
#      : 根据同脚本同级目录下的气象文件自动生成对就的业务清单文件存于 result目录
#
# Precondition :
#             1. 在脚本的同级目录需要有model文件夹，且有模板文件
#             2. 在脚本同级的目录下有气象文件文件名类似:Haixun1_2020121818.txt
# usage like:  
#            ./$0
#
#
################################################################################
#


#if [ $# -lt 1 ];then
#    echo -e "\n\t\e[1;31mERROR:\e[0m input should like:\n\t\t$0 <qx_file1> \n"
#    exit 1
#fi

rDir="result"
if [ ! -d "${rDir}" ];then
    mkdir -p ${rDir}
fi

mdafile="model/a.model"
mdbfile="model/b.model"

if [ ! -f "${mdafile}" ];then
    echo -e "\n\tERROR: file [${mdafile}] not exist!\n"
    exit 2
fi

if [ ! -f "${mdbfile}" ];then
    echo -e "\n\tERROR: file [${mdbfile}] not exist!\n"
    exit 2
fi

#根据某个气象文件名，生成对就的业务清单
function F_doOneMeteBusi()
{
    if [ $# -lt 1 ];then
        echo -e "\n\t\e[1;31mERROR:\e[0m ${FUNCNAME}: input parameters less 1!\n"
        return 1
    fi

    local oldFN="$1"              #Haixun1_2020121818.txt
    local fcName=${oldFN%%_*}     #Haixun1
    local tmpHz=${oldFN##*_}      #2020121818.txt
    local tmpDate=${tmpHz%%.*}    #2020121818
    local datePre1=${tmpDate:0:8} #20201218
    local datePre2=${tmpDate:8:2} #18
    local fwtTm="${tmpDate:0:4}/${tmpDate:4:2}/${tmpDate:6:2}_${tmpDate:8:2}:45:01"
    local file_hzNo=0
    if [ "${datePre2}" = "00" ];then
        file_hzNo=3
    elif [ "${datePre2}" = "06" ];then
        file_hzNo=4
    elif [ "${datePre2}" = "12" ];then
        file_hzNo=5
    elif [ "${datePre2}" = "18" ];then
        file_hzNo=6
    fi

    local resultDir="${rDir}/${fcName}"
    if [ ! -d "${resultDir}" ];then
        mkdir -p "${resultDir}"
    fi
    local rslFile="${resultDir}/busilist_${datePre1}_${file_hzNo}.xml"

    echo -e "------rslFile=[${rslFile}]--\n"

    #return 0

    cat ${mdafile} > "${rslFile}"
    cat ${oldFN} >> "${rslFile}"
    cat ${mdbfile} >> "${rslFile}"

    sed  -i  's/\xEF\xBB\xBF//g' "${rslFile}"
    sed -i 's///g' "${rslFile}"
    sed -i '/^\s*<\s*jobData\s*>\s*/{N;s/<\s*jobData\s*>\s*\n\s*/<jobData>/g}' "${rslFile}"
    sed -i "s/<dataID>[0-9]<\/dataID>/<dataID>${file_hzNo}<\/dataID>/g" "${rslFile}"
    sed -i "s/${fcName}/zhuanghe/g" "${rslFile}"
    sed -i "s=<\s*submitTime\s*>[^>]*<\s*/\s*submitTime\s*>=<submitTime>${fwtTm}</submitTime>=g" "${rslFile}"

    iconv -f utf8 -t gbk "${rslFile}"  -o  $$.txt
    mv $$.txt "${rslFile}" 

}

#判断当前目录是否有符合要求的气象文件名
num=$(ls -1 *_[0-9]*.txt 2>/dev/null|wc -l)
if [ $num -lt 1 ];then
    echo -e "\n\t\e[1;31mERROR:\e[0m in current dir not have files like :_[0-9]*.txt\n"
    exit 1
fi

#循环处理当前目录下的每个气象文件: order by  fcName, modify_time asc;
for fcname in $(ls -1 *_[0-9]*.txt 2>/dev/null |awk -F'_' '{print $1}'|sort|uniq)
do
    echo -e "fcname=[${fcname}]"
    ls -lrt ${fcname}_*|awk '{print $NF}'|while read tnaa
    do
        echo "tnaa=[${tnaa}]"
        F_doOneMeteBusi "${tnaa}"
    done
done

exit 0

#ls -lrt Lingchuan1_*|awk '{print $NF}'|while read tnaa
#do
#    echo "tnaa=[${tnaa}]"
#    F_doOneMeteBusi "${tnaa}"
#done

#exit 0

