#!/bin/bash
#
############################################################
#
# author : fushikai
# date   : 20210408
# dsc    : 从1.7预测数据入库日志中提取整场数据，生成csv结果文件
#
############################################################
#

tmpFcbh="011202"


function F_BSFSFX()
{

    #grep "\s测风时刻为" *.log |awk -F'，' '{print $(NF-2),$(NF-1),$NF}'|sed 's/。//g'|while read a1 a2 a3 a4 a5 a6 a7
    #grep "\s测风时刻为" *.log |awk -F'，' '{print $(NF-2),$(NF-1),$NF}'|sed 's/。//g'|sed 's/^\s\+//g'|while read a1 a2 a3 a4 a5 a6 a7

    local a1; local a2; local a3; local a4
    local a5; local a6;

    echo "SJRQ,BSWPJFS,BSWPJFX,LSFCBH"


    grep "\s测风时刻为" *.log |awk -F'，' '{print $(NF-2),$(NF-1),$NF}'|sed 's/。//g'|sed 's/^\s\+测风时刻为：//g'|sed  's/风速为：//g'|sed  's/风向为：//g'|sed 's///g'|while read a1 a2 a3 a4 a5 a6 
    do

        echo "${a1} ${a2},${a3},${a4},${tmpFcbh}"
    done

    return 0
}

function F_yggl()
{
    local a1; local a2; local a3; local a4
    local a5; local a6;

    echo "SJRQ,YGGL,FCBH"


    grep "\s获取整场功率的运行时间为" *.log|awk -F',' '{print $(NF-2),$(NF-1)}'|awk '{print $(NF-2),$(NF-1),$NF}'|sed 's/获取整场功率的运行时间为：//g;s/有功功率为：//g'|while read a1 a2 a3
    do
        echo "${a1} ${a2},${a3},${tmpFcbh}"
    done


    return 0
}

main()
{
    F_BSFSFX >fsfx.csv
    F_yggl>yggl.csv

}

main

exit 0
