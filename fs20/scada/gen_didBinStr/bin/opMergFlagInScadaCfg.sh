#!/bin/bash
#
################################################################################
#
#author: fusky
#date  : 2021-08-24
#Dsc   :
#       add or delete content "<logCfg mergeLogFlag="1"/> " in  the input file
#use   :
#      opMergFlagInScadaCfg.sh   <opFlag>  <inPutFile>
#                           opFlag:    add  添加; del 删除
#                           inPutFile: 要处理的文件名命名:scdCfg.xml
#
#
################################################################################

inSh="$0"; inNum="$#"; inFlag="$1"; inFile="$2";

baseDir="./"

addContent='        <!--日志的相关配置 mergeLogFlag:1 将scada的所有输出日志合并到一个文件，其他值为表示不合并-->\r
        <logCfg mergeLogFlag="1"/> \r'
sysCfg_NOS=""; logCfg_NO="";  logCfg_cmNO="";
sysCfg_BN="";  sysCfg_EN="";

tmpFile1=""; tmpFile2="";

function F_tips()
{
    echo -e "\n  input like:\n"
    echo -e "    ${inSh}  <opFlag>  <inPutFile>"
    echo -e "        #opFlag:    add  添加; del 删除"
    echo -e "        #inPutFile: 要处理的文件名命名:scdCfg.xml\n"

    return 0
}


function F_check()
{
    if [ ${inNum} -ne 2 ];then
        F_tips
        exit 1
    fi
    
    if [[ "xadd" != "x${inFlag}" && "xdel" != "x${inFlag}" ]];then
        F_tips
        exit 2
    fi
    
    if [ ! -f "${inFile}" ];then
        echo -e "\n\t\e[1;31mERROR:\e[0m input file [${inFile}] not exist!\n"
        exit 3
    fi

    baseDir=$(dirname "${inFile}")

    sysCfg_NOS=$(sed -n '/^\s*<\s*\/\?sysCfg\s*>/{=;/^\s*<\s*\/\s*sysCfg\s*>/q}' "${inFile}")
    local tnum=$(echo "${sysCfg_NOS}"|wc -l)
    if [ ${tnum} -ne 2 ];then
        echo -e "\n\t\e[1;31mERROR:\e[0m in file [${inFile}] not have \"sysCfg\" xml nodes\n"
        exit 4
    fi

    local i=0; local tmpStr="";
    for tmpStr in ${sysCfg_NOS}
    do
        [ $i -eq 0 ] && sysCfg_BN=${tmpStr}
        [ $i -eq 1 ] && sysCfg_EN=${tmpStr}
        let i++
    done

    echo "----sysCfg_BN=[${sysCfg_BN}],sysCfg_EN=[${sysCfg_EN}]"
    logCfg_NO=$(sed -n "${sysCfg_BN},${sysCfg_EN}{/^\s*<\s*logCfg\s*/=;${sysCfg_EN}q}" "${inFile}")
    if [  ! -z "${logCfg_NO}" ];then
        logCfg_cmNO=$(echo "${logCfg_NO} -1"|bc)
        tnum=$(sed -n "${logCfg_cmNO}{/^\s*<\!/=;q}" "${inFile}")
        if [ ${tnum} -eq 0 ];then
            logCfg_cmNO=""
        fi
    fi

    echo "----logCfg_NO=[${logCfg_NO}],logCfg_cmNO=[${logCfg_cmNO}]"

    if [[ "x${inFlag}" = "xadd" ]];then
        if [ ! -z "${logCfg_NO}" ];then 
            echo -e "\n\tTIPS: There are already \"logCfg\" nodes in the file [${inFile}] \n"
            exit 0
        fi
        tmpFile1="${baseDir}/$$.tmp"
        tmpFile2="${tmpFile1}_2"
    else
        if [  -z "${logCfg_NO}" ];then 
            echo -e "\n\tTIPS: There is not \"logCfg\" node in the file [${inFile}] \n"
            exit 0
        fi
    fi

    return 0
}


function F_doOp()
{
    if [ "x${inFlag}" = "xadd" ];then
        echo -e "${addContent}">${tmpFile1}
        iconv -f utf-8 -t gbk ${tmpFile1} -o ${tmpFile2}
        echo "sed -i \"${sysCfg_BN} r ${tmpFile2}\" \"${inFile}\""
        sed -i "${sysCfg_BN} r ${tmpFile2}" "${inFile}"
        rm -rf "${tmpFile2}"
        rm -rf "${tmpFile1}"
    else
        if [ ! -z "${logCfg_NO}" ];then
            sed -i "${logCfg_NO} d" "${inFile}"
        fi
        if [ ! -z "${logCfg_cmNO}" ];then
            sed -i "${logCfg_cmNO} d" "${inFile}"
        fi
    fi
    return 0
}

main()
{
    F_check
    F_doOp
    echo -e "\n\t $0 exe complete!\n"
    return 0
}

main

exit 0
