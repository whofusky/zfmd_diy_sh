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
#        或者将业务清单打包成zip作为邮件的附件或者只将业务清单
#        cp到本地的某些目录(根据post_do_flag的配置值决定对应
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

debugFlagM=1            
#debugFlagM=3            
#debugFlagM=255            
                          

thisShName="$0"
onlyShName=${thisShName##*/}
onlyShPre=${onlyShName%.*}

#加载系统环境变量配置
if [ -f /etc/profile ]; then
    . /etc/profile >/dev/null 2>&1
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile >/dev/null 2>&1
fi

#已经有脚本在运行则退出
tmpShPid=$(pidof -x ${onlyShName})
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
logFile="${logDir}/${inNPre}$(date +%Y%m%d).log"

tmpDir="${baseDir}/tmp"
ftpLdir="${tmpDir}"
smailFile="${tmpDir}/smail.txt"
smailattFile="${tmpDir}/smailatt.txt"
rcdFile="${tmpDir}/rcd.txt"

tposDir="${tmpDir}/post"
tattFile="attachment.zip"
tposAttach="${tposDir}/${tattFile}"

doNum=0


#mail
headCnt=""
headattCnt=""
tailCnt=""
sdmailTitle=""

function F_genMailFixCnt()
{

	headattCnt="

To whom it may concern:

   	Time $(date +%Y-%m-%d_%H:%M:%S), the business list file is 
  formatted and processed, and the file is in the attachment."

	headCnt="

To whom it may concern:

   	Time $(date +%Y-%m-%d_%H:%M:%S), the results of the successful 
  formatting of the business list file are as follows: "

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
	if [ $# -lt 2 ];then
		return 1
	fi
	local tType="$1"
	local tmailF="$2"

	if [[ ! -z "${tType}" && "${tType}" = "1" ]];then
		echo "${headattCnt}">${tmailF}
	else
		echo "${headCnt}">${tmailF}
	fi
	return 0
}


function F_mailFileTail()
{
	if [ $# -lt 1 ];then
		return 1
	fi
	local tmailF="$1"

	echo "${tailCnt}">>${tmailF}
	return 0
}

function F_mailFileCnt()
{
	if [ $# -lt 2 ];then
		return 0
	fi
	local level="$1"
	local tmailF="$2"


	if [ "${level}" = "0" ];then
		echo "">>${tmailF}
		return 0
	fi

	if [ $# -lt 2 ];then
		return 0
	fi

	local inStr="$3"

	if [ "${level}" = "1" ];then
		echo "  ${inStr}">>${tmailF}
	elif [ "${level}" = "2" ];then
		echo "    ${inStr}">>${tmailF}
	elif [ "${level}" = "3" ];then
		echo "      ${inStr}">>${tmailF}
	elif [ "${level}" = "4" ];then
		echo "        ${inStr}">>${tmailF}
	fi

	return 0
}


function F_cpBuFToAttsub() # copy business list file to ataachement sub dir
{
	if [ $# -lt 3 ];then
		return 1
	fi

	local tftpLdir="$1"
	local ttatadir="$2"
	local filename="$3"
	local ret=0

	local tsrcFile="${tftpLdir}/${filename}"

	local tnum=0
	tnum=$(ls -1 ${tsrcFile} 2>/dev/null|wc -l)
	if [ ${tnum} -lt 1 ];then
		return 2
	fi

	[ ! -d "${ttatadir}" ] &&  mkdir -p "${ttatadir}"
	cp -a  ${tsrcFile} "${ttatadir}"
	ret=$?
	return ${ret}
}

function F_cpBuFToLocalDir() # copy business list file to local target dir
{
    if [ -z "${cp_dst_local_dirS}" ];then
        return 0
    fi

	if [ $# -lt 2 ];then
		return 1
	fi

	local tSrcDir="$1"
	local filename="$2"

	local tsrcFile="${tSrcDir}/${filename}"

	local tnum=0; local it; local tDstDirS;

	tnum=$(ls -1 ${tsrcFile} 2>/dev/null|wc -l)
	if [ ${tnum} -lt 1 ];then
		return 2
	fi
    

    tDstDirS=$(F_convertVLineToSpace "${cp_dst_local_dirS}")
    for it in ${tDstDirS}
    do
        [ ! -d "${it}" ] &&  mkdir -p "${it}"
        cp -a  ${tsrcFile} "${it}"
        F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:cp -a ${tsrcFile} ${it}"
    done

	return 0
}

function F_zipAttachFile()
{
	if [ $# -lt 3 ];then
		return 2
	fi
	if [ -z "${post_do_flag}" ];then
		return 0
	fi

	local tzipDir="$1"
	local tfrmName="$2"
	local tzipName="$3"

	if [[ ${post_do_flag} -eq 1 || ${post_do_flag} -eq 2 ]];then
		if [ ! -d "${tzipDir}" ];then
			return 1
		fi

		local tpwd="$(pwd)"
		cd "${tzipDir}"
		if [ ! -e "${tzipName}" ];then
			rm -rf "${tzipName}"
		fi
		local tnum=0
		tnum=$(find ${tfrmName} -type f -print|wc -l)
		if [ ${tnum} -lt 1 ];then
			return 2
		fi

		zip -r "${tzipName}"  ${tfrmName}  >/dev/null 2>&1
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
    chkStr="$7"          #chkStr="busilist#/xinglongshan/up#0#20210309-20210310#6,13#xlsfdc@163.com"
    ftpLdir="$8"
    local logFile="$9"

    ftpRdir=$(echo "${chkStr}"|cut -d '#' -f 2)
    local filePre=$(echo "${chkStr}"|cut -d '#' -f 1)

    #busilist_20190114_0.xml
    fileName="${filePre}_$(date +%Y%m%d)_*.xml"

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
	tnum=$(ls -1 ${tmpDoFile} 2>/dev/null|wc -l)
    if [ ${tnum} -gt 0 ];then
        rm  -rf ${tmpDoFile}
    fi

    #downing file
    ftpRet=$(getOrPutFtpFile "${opFlag}" "${trsType}" "${trsMode}" "${ftpIP}" "${ftpUser}" "${ftpPwd}" "${ftpRdir}" "${ftpLdir}" "${fileName}" "${ftpCtrPNum}")
    ret=$?
    F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getOrPutFtpFile down retturn[${ret}]]"

	tnum=$(ls -1 ${tmpDoFile} 2>/dev/null|wc -l)
    if [ ${tnum} -lt 1 ];then
        F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getOrPutFtpFile down retRet=[${frpRet}]"
        return 4
    fi


    #do some format user downlaoded file
    F_delDosCRCharinFile "${tmpDoFile}"



	local frmname=$(echo "${ftpRdir}"|awk -F'/' '{print $2}')
	local tCpDst="${tposDir}/${frmname}"
	local tzipName="${frmname}$(date +%Y%m%d_%H).zip"
	local tzipDir="${tposDir}"
	local tataFile="${tzipDir}/${tzipName}"

    #copy busi file to lcoal dst dir
    F_cpBuFToLocalDir "${ftpLdir}"  "${fileName}"
    ret=$?
    F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:F_cpBuFToLocalDir ${ftpLdir} ${fileName} retturn[${ret}]"

	#copy to attachment dir and send email
	if [[ ${post_do_flag} -eq 1 || ${post_do_flag} -eq 2 ]];then
		F_cpBuFToAttsub "${ftpLdir}" "${tCpDst}" "${fileName}"
		ret=$?
		F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:F_cpBuFToAttsub ${ftpLdir} ${tCpDst} ${fileName} retturn[${ret}]"

		#zip attach busilist file and send mail
		if [ ${ret} -eq 0 ];then 

			#attach file
			F_zipAttachFile "${tzipDir}" "${frmname}" "${tzipName}"
			ret=$?

			local tmailTitle="busi_${frmname}$(date +%Y%m%d_%H%M%S)"
			#chkStr="busilist#/xinglongshan/up#0#20210309-20210310#6,13#xlsfdc@163.com"
			local tmailAddr="$(echo ${chkStr}|cut -d '#' -f 6)"
			local delFtpFile_flag="$(echo ${chkStr}|cut -d '#' -f 3)"
			tmailAddr="1#${tmailAddr}"

			F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:F_zipAttachFile ${tzipDir} ${frmname} ${tzipName} retturn[${ret}],tmailAddr=[${tmailAddr}]"
			#send mail
			if [[ ${ret} -eq 0 && ! -z "${tmailAddr}" ]];then
				F_mailFileHead 1 ${smailattFile}
				F_mailFileTail ${smailattFile}
				F_sendMail "${tmailTitle}" "${smailattFile}" "${tataFile}" "${tmailAddr}" "${logFile}"
				ret=$?
				F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:F_sendMail retturn[${ret}],delFtpFile_flag=[${delFtpFile_flag}]"

				local delRet
				local delStat
				#delete ftp file delFtpSerFile
				if [[ ${ret} -eq 0 && ! -z "${delFtpFile_flag}" && "${delFtpFile_flag}" = "1" ]];then
					delRet=$(delFtpSerFile "${opFlag}" "${trsType}" "${trsMode}" "${ftpIP}" "${ftpUser}" "${ftpPwd}" "${ftpRdir}" "${ftpLdir}" "${fileName}" "${ftpCtrPNum}")
					delStat=$?
					F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:delFtpSerFile ${ftpIP}:${ftpRdir}/${fileName} retturn[${delStat}]"

				fi
			fi

		fi
	fi

	#upload new file
	if [[ ${post_do_flag} -eq 0 || ${post_do_flag} -eq 2 ]];then
		opFlag=1 #0:download, 1:upload
		ftpRet=$(getOrPutFtpFile "${opFlag}" "${trsType}" "${trsMode}" "${ftpIP}" "${ftpUser}" "${ftpPwd}" "${ftpRdir}" "${ftpLdir}" "${fileName}" "${ftpCtrPNum}")
		ret=$?
		F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:getOrPutFtpFile up retturn[${ret}],retRet=[${frpRet}]"
	fi

	if [ ${ret} -eq 0 ];then
		F_mailFileCnt 0 ${smailFile}
		F_mailFileCnt 2 ${smailFile} "ip[${ftpIP}]:file[ ${ftpRdir}/${fileName} ]"
	fi

    return ${ret}
}

function F_recordOnSucess()
{
    if [  $# -lt 2 ];then
        return 1
    fi
    local rcdFile="$1"
    local rcdContent="$2"  #"ip#busilist#/xinglongshan/up#0#20210309-20210310#6,13#xlsfdc@163.com"

    local upDate=$(date +%Y%m%d)
	local curHour="$(date +%H)"

	#"ip#busilist#/xinglongshan/up"
	local fixStr=$(echo ${rcdContent}|cut -d '#' -f 1-3)

	#42.121.65.50#busilist#/xinglongshan/up#20210309#14
    local rcdResult="${fixStr}#${upDate}#${curHour}"

	#"ip#busilist#/xinglongshan/up#" 
    local fsearStr="${fixStr}#"

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
    local rcdContent="$2"  #"ip#busilist#/xinglongshan/up#0#20210309-20210310#6,13#xlsfdc@163.com"


    local curDate=$(date +%Y%m%d)
    local curHour=$(date +%H)

	#"ip#busilist#/xinglongshan/up"
	local fixStr=$(echo ${rcdContent}|cut -d '#' -f 1-3)
    local fsearStr="${fixStr}#"

	#6,13 ->6 13
	local fixHours=$(echo ${rcdContent}|cut -d '#' -f 6|sed 's/,/ /g' )

	#20210309
	local fixBgDate=$(echo ${rcdContent}|cut -d '#' -f 5|cut -d '-' -f 1)
	#20210310
	local fixEdDate=$(echo ${rcdContent}|cut -d '#' -f 5|cut -d '-' -f 2)

	local rightFlag=0
	rightFlag=$(echo "${curDate}>=${fixBgDate} && ${curDate}<=${fixEdDate}"|bc)

	#not within the configured time range
	if [ ${rightFlag} -eq 0 ];then
		return 0
	fi

	local maybe_flag=0
	local i
	if [[ ! -z "${fixHours}" ]];then
		for i in ${fixHours}
		do
			rightFlag=$(echo "${curHour}>=${i}"|bc)
			if [ ${rightFlag} -eq 1 ];then
				maybe_flag=1
				break;
			fi
		done

		#not within the configured hours
		if [ ${maybe_flag} -eq 0 ];then
			return 0
		fi
	fi


    if [ ! -e "${rcdFile}" ];then
        return 1
    fi

    #egrep -n "192.168.0.42#busilist#/xinglongshan/up#20210226" rcd.txt
	#
	# rcd.txt:
	#42.121.65.50#busilist#/xinglongshan/up#20210309#14

    local tNum=0
    local rcdDate=0
	local rcdHour=0
	local tmpStr
    tNum=$(egrep -n "${fsearStr}" "${rcdFile}"|wc -l)
    if [ ${tNum} -lt 1 ];then
        return 1
    else
		tmpStr=$(egrep -n "${fsearStr}" "${rcdFile}"|tail -1)
        rcdDate=$(echo "${tmpStr}"|cut -d '#' -f 4)
        rcdHour=$(echo "${tmpStr}"|cut -d '#' -f 5)
        if [ "${rcdDate}" != "${curDate}" ];then
            return 1
        fi

		for i in ${fixHours}
		do
			rightFlag=$(echo "${curHour}>=${i} && ${rcdHour}<${i}"|bc)
			if [ ${rightFlag} -eq 1 ];then
				return 1
			fi
		done
    fi

    return 0
}


function main()
{
    local bgScds=$(date +%s)

    F_chkDir

    . ${tconfFile}

    . ${diyFuncFile}

    F_outShDebugMsg ${logFile} ${debugFlagM} 2 "$0 running beine:${begineTm}"

    F_chkCfgFile

	F_genMailFixCnt
	F_mailFileHead 0 ${smailFile}

    #echo "haha doNum=[${doNum}]"

    local i; local it; local tChkList; local rcdContent; local retstat;
    local sedMailFlag=0; local outDebugFlag=0;

	F_clearAttachDir

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
                F_outShDebugMsg ${logFile} ${debugFlagM} 2 "F_judgeShouldDo [${rcdContent}] return[${retstat}],not should do !"
                continue
            fi

            outDebugFlag=1

            F_doFormatOneSite "${trsType[$i]}"  "${trsMode[$i]}" "${ftpip[$i]}" "${ftpuname[$i]}" "${ftpupwd[$i]}" "${ftpport[$i]}"  "${it}" "${ftpLdir}" "${logFile}"
            retstat=$? #0 sucess; !0 error
            if [ ${retstat} -eq 0 ];then
                F_recordOnSucess "${rcdFile}" "${rcdContent}"
                if [[ ! -z "${post_do_flag}" && "${post_do_flag}x" != "3x" ]];then
                    sedMailFlag=1
                fi
            fi

        done
    done


    if [ ${sedMailFlag} -eq 1 ];then
		#F_zipAttachFile

		F_mailFileCnt 0 ${smailFile}
		F_mailFileCnt 0 ${smailFile}
		F_mailFileTail ${smailFile}
        #F_sendMail "${sdmailTitle}" "${smailFile}" "${attachFile}" "${rMailAddr[0]}" "${logFile}"
        F_sendMail "${sdmailTitle}" "${smailFile}" "" "${rMailAddr}" "${logFile}"
    fi

    endTm="$(date +%Y-%m-%d_%H:%M:%S.%N)"
    local edScds=$(date +%s)
    local difScds=$(echo "${edScds} - ${bgScds}"|bc)

    if [ ${outDebugFlag} -eq 1 ];then
        F_outShDebugMsg ${logFile} 1 1 "$0 running end:${endTm}, [ ${difScds} ] seconds in total!"
    fi

    return 0
}

main

exit 0


