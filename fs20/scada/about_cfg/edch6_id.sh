#!/bin/bash


#############################################################################
#author       :    fushikai
#date         :    20190410
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#   根据没找到文件noFindFile.txt中的数据id反查通道6中的对应id并对其进行修改
#
#
#
#
#############################################################################




baseDir=$(dirname $0)


#主需要处理的文件
sfile="${baseDir}/chn_6.xml"
noFindFile="${baseDir}/noFindFile.txt"


if [ ! -e ${sfile} ];then
    echo -e "\n\tError: file [ ${sfile} ] does not exist!\n"
    exit 1
fi

if [ ! -e ${noFindFile} ];then
    echo -e "\n\tError: file [ ${noFindFile} ] does not exist!\n"
    exit 2
fi


beginRunTime="script [ $0 ] starts running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"

while read tnaa
do

    edFlag=$(echo "${tnaa}"|grep -w "ENCODETYPE_TURBINE"|wc -l)
    if [ ${edFlag} -eq 0 ];then
        echo -e "\n ${tnaa} \n not need edit\n"
        continue
    fi
    findLineNo=$(grep -n "${tnaa}" ${sfile}|awk -F':' '{print $1}')
    sed -e "${findLineNo}s/funcType=.1./funcType=\"2\"/; ${findLineNo}s/htype=.HEIGHTTYPE_HUB.\s*hvalue=...\s* //"  -i ${sfile}

done<${noFindFile}

endRunTime="script [ $0 ] end running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"

echo -e "\n\t${beginRunTime}\n"
echo -e "\n\t${endRunTime}\n"



exit 0

