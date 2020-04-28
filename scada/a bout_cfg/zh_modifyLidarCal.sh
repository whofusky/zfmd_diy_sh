#!/bin/sh

#修改主和备激光雷达1分钟5分钟10分钟15分钟风速风向平均值的计算方法



baseDir=$(dirname $0)

echo "---baseDir=[${baseDir}]-----"

edFileName="${baseDir}/unitMemInit.xml"

if [ ! -e "${edFileName}" ];then
    echo -e "\n\tError: file [${edFileName}] does not exists!\n"
    exit 1
fi


#修改通道的开始行号及结束行号
beginNoS[0]=16
endNoS[0]=1359
beginNoS[1]=1949
endNoS[1]=3289



tmpMaxPreNum=20

function getPhyNo()
{
    if [ $# -ne 1 ];then
        echo "getPhyNo function input parameter numbers error not eq 1"
        return 1
    fi
    beNo=$1
    for ((i=1;i<=${tmpMaxPreNum};i++))
    do
        if [ ${i} -eq ${tmpMaxPreNum} ];then

            echo -e "\n\tsearch file[ ${edFileName}]---Error:--i=[${i}],beNo=[${beNo}]--for i biger than tmpMaxPreNum,and not find\n"
            return 2
        fi
        let beNo--
        tSearPhyEndNum=$(sed -n "${beNo}{/^\s*<\s*phyObjVal\>\s*/p}" ${edFileName}|wc -l)
        if [ ${tSearPhyEndNum} -gt 0 ];then
            echo "${beNo}"
            return 0
        fi
    done

    echo "${beNo}"
    return 3

}

function chgCalVal()
{
    if [ $# -ne 2 ];then
        echo "chgCalVal function input parameter number error not eq 2"
        return 1
    fi
    beNo=$1
    tVal="$2"

    #echo "---beNo=[${beNo}],tVal=[${tVal}]----"

    tfindNo=$(getPhyNo ${beNo})
    retStat=$?
    if [ ${retStat} -eq 0 ];then

        #sed -i "${tfindNo}{s/calcMethd\s*=\s*\"[^\s]*\"/calcMethd=\"${tVal}\"/}" ${edFileName}
        sed -i "${tfindNo}{s/calcMethd\s*=\s*\"[0-9a-zA-Z_]*\"/calcMethd=\"${tVal}\"/}" ${edFileName}
    else
        echo "+++++++tfindNo=[${tfindNo}],retStat=[${retStat}]+++++"
        return 2
    fi
    
    return 0

}

tpartNo=0

function chgOneChnnel()
{
    if [ $# -ne 2 ];then
        echo "chgOneChnnel function input parameter number error not eq 2"
        return 1
    fi

    let tpartNo++

    beNo=$1
    endNo=$2

    echo -e "\n\t--------- edit file [${edFileName}],第[${tpartNo}]部分要处理的内容:beNo=[${beNo}],endNo=[${endNo}]----------------\n"

    echo "#1分钟平均 风速"
    #1分钟平均 风速
    sed -n "${beNo},${endNo}{/\s*<\s*dataId\>.*\"DATACATALOG_WS\".*\"DATAKIND_AVG\".*ivalue\s*=\s*\"1\"/=}" ${edFileName}|while read tnaa
    do
        echo "id line NO=[${tnaa}]"
        chgCalVal "${tnaa}" "PHY_CALC_ADD"
    done

    #exit 0

    echo -e "\n"
    echo "#1分钟平均 风向"
    #1分钟平均 风向
    sed -n "${beNo},${endNo}{/\s*<\s*dataId\>.*\"DATACATALOG_WD\".*\"DATAKIND_AVG\".*ivalue\s*=\s*\"1\"/=}" ${edFileName}|while read tnaa
    do
        echo "id line NO=[${tnaa}]"
        chgCalVal "${tnaa}" "PHY_CALC_ADD"
    done




    echo -e "\n"
    echo "#5分钟平均 风速"
    #5分钟平均 风速
    sed -n "${beNo},${endNo}{/\s*<\s*dataId\>.*\"DATACATALOG_WS\".*\"DATAKIND_AVG\".*ivalue\s*=\s*\"5\"/=}" ${edFileName}|while read tnaa
    do
        echo "id line NO=[${tnaa}]"
        chgCalVal "${tnaa}" "PHY_CALC_ADD_SUM"
    done


    echo -e "\n"
    echo "#5分钟平均 风向"
    #5分钟平均 风向
    sed -n "${beNo},${endNo}{/\s*<\s*dataId\>.*\"DATACATALOG_WD\".*\"DATAKIND_AVG\".*ivalue\s*=\s*\"5\"/=}" ${edFileName}|while read tnaa
    do
        echo "id line NO=[${tnaa}]"
        chgCalVal "${tnaa}" "PHY_CALC_WIND_MEAN"
    done



    echo -e "\n"
    echo "#10分钟平均 风速"
    #10分钟平均 风速
    sed -n "${beNo},${endNo}{/\s*<\s*dataId\>.*\"DATACATALOG_WS\".*\"DATAKIND_AVG\".*ivalue\s*=\s*\"10\"/=}" ${edFileName}|while read tnaa
    do
        echo "id line NO=[${tnaa}]"
        chgCalVal "${tnaa}" "PHY_CALC_ADD_SUM"
    done


    echo -e "\n"
    echo "#10分钟平均 风向"
    #10分钟平均 风向
    sed -n "${beNo},${endNo}{/\s*<\s*dataId\>.*\"DATACATALOG_WD\".*\"DATAKIND_AVG\".*ivalue\s*=\s*\"10\"/=}" ${edFileName}|while read tnaa
    do
        echo "id line NO=[${tnaa}]"
        chgCalVal "${tnaa}" "PHY_CALC_WIND_MEAN"
    done



    echo -e "\n"
    echo "#15分钟平均 风速"
    #15分钟平均 风速
    sed -n "${beNo},${endNo}{/\s*<\s*dataId\>.*\"DATACATALOG_WS\".*\"DATAKIND_AVG\".*ivalue\s*=\s*\"15\"/=}" ${edFileName}|while read tnaa
    do
        echo "id line NO=[${tnaa}]"
        chgCalVal "${tnaa}" "PHY_CALC_ADD_SUM"
    done


    echo -e "\n"
    echo "#15分钟平均 风向"
    #15分钟平均 风向
    sed -n "${beNo},${endNo}{/\s*<\s*dataId\>.*\"DATACATALOG_WD\".*\"DATAKIND_AVG\".*ivalue\s*=\s*\"15\"/=}" ${edFileName}|while read tnaa
    do
        echo "id line NO=[${tnaa}]"
        chgCalVal "${tnaa}" "PHY_CALC_WIND_MEAN"
    done


    return 0

}


chgOneChnnel ${beginNoS[0]} ${endNoS[0]} 
chgOneChnnel ${beginNoS[1]} ${endNoS[1]} 

