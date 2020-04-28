#!/bin/bash

deErrNo=100
baseDir=$(dirname $0)

function mpDebugFlag()
{
    if [ $# -ne 5 ];then
       return ${deErrNo}
    fi

    searStr=$1
    newVal=$2
    edFile=$3
    if [ ! -f "${edFile}" ];then
        echo "Error: the file [${edFile}] not exist!"
        return $((${deErrNo}+1))
    fi

    doFlag=$4
    tcheck=$(echo "${doFlag}"|sed -n "/^[0-9]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && doFlag=0

    prtFlag=$5
    tcheck=$(echo "${prtFlag}"|sed -n "/^[0-9]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && prtFlag=0

    existFlag=$(sed -n "/debugFlag\s*=\s*\<${newVal}\>\s*/p" ${edFile}|wc -l)
    if [ ${existFlag} -gt 0 ];then
        if [ ${prtFlag} -eq 1 ];then
            echo ""
            echo "  配置文件[${edFile}]中debugFlag已经是你要修改的值，不需要再修改了!"
            sed -n "/debugFlag\s*=\s*\<${newVal}\>\s*/p" ${edFile}
            echo ""
        fi
        return 1
    fi

    beforeFlag=$(sed -n "/debugFlag\s*=\s*${searStr}\s*/p" ${edFile}|wc -l)
    if [ ${beforeFlag} -gt 0 ];then
        if [ ${prtFlag} -eq 1 ];then
            echo ""
            echo "  配置文件[${edFile}]中debugFlag修改前的值如下："
            sed -n "/debugFlag\s*=\s*${searStr}\s*/p" ${edFile}
            echo ""
        fi

        if [ ${doFlag} -eq 1 ];then
            sed "s/debugFlag\s*=\s*${searStr}\s*/debugFlag=${newVal}/g" -i ${edFile}
        fi

        if [ ${prtFlag} -eq 1 ];then
            echo ""
            echo "  配置文件[${edFile}]中debugFlag修改后的值如下："
            sed -n "/debugFlag\s*=\s*${searStr}\s*/p" ${edFile}
            echo ""
        fi

        return 2
    fi

    return 0
}

prompct1="       
       请输入如下选择项前的数字进行选择
                [1].停zfmd用户下的自启动脚本
                [2].停root用户下的自启动脚本
                [3].停zfmd用户和root用户下的启动脚本
                [4].退出，什么都不做
      你的选择是: "
#echo "---${prompct1}"
curUid=$(id -u $(whoami))
if [ ${curUid} -eq 0 ];then
    while ((1))
    do

        read -n 1 -p "${prompct1}" opFile

        if [[ ${opFile} -ne 1 && ${opFile} -ne 2 && ${opFile} -ne 3 && ${opFile} -ne 4 ]];then
        echo ""
        echo " -----------ERROR---------------------:输入错误，请重新输入:"
            continue
        fi

        break

    done
else
    opFile=1
fi

[ ${opFile} -eq 4 ] && echo "" && exit 0

#echo "baseDir=[${baseDir}]"
#echo "opFile=[${opFile}]"

edzfmdcfg=${baseDir}/rcfg.cfg
edrootcfg=${baseDir}/rcfgRoot.cfg

if [ ${opFile} -eq 1 -o ${opFile} -eq 3 ] && [ ! -w ${edzfmdcfg} ];then
	echo " 你没有权限修改 zfmd 下的配置文件:${edzfmdcfg}"
	echo ""

	exit 1
fi
if [ ${opFile} -eq 2 -o ${opFile} -eq 3 ] && [ ! -w ${edrootcfg} ];then
	echo " 你没有权限修改 root 下的配置文件: ${edrootcfg}"
	echo ""

	exit 2
fi
echo ""
echo "===================================================================>"
if [  ${opFile} -eq 3 ];then
    mpDebugFlag '[0-9]' '3' ${edzfmdcfg} "1" "1"
    mpDebugFlag '[0-9]' '3' ${edrootcfg} "1" "1"
elif [  ${opFile} -eq 2 ];then
    mpDebugFlag '[0-9]' '3' ${edrootcfg} "1" "1"
elif [  ${opFile} -eq 1 ];then
    mpDebugFlag '[0-9]' '3' ${edzfmdcfg} "1" "1"
fi

#echo "  【提示】：如果停监视前和停监视后值一样，则说明配置文件里的值已经是停监视状态！"
echo "<==================================================================="

echo ""
echo "script [$0] execution completed !!"
echo ""
