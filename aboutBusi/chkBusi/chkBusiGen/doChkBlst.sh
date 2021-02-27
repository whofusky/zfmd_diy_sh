#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20191208
#linux_version:    Red Hat Enterprise Linux Server release 6.7 
#dsc          :   
#    Check the configuration file (cfg / chkB.cfg) whether 
#       there is a corresponding file in the corresponding 
#       directory on the ftp server
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
tconfFile="${baseDir}/cfg/chkB.cfg"
logDir="${baseDir}/log"
logFile="${logDir}/${inNPre}.log"
tmpDir="${baseDir}/tmp"
tmpFile="${tmpDir}/tmp.txt"
smailFilePre="${tmpDir}/smailpre.txt"
tFtpBuList="${tmpDir}/tmpBusList.txt"
smailFile="${tmpDir}/smail.txt"
recordDtFile="${tmpDir}/doDate.txt"
attachFile="${tmpDir}/attachment.txt"
tmpwinmemf="${tmpDir}/cmptMem.txt"

if [ ! -e "${tconfFile}" ];then
    echo -e "\n\t\e[1;31mError,in [$0]\e[0m: File [ ${cfgFile} ] does not exist!!\n"
    exit 9
fi
. ${tconfFile}

if [ ! -d "${logDir}" ];then
    mkdir -p "${logDir}"
fi

if [ ! -d "${tmpDir}" ];then
    mkdir -p "${tmpDir}"
fi


#echo "doNum=[${doNum}]"
doNum=${#ftpip[*]}
if [ ${doNum} -lt 1 ];then
    exit 0
fi


function F_convertVLineToSpace() #Convert vertical lines to spaces
{

    if [ $# -lt 1 ];then
        echo ""
        return 0
    fi

    echo $(echo "$1"|tr -d "[\040\t\r\n]"|tr -s "|" "\040")
    return 0
}


function getPathOnFname() #get the path value in the path string(the path does not have / at the end)
{

    if [ $# -ne 1 ];then
        echo "  Error: function getPathOnFname input parameters not eq 1!"
        return 1
    fi

    if [  -z "$1" ];then
        echo "  Error: function getPathOnFname input parameters is null!"
        return 2
    fi
    
    local dirStr=$(echo "$1"|awk -F'/' '{for(i=1;i<NF;i++){printf "%s/",$i}}'|sed 's/\/$//g')
    if [ -z "${dirStr}" ];then
        dirStr="."
    fi

    echo "${dirStr}"
    return 0
}

function F_outShDebugMsg() #out put $4 to $1; use like: F_outShDebugMsg $logfile $cfgdebug $valdebug $putcontent $clearflag
{
    if [ $# -ne 4 -a $# -ne 5 ];then
        echo "  Error: function F_outShDebugMsg input parameters not eq 4 or 5 !"
        return 1
    fi

    local inum=$#
    local logFile="$1"
    local cfgDebugFlag="$2"
    local valDebugFlag="$3"
    local puttxt="$4"
    
    local tcheck=$(echo "${cfgDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && cfgDebugFlag=0
    tcheck=$(echo "${valDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && valDebugFlag=0

    if [ $((${cfgDebugFlag}&${valDebugFlag})) -ne ${valDebugFlag} ];then
        return 0
    fi
    
    #output content to standard output device if the log file name is empty
    if [ -z "${logFile}" ];then
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}"
        return 0
    fi

    local tmpdir=$(getPathOnFname "${logFile}")
    local ret=$?
    [ ${ret} -ne 0 ] && echo "${tmpdir}" && return ${ret}

    if [ ! -d "${tmpdir}" ];then
        echo "  Error: dirname [${tmpdir}] not exist!"
        return 2
    fi

    local clearFlag=0
    [ ${inum} -eq 5 ] && clearFlag=$5
    tcheck=$(echo "${clearFlag}"|sed -n "/^[0-9]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && clearFlag=0
    [ ${clearFlag} -eq 1 ] && >"${logFile}"
    
    if [ ${clearFlag} -eq 2 ];then
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}"|tee -a "${logFile}"
    else
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}">>"${logFile}"
    fi
    
    return 0
}

function F_formatFtpBusCnt() #format ftp server's status business file content
{
	if [ $# -ne 2 ];then
		return 1
	fi
	local preDoFile="$1"
	local outputFile="$2"

	sed -n '/\(\btdir1\b\|\bup\b\|busilist_\)/p' ${preDoFile} |sed 's/^\s*250\s*Directory\s*changed\s*to\s*//g'|sed '/tdir/ i\\n'|sed 's/^/  /g'>>${outputFile}

	return 0
}


function F_judgeDoit() #judge do it 
{
    local thFname="F_judgeDoit"
    local tfInParNum=4
    if [ $# -ne ${tfInParNum} ];then
        return 0
    fi
    
    local debugflag=${debugFlagM}
    local ret=0

    local tJudgeFile="$1"
    local tsmailFile="$2"
    local tcfgstr="$3"
    local logFile="$4"

    local tCurNum=0
    local tFixNum=0

    local tdebugVal=2

    if [ ! -e "${tsmailFile}" ];then
        F_outShDebugMsg "${logFile}" ${debugflag} ${tdebugVal} "${thFname}:[${tsmailFile}] not exist!"
        return 1
    fi

    local tDate="$(date +%Y%m%d)"
    local tsftmtamp="$(stat -c %Y ${tsmailFile})"
    local tCurDaytamp="$(date -d $(date +%Y%m%d) +%s)"

    local crossDFlag=$(echo "${tCurDaytamp} - ${tsftmtamp} >0"|bc)
    if [ ${crossDFlag} -eq 1 ];then
        F_outShDebugMsg "${logFile}" ${debugflag} ${tdebugVal} "${thFname}:[${tsmailFile}] is not today's file!"
        echo "${tDate}">"${tJudgeFile}"
        return 1
    fi

    if [ ! -e "${tJudgeFile}" ];then
        F_outShDebugMsg "${logFile}" ${debugflag} ${tdebugVal} "${thFname}:[${tJudgeFile}] not exist!"
        echo "${tDate}">"${tJudgeFile}"
        return 1
    fi
    
    local tnum=$(egrep "^$|\s+" "${tJudgeFile}"|wc -l)
    if [ ${tnum} -gt 0 ];then
        sed -i -e 's/\s\+//g;/^$/d' "${tJudgeFile}"
    fi
    local fileDate=$(egrep "^[0-9]+$" "${tJudgeFile}")
    if [ -z "${fileDate}" ];then
        echo "${tDate}">"${tJudgeFile}"
        F_outShDebugMsg "${logFile}" ${debugflag} ${tdebugVal} "${thFname}:fileDate is null!"
        return 1
    else
        tnum=$(echo "${fileDate}"|wc -l)
        if [ ${tnum} -ne 1 ];then
            echo "${tDate}">"${tJudgeFile}"
            F_outShDebugMsg "${logFile}" ${debugflag} ${tdebugVal} "${thFname}:fileDate line num=[${tnum}]!"
            return 1
        fi
    fi
    
    if [ "${tDate}" != "${fileDate}" ];then
        echo "${tDate}">"${tJudgeFile}"
        F_outShDebugMsg "${logFile}" ${debugflag} ${tdebugVal} "${thFname}:${tDate}!=${fileDate}"
        return 1
    fi

    local tcfgstrList=$(F_convertVLineToSpace "${tcfgstr}")
    local it
    local sfname
    local sfnum=0
    for it in ${tcfgstrList}
    do
        sfname=$(echo "${it}"|cut -d '#' -f 1)
        sfnum=$(echo "${it}"|cut -d '#' -f 2)
        tnum=$(grep -A 2 "/up" "${tsmailFile}"|sed -n "/${sfname}/p" |wc -l)
        if [ ${tnum} -ne ${sfnum} ];then
            F_outShDebugMsg "${logFile}" ${debugflag} ${tdebugVal} "${thFname}:sfnum=[${sfnum}],tnum=[${tnum}]"
            return 1
        fi
    done

    F_outShDebugMsg "${logFile}" ${debugflag} ${tdebugVal} "${thFname}:end return 0"

    return 0
}


function F_genAttach() #generate attachment file
{
    local thFname="F_genAttach"

    #local tfInParNum=2
    #if [ $# -ne ${tfInParNum} ];then
    #    return 1
    #fi

    #local tJudgeFile="$1"
    #local tsmailFile="$2"
    #local tcfgstr="$3"
    #local logFile="$4"
    
    local debugflag=${debugFlagM}
    local ret=0
    local tdebugVal=2

    if [[ -z "${atSrcDir}" || -z "${atSrcFilePre}" ]];then
        F_outShDebugMsg "${logFile}" ${debugflag} ${tdebugVal} "${thFname}:[${tconfFile}] not config atSrcDir or atSrcFilePre !"
		return 1
    fi

	if [ ! -d "${atSrcDir}" ];then
        F_outShDebugMsg "${logFile}" ${debugflag} ${tdebugVal} "${thFname}:dir [${atSrcDir}] not exist!"
		return 1
    fi

	local tdFile=$(ls -r1 ${atSrcDir}/${atSrcFilePre}* 2>/dev/null|head -1)
	if [ -z "${tdFile}" ];then
        F_outShDebugMsg "${logFile}" ${debugflag} ${tdebugVal} "${thFname}:file [${atSrcDir}/${atSrcFilePre}*] not exist!"
		return 1
    fi


	echo " log file=[${tdFile}]" >${attachFile}
	echo " beine:$(date +%y-%m-%d_%H:%M:%S.%N)" >>${attachFile}
	echo "">>${attachFile}
	echo "--------------------ERROR LOG: begine">>${attachFile}
	grep -w level_0 ${tdFile} >>${attachFile}
	echo "--------------------ERROR LOG: end">>${attachFile}
	echo "">>${attachFile}

	echo "">>${attachFile}
	echo "">>${attachFile}
	echo "">>${attachFile}
	echo "--------------------TIMER LOG: begine">>${attachFile}
	sed -n '/startCycTskTimer/p' ${tdFile} |grep -w "tmpSeconds" >>${attachFile}
	echo "--------------------TIMER LOG: end">>${attachFile}
	echo "">>${attachFile}
	echo "">>${attachFile}
	echo " end:$(date +%y-%m-%d_%H:%M:%S.%N)" >>${attachFile}

    return 0
}


function F_chkBusiStat() #get ftp server's status
{
    local thFname="F_chkBusiStat"
    if [ $# -ne 9 ];then
        return 1
    fi
    
    local debugflag=${debugFlagM}
    local ret

    local ftpIP=$1      #ftp ip address
    local ftpCtrPNum=$2 #the port number
    local ftpUser=$3    #ftp username
    local ftpPwd=$4     #ftp password
    local trsType="$5"  #0:ascii; 1:binary
    local trsMode="$6"  #0:passive; 1:active
    local chkStr="$7"
    local logFile="$8"
    local tmpFile="$9"

    local fileNameTmp

    local logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"
    local opStr
    local opCmd
    local typeStr
    local modeStr
    local outmsg
    local modeOpt

    local opFlag=0
    if [ ${opFlag} -eq 0 ];then
        opStr="downlaod"
        opCmd="mget"
    else
        opStr="upload"
        opCmd="mput"
    fi
    if [ ${trsType} -eq 0 ];then
        typeStr="ascii"
    else
        typeStr="binary"
    fi
    if [ ${trsMode} -eq 0 ];then
        modeStr="passive"
        modeOpt="-p"
    else
        modeStr="active"
        modeOpt="-A"
    fi

    local outmsg="function ${thFname} input param ${logTime} 
         debugflag=[${debugflag}]
         opFlag=[${opFlag}],opStr=[${opStr}],opCmd=[${opCmd}]
         trsType=[${trsType}],typeStr=[${typeStr}]
         trsMode=[${trsMode}],modeStr=[${modeStr}],modeOpt=[${modeOpt}]
         ---------ftp para begine--------
         ----ftpIP     =[${ftpIP}]
         ----ftpUser   =[${ftpUser}]
         ----ftpPwd    =[${ftpPwd}]
         ----ftpCtrPNum=[${ftpCtrPNum}]
         ---------ftp para end----------
         "
    F_outShDebugMsg "${logFile}" ${debugflag} 4 "${outmsg}"
    


    nc -z ${ftpIP} ${ftpCtrPNum} >/dev/null 2>&1
    ret=$?
    if [ ${ret} -ne 0 ];then
        #connect ftp server error
        echo "connect ftp server[${ftpIP} ${ftpCtrPNum}] error"
        return 11
    fi

    local tmpstr="open ${ftpIP} ${ftpCtrPNum}
              user ${ftpUser} ${ftpPwd}
              ${typeStr}
    "

    echo "${tmpstr}">${tmpFile}

    local tailName="_$(date +%Y%m%d)_*.xml"

    local chkStrList=$(F_convertVLineToSpace "${chkStr}")
    local ckIdx=0
    local ckNamePre
    local ckName
    local cktdir
    local ckup
    local it
    for it in ${chkStrList}
    do
        ckNamePre=$(echo "${it}"|cut -d '#' -f 1)
        ckName="${ckNamePre}${tailName}"
        cktdir=$(echo "${it}"|cut -d '#' -f 2)
        ckup=$(echo "${it}"|cut -d '#' -f 3)
        echo "cd ${cktdir}">>${tmpFile}
        echo "ls ${ckName}">>${tmpFile}
        echo "cd ${ckup}">>${tmpFile}
        echo "ls ${ckName}">>${tmpFile}
    done

    echo "bye">>${tmpFile}
    echo "">>${tmpFile}

    #cat ${tmpFile}
    local ftpRet

    ftpRet=$(cat ${tmpFile}|ftp -n -v ${modeOpt} 2>&1)

    echo "${ftpRet}">>${smailFilePre}



    logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

    #service ready
    local v220=$(echo ${ftpRet}|grep -E "\s+\<220\>\s+"|wc -l)
    #Password required
    local v331=$(echo ${ftpRet}|grep -E "\s+\<331\>\s+"|wc -l)
    #not logging in to the network
    local v530=$(echo ${ftpRet}|grep -E "\s+\<530\>\s+"|wc -l)
    #login to the internet
    local v230=$(echo ${ftpRet}|grep -E "\s+\<230\>\s+"|wc -l)
    #The system cannot find the file specified.
    local v550=$(echo ${ftpRet}|grep -E "\s+\<550\>\s+"|wc -l)

    #TTNUM=$(echo ${ftpRet}|grep -E "User[ ]+cannot[ ]+log"|wc -l)
    #if [[ "${TTNUM}" -gt 0 ]];then
    if [[ "${v331}" -gt 0 && "${v530}" -gt 0 ]];then
        echo "wrong user name or password"
        #echo "${ftpRet}"
        return 12
    fi

    #TTNUM=$(echo ${ftpRet}|grep -E "cannot[ ]+find[ ]+the[ ]+file"|wc -l)
    #if [[ "${TTNUM}" -gt 0 ]];then
    if [[ "${v230}" -gt 0 && "${v550}" -gt 0 ]];then
        echo "The system cannot find the file specified."
        #echo "${ftpRet}"
        return 13
    fi

    #echo "${ftpRet}"
    return 0
}


if [ -z "{chkNums}" ];then
    F_outShDebugMsg ${logFile} 1 1 "ERROR:There is no configuration variable [chkNums] in file [${tconfFile}]!"
    exit 1
fi

F_judgeDoit "${recordDtFile}" "${smailFile}" "${chkNums}" "${logFile}"
retStat=$?
if [ ${retStat} -ne 1 ];then
    F_outShDebugMsg ${logFile} ${debugFlagM} 2 "call F_judgeDoit return result is  not need to call F_chkBusiStat!"
    exit 0
else
    F_outShDebugMsg ${logFile} ${debugFlagM} 2 "call F_judgeDoit return result is  need to call F_chkBusiStat!"
fi

#fusk test begine
#exit 0
#fusk test end


F_outShDebugMsg ${logFile} 1 1 "$0 running beine:${begineTm}"

attaFlag=0
F_genAttach
retStat=$?
if [ ${retStat} -eq 0 ];then
	attaFlag=1
fi

memInfo=""
if [ ! -z "${winMemeFile}" ];then
	if [ -e "${winMemeFile}" ];then
		#tcont=$(sed -n '1p' ${winMemeFile}|sed  's///g')
		if [ -e "${tmpwinmemf}" ];then
			rm -rf "${tmpwinmemf}"
		fi
		iconv  -f utf-16le -t utf-8 ${winMemeFile} -o ${tmpwinmemf}
		tcont=$(sed -n 's/[^0-9a-zA-Z]\+//g'p ${tmpwinmemf})
		tfile=${winMemeFile##*/}
		ttime=$(ls -l "${winMemeFile}"|awk '{print $6,$7}')
		memInfo="


		${ttime} ${tfile}:  ${tcont}"
	fi
fi

>${smailFilePre}
headCnt="

Dear fu.sky:

    The following will send you the $(date +%Y-%m-%d) business list 
  generation situation as follows:${memInfo} "
tailCnt="  

Wishing your business ever successful !
$(whoami)
$(date +%y-%m-%d_%H:%M:%S.%N)

"
echo "${headCnt}">${smailFile}

mIdx=0
for ((i=0;i<${doNum};i++))
do
    if [ -z "${rMailAddr[$i]}" ];then
        retMsg="rMailAddr[$i] is not exits"
        F_outShDebugMsg ${logFile} 1 1 "${retMsg}"
        exit 1
    fi
    rMailAddrList=$(F_convertVLineToSpace "${rMailAddr[$i]}") 
    mIdx=0
    for it in ${rMailAddrList}
    do
        enableMail[${mIdx}]=$(echo "${it}"|cut -d '#' -f 1)
        mailAddr[${mIdx}]=$(echo "${it}"|cut -d '#' -f 2)
        let mIdx++
    done 

    #echo "F_chkBusiStat \"${ftpip[$i]}\" \"${ftpport[$i]}\" \"${ftpuname[$i]}\" \"${ftpupwd[$i]}\" \"${trsType[$i]}\" \"${trsMode[$i]}\" \"${chkStr[$i]}\" \"${logFile}\" \"${tmpFile}\" "
    retMsg=$(F_chkBusiStat "${ftpip[$i]}" "${ftpport[$i]}" "${ftpuname[$i]}" "${ftpupwd[$i]}" "${trsType[$i]}" "${trsMode[$i]}" "${chkStr[$i]}" "${logFile}" "${tmpFile}")
    ret=$?
    if [ ${ret} -ne 0 ];then
        echo "">>${smailFile}
        echo "ERROR:-------------------">>${smailFile}
        echo "${retMsg}">>${smailFile}
        echo "-------------------">>${smailFile}
        echo "">>${smailFile}
        F_outShDebugMsg ${logFile} 1 1 "${retMsg}"
    fi

done

#cat ${smailFilePre}
#sed -n '/\(\btdir1\b\|\bup\b\|busilist_\)/p' ${smailFilePre} |sed 's/^\s*250\s*Directory\s*changed\s*to\s*//g'|sed '/tdir/ i\\n'|sed 's/^/  /g'>>${smailFile}
F_formatFtpBusCnt "${smailFilePre}" "${smailFile}"

sdmailTitle="[$(date +%Y%m%d)_$$]busilist report"
echo "${tailCnt}">>${smailFile}

#echo "sdmailTitle=[${sdmailTitle}]"
#cat ${smailFile}
#exit 0

tnum=$(wc -l ${smailFile} |awk '{print $1}')
#echo "tnum=[${tnum}],mIdx=[${mIdx}]"
if [ ${tnum} -gt 0 ];then
    for ((i=0;i<${mIdx};i++))
    do
        #echo  "${enableMail[$i]}"
        if [ "${enableMail[$i]}" = "1" ];then
			if [ ${attaFlag} -eq 1 ];then
				/bin/mail -s "${sdmailTitle}" -a ${attachFile} ${mailAddr[$i]} <${smailFile}
				outmsg="/bin/mail -s \"${sdmailTitle}\" -a ${attachFile} ${mailAddr[$i]} <${smailFile}"
			else
				/bin/mail -s "${sdmailTitle}" ${mailAddr[$i]} <${smailFile}
				outmsg="/bin/mail -s \"${sdmailTitle}\"  ${mailAddr[$i]} <${smailFile}"
			fi
            #echo "outmsg=[${outmsg}]"
            F_outShDebugMsg ${logFile} 1 1 "${outmsg}"
        fi
    done

fi

endTm="$(date +%Y-%m-%d_%H:%M:%S.%N)"
F_outShDebugMsg ${logFile} 1 1 "$0 running end:${endTm}"

exit 0


