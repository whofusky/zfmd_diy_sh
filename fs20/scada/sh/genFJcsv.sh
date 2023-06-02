#!/bin/bash
#
##############################################################################
#author : fu.sky
#date   : 2022-09-27_15:45:17
#dsc    :
#         此脚本是用于scada自动自动配置文件时，需要根据第一台风机的csv配置,生成
#         所有风机的csv配置
#
#
##############################################################################
#
#

thisSh="$0" ;inPutNum="$#"

tModelFileName="$1"
tOutFileName="$2"
tOutFJNum="$3"
inModeFJNo="${4:-1}"  #如果输入模型文件的开始编号则以输入为准,否则默认为1
tPwd="$(pwd)"

function F_tips()
{
    echo -e "\n\tinput like:\n\t\t${thisSh} <model_file> <out_file> <fan_nums> [mode_fj_no]\n"
    return 0
}

function F_dumpInput()
{
    echo -e "\n${thisSh} <model_file> <out_file> <fan_nums> [mode_fj_no]"
    return 0
}

function F_check()
{
    if [ ${inPutNum} -lt 3 ];then
        F_tips
        exit 2
    fi
    if [ ! -f "${tModelFileName}" ];then
        F_dumpInput
        echo -e "\n\tERROR:model_file [ ${tModelFileName} ] not exist!\n"
        exit 1
    fi

    local tnum=$(echo "${tOutFJNum}"|sed -n '/^[1-9][0-9]*$/p'|wc -l)
    if [ ${tnum} -eq 0 ];then
        F_dumpInput
        echo -e "\n\tERROR:fan_nums [ ${tOutFJNum} ] is not a number!\n"
        exit 1
    fi

    g_model_line_num=$(sed -n '/^\([0-9]\|[a-zA-Z]\)/p' "${tModelFileName}"|wc -l)
    let g_model_line_num--
    return 0
}

function F_OneXfan()
{
    local model_src_fjNo="$1"
    local out_fjNo="$2"

    #是否针一组风机中不同的行进行不同量的添加标识:0 不特殊, 1 特殊
    local specialFlag=0 

    local taddend=$(echo "($out_fjNo - ${model_src_fjNo}) * ${g_model_line_num}*2"|bc)

    #如果是特殊处理则需要针对每组中的不同行都定义一个添加量,有多少就要定义多个变量
    if [ "x${specialFlag}" != "x0" ];then
        local multFactor=$(echo "${g_model_line_num} -1"|bc)
        spe_addr[0]=$(echo "($out_fjNo - ${model_src_fjNo}) * ${multFactor}*2"|bc)
        spe_addr[1]=$(echo "($out_fjNo - ${model_src_fjNo}) * ${multFactor}*2"|bc)
        spe_addr[2]=$(echo "($out_fjNo - ${model_src_fjNo}) * ${multFactor}*2"|bc)
        spe_addr[3]=$(echo "($out_fjNo - ${model_src_fjNo}) * ${multFactor}*2"|bc)
        spe_addr[4]=$(echo "($out_fjNo - ${model_src_fjNo}) * ${multFactor}*2"|bc)
        spe_addr[5]=$(echo "($out_fjNo - ${model_src_fjNo}) * ${multFactor}*2"|bc)
        spe_addr[6]=$(echo "($out_fjNo - ${model_src_fjNo}) * ${multFactor}*2"|bc)
        spe_addr[7]=$(echo "($out_fjNo - ${model_src_fjNo}) * ${multFactor}*2"|bc)
        spe_addr[8]=$(echo "($out_fjNo - ${model_src_fjNo}) * ${multFactor}*2"|bc)
        spe_addr[9]=$(echo "($out_fjNo - ${model_src_fjNo}) *2"|bc)
    fi

    local a1; local a2; local a3; local a4; local a5;
    local b1; local b2; local b3; local b4; local b5;
    local i=0
    sed -n '/^[0-9]\+/p' "${tModelFileName}"|sed 's///g'|sed 's/^\([^,]\+\),\([^,]\+\),\([^,]\+\),\([^,]\+\),\([^,]\+\)/\1 \2 \3 \4 \5/'|while read a1 a2 a3 a4 a5 
do
    if [ "x${specialFlag}" != "x0" ];then
        b1=$(echo "$a1 + ${spe_addr[$i]}"|bc)
    else
        b1=$(echo "$a1 + $taddend"|bc)
    fi
    b2=$(echo "${a2}"|sed "s/^${model_src_fjNo}号风机/${out_fjNo}号风机/")
    b3="$a3"
    b4="${out_fjNo}"
    b5="$a5"

    #echo "----i=[$i]------"

    #echo "old:[$a1,$a2,$a3,$a4,$a5]"
    #echo "new:[$b1,$b2,$b3,$b4,$b5]"
    echo "${FUNCNAME}:[$b1,$b2,$b3,$b4,$b5]"
    echo "$b1,$b2,$b3,$b4,$b5">>"${tOutFileName}"

    let i++


done

    return 0
}

function F_genFan()
{
    local i=0
    #cp "${tModelFileName}" "${tOutFileName}"
    #sed -n '/^\S\+$/p' "${tModelFileName}" > "${tOutFileName}"
    sed -n '/^\([0-9]\|[a-zA-Z]\)/p' "${tModelFileName}" > "${tOutFileName}"
    local endFJno=$(echo "${inModeFJNo} + ${tOutFJNum} -1"|bc)
    local begFJno=$(echo "${inModeFJNo} + 1"|bc)
    for (( i=${begFJno};i<=${endFJno};i++))
    do
        #F_OneXfan 1 "$i"
        F_OneXfan ${inModeFJNo} "$i"
    done

    return 0
}

function F_test()
{
    echo "${FUNCNAME}:tPwd=[${tPwd}]"
    echo "${FUNCNAME}:g_model_line_num=[${g_model_line_num}]"

    return 0
}

#sed -n '2,$ p' model.csv |sed 's/^\([^,]\+\),\([^,]\+\),\([^,]\+\),\([^,]\+\),\([^,]\+\)/\1 \2 \3 \4 \5/'

main()
{
    F_check
    #F_test
    F_genFan
    

    return 0
}
main
