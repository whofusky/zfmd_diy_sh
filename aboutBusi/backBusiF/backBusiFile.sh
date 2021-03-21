#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20210225
#linux_version:    Red Hat Enterprise Linux Server release 6.7 
#dsc          :   
#    Download the business list from the corresponding directory on the 
#    configured ftp service, and upload it to the original location after 
#    some processing
#
#    (1) 根据cfg/cfg.cfg文件配置，用ftp脚本下载业务清单busilist_${YYYYMMDD}_0.xml
#    (2) 将下载的业务清单中DOS下的回车符去掉
#    (3) 将处理完的业务清单文件上传到原来下载的位置 
#        或者将业务清单打包成zip作为邮件的附件(根据post_do_flag的配置值决定对应
#        的动作）
#    (4) 给想关人员发送见邮件
#limit
#    (1) 相同服务器相同路径下的业务清单同一天根据配置只处理一次(如果配置的是2次则
#        同一天在相应时间点各处理一次），如果已经处理过一次第二次
#        调用脚本将根据tmp/rcd.txt文件的记录决定是否需要重新下载
#    (2) 只有当有上传成功或成功处理格式且要求发送业务清单文件作为附件发送的情况才发邮件，
#        其它情况不发邮件
#    (3) 当需要把业务清单作为附件邮件发送时，最终会有2个邮件：
#        第一个：发送附件
#        第二个：发送总的统计情况
#        这两处发送邮件地方在配置文件中不同的位置进行配置
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


