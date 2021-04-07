#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20190808
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    统计/zfmd/wpfs20目录文件占用硬盘空间情况
#    
#revision history:
#       fushikai@20190813@modify bug@v0.0.0.2
#       fushikai@20190808@created@v0.0.0.1
#       
#
#############################################################################

#软件版本号
versionNo="software version number: v0.0.0.2"

#加载系统环境变量配置
if [ -f /etc/profile ]; then
    . /etc/profile >/dev/null 2>&1
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile >/dev/null 2>&1
fi

errorProm="--------\e[1;31mERROR\e[0m--------:Input errors,please re-enter!"
prompct1="
        ${versionNo}

        请输入如下数字，选择相应的操作：
                【1】统计[ /zfmd/wpfs20 ]下子目录及二级子目录硬盘占用情况
                【2】统计[ /zfmd/wpfs20 ]下子目录硬盘占用情况
                【3】统计[ /zfmd ]下子目录硬盘占用情况
                【4】统计[ /zfmd ]下子目录及二级子目录硬盘占用情况
                【5】退出，什么都不做
        你的选择是："

while ((1))
do
    read -n 1 -p "${prompct1}" opType
    if [[ -z "${opType}" ]];then
        echo -e "\n${errorProm}"
        continue
    elif [[ ${opType} -ne 1 && ${opType} -ne 2 && ${opType} -ne 3 && ${opType} -ne 4 && ${opType} -ne 5 ]];then
        echo -e "\n${errorProm}"
        continue
    fi
    break
done
[ ${opType} -eq 5 ] && echo "" && exit 0

#baseDir=$(dirname $0)
#logFNDate="$(date '+%Y%m%d')"
tBegineTm=$(date +%s)

secondDirFlag=0
secondStr=""

if [[ ${opType} -eq 1 || ${opType} -eq 2 ]];then
    toDstDir=/zfmd/wpfs20
elif [[ ${opType} -eq 3 || ${opType} -eq 4 ]];then
    toDstDir=/zfmd
fi

if [[  ${opType} -eq 1 || ${opType} -eq 4 ]];then
    secondDirFlag=1
    secondStr="及二级子目录"
fi

if [ ! -d "${toDstDir}" ];then
    echo -e  "\n\t要统计分析的[${toDstDir}]目录不存在 \n"
    exit 1
fi

echo -e "\n\n=============将要统计\e[1;31m[ ${toDstDir} ]\e[0m文件夹下子目录${secondStr}占用硬盘情况（统计结果按占用硬盘大小的升序排列:"

#find "${toDstDir}" -maxdepth 1 -type d|sort|while read tnaa
find "${toDstDir}" -maxdepth 1 -type d 2>/dev/null|egrep -v "^${toDstDir}$"|xargs -d '\n' du -sm|sort -n -k1|awk -F'\t' '{print $2}'|while read tnaa
do
    echo -e "\n\e[1;31m------------------------------------------------------------\e[0m"
    tsize=$(du -sh "${tnaa}"|awk '{print $1}')
    printf "%-40s  %10s \n" "${tnaa}" "${tsize}"
    echo -e "\e[1;31m------------------------------------------------------------\e[0m"
    if [ ${secondDirFlag} -eq 1 ];then
        find "${tnaa}" -maxdepth 1 -type d 2>/dev/null|egrep -v "^${tnaa}$"|xargs -d '\n' du -sm|sort -n -k1|awk -F '\t' '{print $2}'|while read tnaa2
        do
            tsize2=$(du -sh "${tnaa2}"|awk '{print $1}')
            printf "    %-40s --> %10s \n" "${tnaa2}" "${tsize2}"

        done
    fi
    tCoreNum=$(find "${tnaa}" -name "core.*" -type f|wc -l)
    if [ ${tCoreNum} -gt 0 ];then
        tCoresize=$(find "${tnaa}" -name "core.*" -type f|xargs -d '\n' du -sh -c|tail -1|awk '{print $1}')
        #tCoresize1=$(find "${tnaa}" -name "core.*" -type f|xargs -d '\n' du -s|awk '{sum1+=$1}END{print sum1}')
        echo -e "\n\t目录下的所有core文件占用空间为:\e[1;31m ${tCoresize} \e[0m"
    fi
done

tTalSize=$(du -sh "${toDstDir}"|awk '{print $1}')
tEndTm=$(date +%s)

tRunTm=$(echo "${tEndTm} - ${tBegineTm}"|bc)

echo -e "\n\e[1;31m================================================================================\e[0m"
echo -e "\t${toDstDir} 文件夹下面文件的总大小为: \e[1;31m${tTalSize}\e[0m\n"
echo -e "\t此统计脚本总运行时长: \e[1;31m${tRunTm} 秒\e[0m\n"
echo -e "\t\e[1;31m【说明】：\n\t\t此脚本统计结果越靠后的占用硬盘空间越大!\e[0m\n"
echo -e "\e[1;31m================================================================================\e[0m\n\n"

#echo -e "\n\t$(date +%Y/%m/%d-%H:%M:%S.%N): script [$0] runs complete!!\n\n"

exit 0

