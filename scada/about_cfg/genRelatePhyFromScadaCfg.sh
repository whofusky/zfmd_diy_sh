#!/bin/bash


#############################################################################
#author       :    fushikai
#date         :    20190410
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    将scada的出库通道配置文件与其他通道配置文件比较，并自动将出库通道的数据id
#    与其他通道配置文件进行比较，其他通道中关联的物理量生成关联结点插入到出库
#    通道的配置文件中
#       说明：（1）sfile表示的是出库配置文件
#             （2）allSrcFile表示的是其他的配置文件
#             （3）noFindFile中在脚本运行结束后，保存的是出库配置文件id在其他
#                  配置文件中未找到的id值
#              (4) deleteFlag为1时，脚本运行过程生产的临时文件在脚本运行结束后
#                  自动删除
#
#############################################################################




baseDir=$(dirname $0)


#主需要处理的文件
sfile="${baseDir}/chn_6.xml"
allSrcFile="${baseDir}/unitMemInit.xml"
noFindFile="${baseDir}/noFindFile.txt"

#临时文件
tmpFindTarDidFile="${baseDir}/tmp1.txt"
tmpInser="${baseDir}/tmpInser.txt"
tmpChnFile="${baseDir}/tmpChnFile.txt"

tmpFileS[0]=${tmpFindTarDidFile}
tmpFileS[1]=${tmpInser}
tmpFileS[2]=${tmpChnFile}
deleteFlag=1


if [ ! -e ${sfile} ];then
    echo -e "\n\tError: file [ ${sfile} ] does not exist!\n"
    exit 1
fi

if [ ! -e ${allSrcFile} ];then
    echo -e "\n\tError: file [ ${allSrcFile} ] does not exist!\n"
    exit 2
fi


beginRunTime="script [ $0 ] starts running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"


#找到需要匹配的配置文件中各通道的开始和结束行号
idx=0
egrep -n "^\s*(<\<channel\>.|</channel>)\s*" ${allSrcFile} >${tmpChnFile}

while read tnaa
do
    num1=$(echo "${tnaa}"|egrep "^.*\s*<\<channel\>.\s*"|wc -l)
    num2=$(echo "${tnaa}"|egrep "^.*\s*</channel>\s*"|wc -l)
    linenum=$(echo "${tnaa}"|awk -F':' '{print $1}')
    if [ ${num1} -gt 0 ];then
        bbNum[${idx}]=${linenum}    
        chname=$(sed -n "${bbNum[${idx}]}p" ${allSrcFile}|awk -F'[<> ]' '{for(i=1;i<=NF;i++){if($i ~ /chnNum=./){print $i;break;} }}')
        chnNoS[${idx}]=$(echo "${chname}"|awk -F'"' '{print $2}')
    elif [ ${num2} -gt 0 ];then
        eeNum[${idx}]=${linenum}    
        #echo "${bbNum[${idx}]},${eeNum[${idx}]}"
        let idx++
    fi

    #echo "idx=[${idx}]"
    #echo "[${tnaa}],num1=[${num1}],num2=[${num2}],linenum=[${linenum}]"
done<${tmpChnFile}

#echo "idx=[${idx}]"
doNum1=${#bbNum[*]}
doNum2=${#eeNum[*]}
#echo "doNum1=[${doNum1}],doNum2=[${doNum2}]"

#    for ((i=0;i<${doNum1};i++))
#    do
#
#        echo "------$i---------"
#        echo "chnNo=[${chnNoS[${i}]}]"
#        echo "begine=[${bbNum[${i}]}]"
#        echo "end=[${eeNum[${i}]}]"
#        echo ""
#    done





function findChnNo()
{
    if [ $# -ne 1 ];then
        echo -e "\n\t Error: function findChnNo input parameters number not eq 1\n"
        return 1
    fi
    serLineNo="$1"

    for ((i=0;i<${doNum1};i++))
    do

        if [[ ${serLineNo} -ge ${bbNum[${i}]} && ${serLineNo} -le ${eeNum[${i}]} ]];then
            echo "${chnNoS[${i}]}"
            return 0
        fi
    done

    echo "Error:not found!"
    return 2

}





egrep -n "^\s*<\<dataId\>.*\>" ${sfile}|grep -vw "DATAKIND_INVALID">${tmpFindTarDidFile}
noFindNum=0
>${noFindFile}

while read tnaa
do

    #echo -e "\n ${tnaa} \n"
    
    tmpdid=$(echo "${tnaa}"|awk -F"[<>]" '{print $2}')
    #echo -e "\n ${tmpdid} \n"

   ############################## 1.找对应数据id的配置在目标文件中的行号及phyType所在行号以便插入相关内容

   #################### 1.1找id在目标文件的行号（因为有插入内容，的以等号在循环中实时查询）
    tTarFindAllLNo=$(grep -n "${tmpdid}" ${sfile}|awk -F':' '{print $1}')
    #对错误的行不进行处理
    if [ -z ${tTarFindAllLNo} ];then
        echo -e "--------error:tTarFindAllLNo is null-----"
        continue
    fi

    tTarFindNum=$(echo -e "${tTarFindAllLNo}"|wc -l)
    
    #对错误的行不进行处理
    if [ ${tTarFindNum} -ne 1 ];then
        echo -e "-------errr:tTarFindNum=[${tTarFindNum}]-------\n"
        continue
    fi

    #echo "tTarFindAllLNo=[${tTarFindAllLNo}]"

    tmpMaxPreNum=20
   #################### 1.2找phyType的行号
    tmpTarNo=${tTarFindAllLNo}
    for ((i=1;i<=${tmpMaxPreNum};i++))
    do
        if [ ${i} -eq ${tmpMaxPreNum} ];then

            echo -e "\n\tsearch file[ ${sfile}]---Error:--i=[${i}],tTarFindAllLNo=[${tTarFindAllLNo}]--for i biger than tmpMaxPreNum,and not find\n"
            break;
        fi

        let tmpTarNo--
        
        #如果找到</phyObjVal>结点还未找到 phyType 则退出,因为phyObjVal是另外一个物理量节点的边界
        tSearPhyEndNum=$(sed -n "${tmpTarNo}{/^\s*<\/phyObjVal>\s*$/p}" ${sfile}|wc -l)
        if [ ${tSearPhyEndNum} -gt 0 ];then
            echo -e "\n\tsearch file[ ${sfile}]---Error:--i=[${i}],tTarFindAllLNo=[${tTarFindAllLNo}]--find <\/phyObjVal>\n"
            break;
        fi
        #tTarPhyNum=$(sed -n "${tmpTarNo}{/\<phyType\>\s*=/p}" ${sfile}|wc -l)
        tTarPhyNum=$(sed -n "${tmpTarNo}{/\s*<\s*phyObjVal\>/p}" ${sfile}|wc -l)
        if [ ${tTarPhyNum} -gt 0 ];then


#            if [ ${i} -gt 6 ];then
#                echo "+++++i=[${i}]++++tTarFindAllLNo=[${tTarFindAllLNo}]+++++"
#
#            fi

#            tPhyName=$(sed -n "${tmpTarNo}{/\<phyType\>\s*=/p}" ${sfile}|awk -F'[<> ]' '{for(i=1;i<=NF;i++){if($i ~ /phyType=./){print $i;break;} }}')
#            tPhyVal=$(echo "${tPhyName}"|awk -F'"' '{print $2}')
            #echo "--i=[${i}]----${tPhyName}---"
            break
        fi

    done
 
   ############################## 2.找对应数据id的配置在关联关系的文件中行号
    tSearFindAllLNo=$(grep -n "${tmpdid}" ${allSrcFile}|awk -F':' '{print $1}')
    #对错误的行不进行处理
    if [ -z ${tSearFindAllLNo} ];then
        #echo -e "--------error:tSearFindAllLNo is null-----"
        echo "${tmpdid}">>${noFindFile}
        let noFindNum++
        continue
    fi

    tSearFindNum=$(echo -e "${tSearFindAllLNo}"|wc -l)
    
    #对错误的行不进行处理
    if [ ${tSearFindNum} -ne 1 ];then
        echo -e "-------errr:tSearFindNum=[${tSearFindNum}]-------\n"
        continue
    fi

    #echo "tSearFindAllLNo=[${tSearFindAllLNo}]"
   #################### 2.1找对应关系id对应的物理量
    tmpNo=${tSearFindAllLNo}
    for ((i=1;i<=${tmpMaxPreNum};i++))
    do
        if [ ${i} -eq ${tmpMaxPreNum} ];then

            echo -e "\n\tsearch file[ ${allSrcFile}]---Error:--i=[${i}],tSearFindAllLNo=[${tSearFindAllLNo}]--for i biger than tmpMaxPreNum,and not find\n"
            break;
        fi

        let tmpNo--
        
        #如果找到</phyObjVal>结点还未找到 phyType 则退出,因为phyObjVal是另外一个物理量节点的边界
        tSearPhyEndNum=$(sed -n "${tmpNo}{/^\s*<\/phyObjVal>\s*$/p}" ${allSrcFile}|wc -l)
        if [ ${tSearPhyEndNum} -gt 0 ];then
            echo -e "\n\tsearch file[ ${allSrcFile}]---Error:--i=[${i}],tSearFindAllLNo=[${tSearFindAllLNo}]--find <\/phyObjVal>\n"
            break;
        fi
        #tPhyNum=$(sed -n "${tmpNo}{/\<phyType\>\s*=/p}" ${allSrcFile}|wc -l)
        tPhyNum=$(sed -n "${tmpNo}{/\s*<\s*phyObjVal\>/p}" ${allSrcFile}|wc -l)
        if [ ${tPhyNum} -gt 0 ];then


#            if [ ${i} -gt 6 ];then
#                echo "+++++i=[${i}]++++tSearFindAllLNo=[${tSearFindAllLNo}]+++++"
#
#            fi

            tPhyName=$(sed -n "${tmpNo}{/\<phyType\>\s*=/p}" ${allSrcFile}|awk -F'[<> ]' '{for(i=1;i<=NF;i++){if($i ~ /phyType=./){print $i;break;} }}')
            tPhyVal=$(echo "${tPhyName}"|awk -F'"' '{print $2}')
            #echo "--i=[${i}]----${tPhyName}---"
            break
        fi

    done
    

   #################### 2.2.找对应数据id的配置在关联关系的文件中的通道号
    tserChnNo=$(findChnNo ${tSearFindAllLNo})
    ret=$?
    if [ ${ret} -ne 0 ];then
       echo -e "${tserChnNo}"
       continue 
    fi

    echo "---------tserChnNo=[${tserChnNo}]---------------tPhyVal=[${tPhyVal}]----"


   ############################## 3.拼要插入的字符串并将字符串插入到配置文件中

    #sed -n "${tmpTarNo}p" ${sfile}
   #################### 3.1.拼字符串
    toInserStr="                <relPhyType>
                    <phyType chnNo=\"${tserChnNo}\">${tPhyVal}</phyType>
                </relPhyType>"

#    echo ""
#    echo "${toInserStr}"
#    echo ""

    echo "${toInserStr}">${tmpInser}
    
   #################### 3.2.插入到配置文件
    sed -i "${tmpTarNo}r ${tmpInser}" ${sfile}


done<${tmpFindTarDidFile}


echo -e "\n\tnoFindNum=[${noFindNum}]\n"

tmpFileNum=${#tmpFileS[*]}
if [[ ${tmpFileNum} -gt 0 && ${deleteFlag} -eq 1 ]];then
    for ((i=0;i<${tmpFileNum};i++))
    do
        echo -e "\n\t rm -rf ${tmpFileS[${i}]}\n"
        rm -rf ${tmpFileS[${i}]}
    done

fi


endRunTime="script [ $0 ] end running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"

echo -e "\n\t${beginRunTime}\n"
echo -e "\n\t${endRunTime}\n"



exit 0

