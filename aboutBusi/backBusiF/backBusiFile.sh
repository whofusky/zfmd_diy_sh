#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20210225
#linux_version:    Red Hat Enterprise Linux Server release 6.7 
#dsc          :   
#    Download and delte the business list from the corresponding 
#    directory on the configured ftp service, Compressed into a 
#    compressed package with wind farm name and date
#
#    (1) 根据cfg/cfg.cfg文件配置，用ftp脚本下载服务器配置目录下的的*.xml文件
#    (2) 下载完.xml文件后根据配置文件配置决定是否对下载成功的文件进行删除
#    (3) 对下载的文件格式处理（去掉DOS操作系统下的换行符：即去掉行尾的^M）
#    (4) 将下载的xml文件放于脚本同级目录下的result文件夹（脚本自动创建）并按远程
#        服务器对应的第一级目录（往往根据风场名取名)在本地result目录下建立二级
#        目录
#    (5) 每下载完后一个风场目录的文件后，对下载的文件进行打包，包名规则为:
#        远程服务器第一级目录名_文件开始时间_文件结束时间busi.zip
#    (6) 下载过程产生的日志记录于log/backBusiFile.log文件
#
#    例如：
#        下载服务上/gaolongshan/up目录下的所有xml文件
#        这些下载的文件时间跨度为:20210507到20210703
# 
#        文件下载到 result/gaolongshan文件夹下，所有文件下载完后，将此文件夹打包
#        成gaolongshan20210507_20210703busi.zip放于result目录，并清空本的目录
#        result/gaolongshan下的所有文件
# 
#limit
#    (1) 目前观察下载的速度不是很满意可能与具体的网络环境有关系
#
#version:
#    2021-07-04 update 注释
#
#############################################################################

debugFlagM=3            
#debugFlagM=255            
                          
#加载系统环境变量配置
if [ -f /etc/profile ]; then
    . /etc/profile >/dev/null 2>&1
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile >/dev/null 2>&1
fi

#已经有脚本在运行则退出
tmpShPid=$(pidof -x $0)
tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
if [ ${tmpShPNum} -gt 1 ]; then
    echo "+++${tmpShPid}+++++${tmpShPNum}+++"
    echo "`date +%Y/%m/%d-%H:%M:%S.%N`:$0 script has been running this startup exit!"
    exit 0
fi

begineTm="$(date +%y-%m-%d_%H:%M:%S.%N)"

inSh="$0"
inPath="${inSh%/*}"
if [ "${inPath}" = "${inSh}" ];then
    inPath="."
fi
inshName="${inSh##*/}"
inNPre="${inshName%.*}"

baseDir=$(dirname $0)   

diyFuncFile=${baseDir}/myshFunc.sh
tconfFile="${baseDir}/cfg/cfg.cfg"

logDir="${baseDir}/log"
logFile="${logDir}/${inNPre}.log"

tmpDir="${baseDir}/tmp"
tmpFile="${tmpDir}/tt.txt"
rcdFile="${tmpDir}/rcd.txt"
tmpDst="${baseDir}/result"
ftpLdir="${tmpDst}"

doNum=0




function F_clearFtpLDir()
{
    if [ $# -lt 2 ];then
        return 0
    fi

    local tDir="$1"
    local frmName="$2"
    [ -z "${frmName}" ] && return 0

    #echo "${FUNCNAME}:tDir=[${tDir}],frmName=[${frmName}]"

    local fullPath="${tDir}/${frmName}"
    if [ ! -d "${fullPath}" ];then
        mkdir -p "${fullPath}"
        return 0
    fi

    rm -rf "${fullPath}"/*

	return 0
}

function F_chkCfgFile()
{
    #echo "doNum=[${doNum}]"
    doNum=${#ftpip[*]}
    if [ ${doNum} -lt 1 ];then
        exit 0
    fi

    local tnum=0
    tnum=${#chkStr[*]}
    if [ ${tnum} -ne ${doNum} ];then
        F_outShDebugMsg ${logFile} 1 1 "ERROR:chkStr[*] is num=[${tnum} is not eq ftpip[*] 's num=[${doNum}]  in file [${tconfFile}]!"
        exit 1
    fi

    return 0
}

function F_check()
{
	if [ ! -f ${diyFuncFile} ];then
		echo -e "\n\t\e[1;31mError,in [${inSh}]\e[0m: File [ ${diyFuncFile} ] does not exist!!\n"
		exit 1
    fi

    if [ ! -e "${tconfFile}" ];then
        echo -e "\n\t\e[1;31mError,in [${inSh}]\e[0m: File [ ${cfgFile} ] does not exist!!\n"
        exit 9
    fi

    if [ ! -d "${logDir}" ];then
        mkdir -p "${logDir}"
    fi

    if [ ! -d "${tmpDir}" ];then
        mkdir -p "${tmpDir}"
    fi

    if [ ! -d "${tmpDst}" ];then
        mkdir -p "${tmpDst}"
    fi

    . ${tconfFile}

    . ${diyFuncFile}

    F_chkCfgFile

    return 0
}


function F_recordOnSucess()
{
    if [  $# -lt 2 ];then
        return 1
    fi
    local rcdFile="$1"
    local rcdContent="$2"  #"ip#busilist#/xinglongshan/up#0

    local upDate=$(date +%Y%m%d)

	#"ip#busilist#/xinglongshan/up"
	local fixStr=$(echo ${rcdContent}|cut -d '#' -f 1-3)

	#42.121.65.50#busilist#/xinglongshan/up#20210309
    local rcdResult="${fixStr}#${upDate}"

	#"ip#busilist#/xinglongshan/up#" 
    local fsearStr=$(echo "${fixStr}#"|sed 's=\*=\\*=g')

    if [ ! -e "${rcdFile}" ];then
        echo "${rcdResult}" >>"${rcdFile}"
        return 0
    fi

    #egrep -n "192.168.0.42#busilist#/xinglongshan/up#20210226" rcd.txt

    local tNum=0
    local LNo=0
    tNum=$(egrep -n "${fsearStr}" "${rcdFile}"|wc -l)
    while [ ${tNum} -gt 0 ]
    do
        LNo=$(egrep -n "${fsearStr}" "${rcdFile}"|head -1|awk -F':' '{print $1}')
        if [ ! -z "${LNo}" ];then
            sed -i "${LNo} d" "${rcdFile}"
        fi
        tNum=$(egrep -n "${fsearStr}" "${rcdFile}"|wc -l)
    done

    echo "${rcdResult}" >>"${rcdFile}"

    return 0
}


function F_judgeShouldDo() #return: 1 should do; 0 no shuld do
{
    if [  $# -lt 2 ];then
        return 0
    fi
    local rcdFile="$1"
    local rcdContent="$2"  #"ip#busilist#/xinglongshan/up#0

    if [ ! -e "${rcdFile}" ];then
        return 1
    fi

    local curDate=$(date +%Y%m%d)

	#"ip#busilist#/xinglongshan/up"
	local fixStr=$(echo ${rcdContent}|cut -d '#' -f 1-3)
    local fsearStr=$(echo "${fixStr}#"|sed 's=\*=\\*=g')


    #egrep -n "192.168.0.42#busilist#/xinglongshan/up#20210226" rcd.txt
	#
	# rcd.txt:
	#42.121.65.50#busilist#/xinglongshan/up#20210309

    local tNum=0
    local rcdDate=0
	local tmpStr
    tNum=$(egrep -n "${fsearStr}" "${rcdFile}"|wc -l)
    if [ ${tNum} -lt 1 ];then
        return 1
    else
		tmpStr=$(egrep -n "${fsearStr}" "${rcdFile}"|tail -1)
        rcdDate=$(echo "${tmpStr}"|cut -d '#' -f 4)
        if [ "${rcdDate}" != "${curDate}" ];then
            return 1
        fi
    fi

    return 0
}


function F_zipAttachFile()
{
	if [ $# -lt 2 ];then
		return 2
	fi

	local tzipDir="$1"
	local tfrmName="$2"
	local tzipName=""

    #echo "${FUNCNAME}:tzipDir=[${tzipDir}],tfrmName=[${tfrmName}]"

    [[ -z "${tzipDir}" || -z "${tfrmName}" ]] && return 1

    local tpwd="$(pwd)"

    ls -1 "${tzipDir}/${tfrmName}/"busi*.xml|awk -F'/' '{print $NF}'|cut -d'_' -f 2|sort -n >"${tmpFile}"
    local bgT=$(head -1 "${tmpFile}")
    local edT=$(tail -1 "${tmpFile}")

    tzipName="${tfrmName}${bgT}_${edT}busi.zip"

    cd "${tzipDir}"

    local tnum=0
    tnum=$(find ${tfrmName} -type f -print|wc -l)
    if [ ${tnum} -lt 1 ];then
        return 2
    fi

    #do some format user downlaoded file
    F_delDosCRCharinFile "${tfrmName}/busi*.xml"

    if [ ! -e "${tzipName}" ];then
        rm -rf "${tzipName}"
    fi

    zip -r "${tzipName}"  ${tfrmName}/*  >/dev/null 2>&1

    rm -rf ${tfrmName}/*

    cd "${tpwd}"

	return 0
}

function F_doDownBackOneSite()
{
    if [ $# -lt 9 ];then
        return 1
    fi

    local opFlag=0; local trsType=1; local trsMode=0; local ftpIP;
    local ftpUser; local ftpPwd; local ftpCtrPNum; local chkStr;
    local ftpLdir;
    local ftpLdirP;

    trsType="$1"         #0:ascii; 1:binary
    trsMode="$2"         #0:passive; 1:active
    ftpIP="$3"
    ftpUser="$4"
    ftpPwd="$5"
    ftpCtrPNum="$6"      #default 21
    chkStr="$7"          #chkStr="*.xml#/xinglongshan/up
    ftpLdirP="$8"
    local logFile="$9"

    ftpRdir=$(echo "${chkStr}"|cut -d '#' -f 2)
	local frmname=$(echo "${ftpRdir}"|awk -F'/' '{print $2}')
    local filePre=$(echo "${chkStr}"|cut -d '#' -f 1)
    local delFtpFile_flag="$(echo ${chkStr}|cut -d '#' -f 3)"

    ftpLdir="${ftpLdirP}/${frmname}"

    #busilist_20190114_0.xml
    fileName="busilist_$(date +%Y%m%d)_*.xml"

	F_clearFtpLDir "${ftpLdirP}" "${frmname}"
    
    local ftpRet; local ret;

    #check ftp server file status
    ftpRet=$(getFtpSerStatu "${opFlag}" "${trsType}" "${trsMode}" "${ftpIP}" "${ftpUser}" "${ftpPwd}" "${ftpRdir}" "${ftpLdir}" "${fileName}" "${ftpCtrPNum}")
    ret=$?
    F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getFtpSerStatu retturn[${ret}]"

    local outmsg
    local errFlag=1

   
    if [ ${ret} -eq 10 ];then #local path error
        outmsg="the local file path [${ftpLdir}] is error\n"
    elif [ ${ret} -eq 11 ];then
        outmsg="connet ftp server [${ftpIP} ${ftpCtrPNum}] is error\n"
    elif [ ${ret} -eq 12 ];then #wrong user name or password
        outmsg="the ftp username [${ftpUser}] or passwd [${ftpPwd}] is error\n"
    elif [ ${ret} -eq 13 ];then #remote path error
        outmsg="the file path [${ftpRdir}]is error\n"
    elif [ ${ret} -eq 14 ];then #file name does not exist
        outmsg="the file  [${fileName}] is not exists\n"
    else
        errFlag=0
    fi

    if [ ${errFlag} -eq 1 ];then
        #F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getFtpSerStatu outmsg[${outmsg}],ftpRet=[${ftpRet}]"
        F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getFtpSerStatu outmsg[${outmsg}]"
        return 3
    fi

    local tmpDoFile="${ftpLdir}/${fileName}"

	local tnum=0
    #delete old file
	tnum=$(ls -1 ${ftpLdir}/*.xml 2>/dev/null|wc -l)
    if [ ${tnum} -gt 0 ];then
        rm  -rf ${tmpDoFile}
    fi

    local bgOneDnT=$(date +%s)

    #downing file
    ftpRet=$(getOrPutFtpFile "${opFlag}" "${trsType}" "${trsMode}" "${ftpIP}" "${ftpUser}" "${ftpPwd}" "${ftpRdir}" "${ftpLdir}" "*.xml" "${ftpCtrPNum}")
    ret=$?
    local edOneDnT=$(date +%s)
    local diffT=$(echo "${edOneDnT} - ${bgOneDnT}"|bc)
    F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getOrPutFtpFile down retturn[${ret}]],delFtpFile_flag=[${delFtpFile_flag}], use [ ${diffT} ] seconds"

	tnum=$(ls -1 ${tmpDoFile} 2>/dev/null|wc -l)
    if [ ${tnum} -lt 1 ];then
        F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getOrPutFtpFile down retRet=[${ftpRet}]"
        return 4
    fi

    if [[ ${ret} -eq 0 && ! -z "${delFtpFile_flag}" && "${delFtpFile_flag}" = "1" ]];then
        delRet=$(delFtpSerFile "${opFlag}" "${trsType}" "${trsMode}" "${ftpIP}" "${ftpUser}" "${ftpPwd}" "${ftpRdir}" "${ftpLdir}" "*.xml" "${ftpCtrPNum}")
        delStat=$?
        local edDelT=$(date +%s)
        diffT=$(echo "${edDelT} - ${edOneDnT}"|bc)
        F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:delFtpSerFile ${ftpIP}:${ftpRdir}/*.xml retturn[${delStat}],use [ ${diffT} ] seconds"

    fi

    if [ ${ret} -eq 0 ];then
        local bgZipT=$(date +%s)
        #attach file
        F_zipAttachFile "${ftpLdirP}" "${frmname}" 
        ret=$?
        local edZipT=$(date +%s)
        diffT=$(echo "${edZipT} - ${bgZipT}"|bc)
        F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:F_zipAttachFile ${ftpLdirP} ${frmname} retturn[${ret}],use [ ${diffT} ] seconds"
    fi

    return ${ret}
}

function F_doDownBackAllSite()
{

    local i; local it; local tChkList; local rcdContent; local retstat;

    local bgScds1=$(date +%s)

    for ((i=0;i<${doNum};i++))
    do
        tChkList=$(F_convertVLineToSpace "${chkStr[$i]}")
        for it in ${tChkList}
        do
            #echo "i=$i it=[${it}]"

            rcdContent="${ftpip[$i]}#${it}"

            F_judgeShouldDo "${rcdFile}" "${rcdContent}" 
            retstat=$? #0 not; 1 shuld did
            if [ ${retstat} -eq 0 ];then
                F_outShDebugMsg ${logFile} 1 1 "F_judgeShouldDo [${rcdContent}] return[${retstat}],not should do !"
                continue
            fi

            local bgScds2=$(date +%s)
            F_doDownBackOneSite "${trsType[$i]}"  "${trsMode[$i]}" "${ftpip[$i]}" "${ftpuname[$i]}" "${ftpupwd[$i]}" "${ftpport[$i]}"  "${it}" "${ftpLdir}" "${logFile}"
            retstat=$? #0 sucess; !0 error
            if [ ${retstat} -eq 0 ];then
                local edScds2=$(date +%s)
                local difScds2=$(echo "${edScds2} - ${bgScds2}"|bc)
                F_outShDebugMsg ${logFile} 1 1 "${ftpip[$i]} ${rcdContent} down and zip total use [ ${difScds2} ] seconds !"
                F_recordOnSucess "${rcdFile}" "${rcdContent}"
            fi

        done
    done

    local edScds1=$(date +%s)
    local difScds1=$(echo "${edScds1} - ${bgScds1}"|bc)
    F_outShDebugMsg ${logFile} 1 1 "do all frm dir's file down and zip total use [ ${difScds1} ] seconds !"

    return 0
}

function main()
{
    local bgScds=$(date +%s)

    F_check

    F_outShDebugMsg ${logFile} 1 1 "$0 running beine:${begineTm}"
    #echo "haha doNum=[${doNum}]"

    F_doDownBackAllSite

    endTm="$(date +%Y-%m-%d_%H:%M:%S.%N)"
    local edScds=$(date +%s)
    local difScds=$(echo "${edScds} - ${bgScds}"|bc)

    F_outShDebugMsg ${logFile} 1 1 "$0 running end:${endTm}, [ ${difScds} ] seconds in total!"

    return 0
}

main

exit 0


