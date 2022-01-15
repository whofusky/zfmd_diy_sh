#!/bin/bash
#author:fushikai
#date: 2021-12-31_10:11:04
#DSC:一次生成最终的 did二进制字符串文件
 
#farmName="heiyanquan"
#ftmN="heiyq"

basedir="$(dirname $0)"
tBegineTm=$(date +%s)

export LD_LIBRARY_PATH=${basedir}/lib:${LD_LIBRARY_PATH}
cfgFile="${basedir}/cfg.cfg"
if [ ! -f "${cfgFile}" ];then
    echo -e "\n\tERROR: file [${cfgFile}] not exist!\n"
    exit 1
fi

. ${cfgFile}

export myRstDir="${basedir}/${farmName}"

[ ! -d "${myRstDir}" ] && mkdir -p "${myRstDir}"
preDoSh="${basedir}/todoDIdCfg.sh"
#cp -a "$0" "${myRstDir}"
cp -a "${cfgFile}" "${myRstDir}"

preUtfFile="${myRstDir}/pre_${frmN}binstr_did.xml"
preGbkFile="${myRstDir}/pre_${frmN}binstr_did_gbk.xml"

doBin="${basedir}/bin/genDidBinStr"
#doBin="/root/bin/genDidBinStr"
#doBin="${HOME}/bin/genDidBinStr"
oFPre="${farmName}_didBinStr"
oCsvFile="${basedir}/${oFPre}_$(date +%Y%m%d).csv"
oCsvFile1="${myRstDir}/${oFPre}_$(date +%Y%m%d).csv"

function F_echo_and_do()
{
    local cmd="$*"
    local ret=0
    local rFlag=0
    local tmpStr=""

    if [[ ! -z "${writeLogFlag}" && ${writeLogFlag} -eq 1 ]];then
        if [ -e "${logFile}" ];then
            rFlag=1
        fi
    fi

    local tnum=$(echo "${cmd}"|sed -n '/^\s*echo\b/p'|wc -l)

    if [ ${tnum} -eq 0 ];then
        if [ ${rFlag} -eq 1 ];then
            echo "${cmd}"|tee -a "${logFile}"
        else
            echo "${cmd}"
        fi
    fi

    if [[ -z "${debugFlag}" || ${debugFlag} -ne 1 ]];then
        if [ ${rFlag} -eq 1 ];then
            tmpStr=$(${cmd}  2>&1)
            ret=$?
            echo "${tmpStr}"|tee -a "${logFile}"
        else
            ${cmd}
            ret=$?
        fi
    fi

    return ${ret}
}

function F_rmExistFile() #Delete file if file exists
{
    local tInParNum=1
    local thisFName="${FUNCNAME}"
    if [ ${tInParNum} -gt  $# ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${thisFName} input parameter num less than  [${tInParNum}]!\n"
        return 1
    fi

    local tFile="$1"
    while [ $# -gt 0 ]
    do
        tFile="$1"
        if [ -e "${tFile}" ];then
            echo "rm -rf \"${tFile}\""
            rm -rf "${tFile}"
        fi
        shift
    done
    return 0
}

echo -e "\n\n=============do:${farmName}================="
if [ ! -e "${preDoSh}" ];then
    echo -e "\n\t\e[1;31mERROR:\e[0m line:${LINENO} file [${preDoSh}] not exist!\n"
    exit 1
fi

if [ ! -e "${doBin}" ];then
    echo -e "\n\t\e[1;31mERROR:\e[0m line:${LINENO} file [${doBin}] not exist!\n"
    exit 2
fi

[ ! -x "${preDoSh}" ] && F_echo_and_do chmod u+x ${preDoSh}
[ ! -x "${doBin}" ] && F_echo_and_do chmod u+x ${doBin}

F_echo_and_do F_rmExistFile ${preUtfFile} ${preGbkFile} ${oCsvFile}

F_echo_and_do ${preDoSh} ${preUtfFile}
[ $? -ne 0 ] && exit 1
echo -e "\n"
F_echo_and_do iconv -f utf8 -t gbk ${preUtfFile} -o ${preGbkFile}
echo -e "\n"
F_echo_and_do ${doBin} ${preGbkFile} ${oFPre}
echo -e "\n"

if [ -e "${oCsvFile}" ];then
    F_echo_and_do F_rmExistFile ${oCsvFile1}
    F_echo_and_do mv "${oCsvFile}" "${oCsvFile1}"
fi

tEndTm=$(date +%s)
tRunTm=$(echo "${tEndTm} - ${tBegineTm}"|bc) 
echo -e "\n\texe shell total Elapsed time [\e[1;31m${tRunTm}\e[0m] seconds"
echo -e "\t [$0] exute sucessfull! \n"

exit 0
