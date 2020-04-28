#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20170622
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Upload files to ftp server
#
#invoke eg    :    
#    putFileFtp.sh "192.168.0.154" "Administrator" "qwer1234" "/tmp" "/home/zfmd/tmp" "22"
#
#version chg  :
#   20190119@improve the function
#
#############################################################################


. ~/.bash_profile >/dev/null 2>&1

runDir=$(dirname $0)

#load sh func
funcFlag=0
diyFuncFile=${runDir}/meteShFunc.sh
if [ ! -f ${diyFuncFile} ];then
    exit 1
else
    . ${diyFuncFile}
    funcFlag=1
fi

shNAME="putFileFtp"

#print log level:identifiable level 2 N-th power combination
#shDebugFlag=16
shDebugFlag=255

logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"
logFNDate="$(date '+%Y%m%d')"

#function outShDebugMsg() #out put $4 to $1; use like: outShDebugMsg $logfile $cfgdebug $valdebug $putcontent $clearflag

#if you need a personalized log directory,you need to configure the environment
#   varible "RMETEMAINP",for exampl RMETEMAINP=/home/zfmd
#if you do not configure the default directory as the log folder under the upper
#   directory
if [[ -z ${RMETEMAINP} ]]; then
    RMETEMAINP=$(dirname $(dirname $0))
    if [[ ! -d ${RMETEMAINP}/log ]]; then
        mkdir -p ${RMETEMAINP}/log
        if [[ $? -eq 0  ]]; then
            outmsg="${logTime} mkdir -p ${RMETEMAINP}/log"
            outShDebugMsg "${RMETEMAINP}/log/${shNAME}${logFNDate}.log" ${shDebugFlag} 0 "${outmsg}" 0
        fi
    fi
fi
logFile=${RMETEMAINP}/log/${shNAME}${logFNDate}.log


function writeLog()
{
    valDebug="$1"
    outmsg="$2"
    clearFlag=0
    [ $# -eq 3 ] && clearFlag=$3

    #echo -e "-------logFile=[${logFile}]"
    outShDebugMsg "${logFile}" "${shDebugFlag}" "${valDebug}" "${outmsg}" "${clearFlag}"
    ret=$?
    return ${ret}
}


writeLog 16 "\n${logTime} ${shNAME}.sh:$#:start -->"


outmsg="${logTime} --debug:input param nums:$#
                   --logFile=[${logFile}]"
writeLog 2 "${outmsg}"


if [[ $# -ne 6 && $# -ne 7 && $# -ne 8 && $# -ne 9 ]];then
    outmsg="${logTime} input error,please input like this:
                 ${shNAME}.sh <ftpIP> <ftpUser> <ftpPwd> <ftpRdir> <ftpLdir> <fileName>
                 or
                 ${shNAME}.sh <trsType> <trsMode> <ftpIP> <ftpUser> <ftpPwd> <ftpRdir> <ftpLdir> <fileName>"
    writeLog 0 "${outmsg}" 2
    exit 1
fi

opFlag=1 #0:download, 1:upload
trsType=0 #0:ascii ,1:binary
trsMode=0 #0:passive mode for data transfers, 1:active mode for data transfers
if [ $# -eq 8 -o $# -eq 9 ];then
    trsType=$1
    shift
    trsMode=$1
    shift
fi

tcheck=$(echo "${trsType}"|sed -n "/^[0-1]$/p"|wc -l)
[ ${tcheck} -eq 0 ] && trsType=0

tcheck=$(echo "${trsMode}"|sed -n "/^[0-1]$/p"|wc -l)
[ ${tcheck} -eq 0 ] && trsMode=0


ftpIP=$1
ftpUser=$2
ftpPwd=$3
ftpRdir=$4  #directory on the server
ftpLdir=$5  #ftp client local directory
fileName=$6 #file name to be processed on the ftp server

#default port number
if [[ $# -eq 6 ]];then
    ftpCtrPNum=21
else
    ftpCtrPNum=$7
fi  


ftpTrType="ascii"

outmsg="${logTime} shDebugFlag=[${shDebugFlag}]
        ---------ftp para begine--------
        ----ftpIP     =[${ftpIP}]
        ----ftpUser   =[${ftpUser}]
        ----ftpPwd    =[${ftpPwd}]
        ----ftpRdir   =[${ftpRdir}]
        ----ftpLdir   =[${ftpLdir}]
        ----fileName  =[${fileName}]
        ----ftpCtrPNum=[${ftpCtrPNum}]
        ----ftpTrType =[${ftpTrType}]
        ---------ftp para end----------
"
writeLog 4 "${outmsg}"

ftpRet=$(getOrPutFtpFile "${opFlag}" "${trsType}" "${trsMode}" "${ftpIP}" "${ftpUser}" "${ftpPwd}" "${ftpRdir}" "${ftpLdir}" "${fileName}" "${ftpCtrPNum}")
retstat=$?

logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"
writeLog 8 "\n${logTime} retstat=[${retstat}],ftpRet=[${ftpRet}]\n"

if [ "${retstat}" -eq 0 ];then
    writeLog 16 "${logTime} ${shNAME}.sh:$#:end \n"
else
    writeLog 16 "${logTime} ${shNAME}.sh:$#:unsuccessfull \n"
fi


exit ${retstat}

