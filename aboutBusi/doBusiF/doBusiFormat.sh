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
#    (1) 相同服务器相同路径下的业务清单一天只处理一次，如果已经处理过一次第二次
#        调用脚本将根据tmp/rcd.txt文件的记录决定是否需要重新下载
#    (2) 只有当有上传成功的情况才发邮件，其它情况不发邮件
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

diyFuncFile=${baseDir}/doBFFunc.sh
tconfFile="${baseDir}/cfg/cfg.cfg"

logDir="${baseDir}/log"
logFile="${logDir}/${inNPre}.log"

tmpDir="${baseDir}/tmp"
ftpLdir="${tmpDir}"
smailFile="${tmpDir}/smail.txt"
rcdFile="${tmpDir}/rcd.txt"

tposDir="${tmpDir}/post"
tattFile="attachment.zip"
tposAttach="${tposDir}/${tattFile}"

doNum=0


#mail
headCnt=""
tailCnt=""
sdmailTitle=""

function F_genMailFixCnt()
{

	headCnt="

To whom it may concern:

   	Date $(date +%Y-%m-%d), the results of the successful formatting 
  of the business list file are as follows: "

	tailCnt="  

Wishing your business ever successful !
$(whoami)
$(date +%y-%m-%d_%H:%M:%S.%N)

	"

	sdmailTitle="[$(date +%Y%m%d)_$$]format business report"

	return 0
}

function F_mailFileHead()
{
	echo "${headCnt}">${smailFile}
	return 0
}


function F_mailFileTail()
{
	echo "${tailCnt}">>${smailFile}
	return 0
}

function F_mailFileCnt()
{
	if [ $# -lt 1 ];then
		return 0
	fi

	local level="$1"

	if [ "${level}" = "0" ];then
		echo "">>${smailFile}
		return 0
	fi

	if [ $# -lt 2 ];then
		return 0
	fi

	local inStr="$2"

	if [ "${level}" = "1" ];then
		echo "  ${inStr}">>${smailFile}
	elif [ "${level}" = "2" ];then
		echo "    ${inStr}">>${smailFile}
	elif [ "${level}" = "3" ];then
		echo "      ${inStr}">>${smailFile}
	elif [ "${level}" = "4" ];then
		echo "        ${inStr}">>${smailFile}
	fi

	return 0
}


function F_cpBuFToAttsub() # copy business list file to ataachement sub dir
{
	if [ $# -lt 2 ];then
		return 1
	fi

	local ftpRdir="$1"
	local filename="$2"
	local ret=0

	local frmname=$(echo "${ftpRdir}"|awk -F'/' '{print $2}')
	local ttatadir="${tposDir}/${frmname}"
	[ ! -d "${ttatadir}" ] &&  mkdir -p "${ttatadir}"
	cp -a "${ftpLdir}/${fileName}" "${ttatadir}"
	ret=$?
	return ${ret}
}

function F_zipAttachFile()
{
	if [ -z "${post_do_flag}" ];then
		return 0
	fi

	if [[ ${post_do_flag} -eq 1 || ${post_do_flag} -eq 2 ]];then
		if [ ! -d "${tposDir}" ];then
			return 1
		fi

		if [ ! -e "${tattFile}" ];then
			rm -rf "${tattFile}"
		fi
		local tnum=0
		local tpwd="$(pwd)"
		cd "${tposDir}"
		tnum=$(find . -type f -print|wc -l)
		if [ ${tnum} -lt 1 ];then
			return 2
		fi

		zip -r "${tattFile}"  *  >/dev/null 2>&1
		cd "${tpwd}"
	else
		return 0
	fi


	return 0
}

function F_clearAttachDir()
{
	if [ -z "${post_do_flag}" ];then
		return 0
	fi

	if [[ ${post_do_flag} -eq 1 || ${post_do_flag} -eq 2 ]];then
		rm -rf "${tposDir}"/*
	fi
	return 0
}


function F_chkDir()
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


    if [ ! -d "${tposDir}" ];then
        mkdir -p "${tposDir}"
    fi

    return 0
}

function F_chkCfgFile()
{
    #echo "doNum=[${doNum}]"
    doNum=${#ftpip[*]}
    if [ ${doNum} -lt 1 ];then
        exit 0
    fi


    if [ -z "${rMailAddr}" ];then
        F_outShDebugMsg ${logFile} 1 1 "ERROR:There is no configuration variable [rMailAddr] in file [${tconfFile}]!"
        exit 1
    fi

    if [ -z "${post_do_flag}" ];then
        F_outShDebugMsg ${logFile} 1 1 "ERROR:There is no configuration variable [post_do_flag] in file [${tconfFile}]!"
        exit 1
    fi

    return 0
}

function F_doFormatOneSite()
{
    if [ $# -lt 9 ];then
        return 1
    fi

    local opFlag=0; local trsType=1; local trsMode=0; local ftpIP;
    local ftpUser; local ftpPwd; local ftpCtrPNum; local chkStr;
    local ftpLdir;

    trsType="$1"         #0:ascii; 1:binary
    trsMode="$2"         #0:passive; 1:active
    ftpIP="$3"
    ftpUser="$4"
    ftpPwd="$5"
    ftpCtrPNum="$6"      #default 21
    chkStr="$7"          #chkStr="busilist#/xinglongshan/up"
    ftpLdir="$8"
    local logFile="$9"

    ftpRdir=$(echo "${chkStr}"|cut -d '#' -f 2)
    local filePre=$(echo "${chkStr}"|cut -d '#' -f 1)

    #busilist_20190114_0.xml
    fileName="${filePre}_$(date +%Y%m%d)_0.xml"

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
        F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getFtpSerStatu outmsg[${outmsg}],ftpRet=[${ftpRet}]"
        return 3
    fi

    local tmpDoFile="${ftpLdir}/${fileName}"

    #delete old file
    if [ -e "${tmpDoFile}" ];then
        rm  -rf "${tmpDoFile}"
    fi

    #downing file
    ftpRet=$(getOrPutFtpFile "${opFlag}" "${trsType}" "${trsMode}" "${ftpIP}" "${ftpUser}" "${ftpPwd}" "${ftpRdir}" "${ftpLdir}" "${fileName}" "${ftpCtrPNum}")
    ret=$?
    F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getOrPutFtpFile down retturn[${ret}]]"

    if [ ! -e "${tmpDoFile}" ];then
        F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getOrPutFtpFile down retRet=[${frpRet}]"
        return 4
    fi


    #do some format user downlaoded file
    F_delDosCRCharinFile "${tmpDoFile}"



	#copy to attachment dir
	if [[ ${post_do_flag} -eq 1 || ${post_do_flag} -eq 2 ]];then
		F_cpBuFToAttsub "${ftpRdir}" "${fileName}"
		ret=$?
		F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:F_cpBuFToAttsub ${ftpRdir} ${fileName} retturn[${ret}]"
	fi

	#upload new file
	if [[ ${post_do_flag} -eq 0 || ${post_do_flag} -eq 2 ]];then
		opFlag=1 #0:download, 1:upload
		ftpRet=$(getOrPutFtpFile "${opFlag}" "${trsType}" "${trsMode}" "${ftpIP}" "${ftpUser}" "${ftpPwd}" "${ftpRdir}" "${ftpLdir}" "${fileName}" "${ftpCtrPNum}")
		ret=$?
		F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getOrPutFtpFile up retturn[${ret}],retRet=[${frpRet}]"
	fi

	if [ ${ret} -eq 0 ];then
		F_mailFileCnt 0
		F_mailFileCnt 2 "ip[${ftpIP}]:file[ ${ftpRdir}/${fileName} ]"
	fi

    return ${ret}
}

function F_recordOnSucess()
{
    if [  $# -lt 2 ];then
        return 1
    fi
    local rcdFile="$1"
    local rcdContent="$2"  #"ip#busilist#/xinglongshan/up

    local upDate=$(date +%Y%m%d)
    local rcdResult="${rcdContent}#${upDate}"
    local fsearStr="${rcdContent}#"

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


function F_judgeTodayHav() #return: 0 not; 1 have
{
    if [  $# -lt 2 ];then
        return 0
    fi
    local rcdFile="$1"
    local rcdContent="$2"  #"ip#busilist#/xinglongshan/up

    if [ ! -e "${rcdFile}" ];then
        return 0
    fi

    local curDate=$(date +%Y%m%d)
    local fsearStr="${rcdContent}#"

    #egrep -n "192.168.0.42#busilist#/xinglongshan/up#20210226" rcd.txt

    local tNum=0
    local filedate=0
    tNum=$(egrep -n "${fsearStr}" "${rcdFile}"|wc -l)
    if [ ${tNum} -lt 1 ];then
        return 0
    else
        filedate=$(egrep -n "${fsearStr}" "${rcdFile}"|tail -1|cut -d '#' -f 4)
        if [ "${filedate}" != "${curDate}" ];then
            return 0
        fi
    fi

    return 1
}

function main()
{
    local bgScds=$(date +%s)

    F_chkDir

    . ${tconfFile}

    . ${diyFuncFile}

    F_outShDebugMsg ${logFile} 1 1 "$0 running beine:${begineTm}"

    F_chkCfgFile

	F_genMailFixCnt
	F_mailFileHead

    #echo "haha doNum=[${doNum}]"

    local i; local it; local tChkList; local rcdContent; local retstat;
    local sedMailFlag=0

	F_clearAttachDir

    for ((i=0;i<${doNum};i++))
    do
        tChkList=$(F_convertVLineToSpace "${chkStr[$i]}")
        for it in ${tChkList}
        do
            #echo "i=$i it=[${it}]"

            rcdContent="${ftpip[$i]}#${it}"

            F_judgeTodayHav "${rcdFile}" "${rcdContent}" 
            retstat=$? #0 not; 1 have did
            if [ ${retstat} -eq 1 ];then
                F_outShDebugMsg ${logFile} 1 1 "[${rcdContent}] have did today,not need to start again!!"
                continue
            fi

            F_doFormatOneSite "${trsType[$i]}"  "${trsMode[$i]}" "${ftpip[$i]}" "${ftpuname[$i]}" "${ftpupwd[$i]}" "${ftpport[$i]}"  "${it}" "${ftpLdir}" "${logFile}"
            retstat=$? #0 sucess; !0 error
            if [ ${retstat} -eq 0 ];then
                F_recordOnSucess "${rcdFile}" "${rcdContent}"
                sedMailFlag=1
            fi

        done
    done


    if [ ${sedMailFlag} -eq 1 ];then
		F_zipAttachFile

		F_mailFileCnt 0
		F_mailFileCnt 0
		F_mailFileTail
        #F_sendMail "${sdmailTitle}" "${smailFile}" "${attachFile}" "${rMailAddr[0]}" "${logFile}"
        F_sendMail "${sdmailTitle}" "${smailFile}" "${tposAttach}" "${rMailAddr}" "${logFile}"
    fi

    endTm="$(date +%Y-%m-%d_%H:%M:%S.%N)"
    local edScds=$(date +%s)
    local difScds=$(echo "${edScds} - ${bgScds}"|bc)

    F_outShDebugMsg ${logFile} 1 1 "$0 running end:${endTm}, [ ${difScds} ] seconds in total!"

    return 0
}

main

exit 0


