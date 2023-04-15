#!/bin/bash
##############################################################################
# date  :  2023-04-15
# dsc   :  将脚本目录下的运行产生的文件或目录删除,恢复初始状态
#
##############################################################################


runDir=$(dirname $0)
#echo "runDir=[${runDir}]"

function F_rmObj()
{
    if [ $# -ne 1 ];then
        return 0
    fi

    if [ -e "${1}" ];then
        echo "rm -rf ${1}"
        rm -rf "${1}"
    fi
}


function main()
{
    local opType prompct1
    prompct1="       
           [提示]:执行此操作前请【再三确认】是否要让当前目录下
                  的环境回归到部署的初始状态!!

           请输入y/n，选择相应的操作：
                    [y].非常确认
                    [n].退出，什么都不做
          你的选择是: "

    while ((1))
    do

        read -n 1 -p "${prompct1}" opType

        if [[ "x${opType}" != "xy" && "x${opType}" != "xn"  ]];then
        echo ""
        echo " -----------ERROR---------------------:Input errors,please re-enter!"
            continue
        fi

        break

    done

    [ ${opType} = "n" ] && echo "" && exit 0


    F_rmObj "${runDir}/tmp"
    F_rmObj "${runDir}/log"
    F_rmObj "${runDir}/result"
    F_rmObj "${runDir}/gen_tmp_srcfile/result"
}

main
