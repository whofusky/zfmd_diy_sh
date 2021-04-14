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

#grep "\s测风时刻为" *.log |awk -F'，' '{print $(NF-2),$(NF-1),$NF}'|sed 's/。//g'|while read a1 a2 a3 a4 a5 a6 a7
#grep "\s测风时刻为" *.log |awk -F'，' '{print $(NF-2),$(NF-1),$NF}'|sed 's/。//g'|sed 's/^\s\+//g'|while read a1 a2 a3 a4 a5 a6 a7

echo "SJRQ,BSWPJFS,BSWPJFX,LSFCBH"

grep "\s测风时刻为" *.log |awk -F'，' '{print $(NF-2),$(NF-1),$NF}'|sed 's/。//g'|sed 's/^\s\+测风时刻为：//g'|sed  's/风速为：//g'|sed  's/风向为：//g'|sed 's///g'|while read a1 a2 a3 a4 a5 a6 
do

    echo "${a1} ${a2},${a3},${a4},011202"
done

exit 0
