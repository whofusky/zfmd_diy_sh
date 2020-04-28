#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20170724
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Get the status of uploading ftp server
#
#invoke eg    :
#   putFserStas.sh "192.168.0.154" "Administrator" "qwer1234" "/tmp" "/home/zfmd/tmp" "22"
#
#version chg  :
#   20190115@improve the function
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

shNAME="putFserStas"

#print log level:identifiable level 2 N-th power combination
shDebugFlag=3
#shDebugFlag=31

logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"
logFNDate="$(date '+%Y%m%d')"

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

#tmpFile=${RMETEMAINP}/log/.fPtmpFile
logFile=${RMETEMAINP}/log/${shNAME}${logFNDate}.log


function writeLog()
{
    valDebug=$1
    outmsg="$2"
    clearFlag=0
    [ $# -eq 3 ] && clearFlag=$3
    outShDebugMsg ${logFile} ${shDebugFlag} ${valDebug} "${outmsg}" ${clearFlag}
    ret=$?
    return ${ret}
}


if [[ $# -ne 6 && $# -ne 7 && $# -ne 8 && $# -ne 9 ]];then
    outmsg="${logTime} input error,please input like this:
                 ${shNAME}.sh <ftpIP> <ftpUser> <ftpPwd> <ftpRdir> <ftpLdir> <fileName>
                 or
                 ${shNAME}.sh <trsType> <trsMode> <ftpIP> <ftpUser> <ftpPwd> <ftpRdir> <ftpLdir> <fileName>"
    writeLog 0 "${outmsg}"
	exit 6
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
fileName=$6 #file name to be uploaded to the ftp server

#default port number
if [[ $# -eq 6 ]];then
    ftpCtrPNum=21
else
    ftpCtrPNum=$7
fi  

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


outmsg="${logTime} ${shNAME}.sh input param
     shDebugFlag=[${shDebugFlag}]
     opFlag=[${opFlag}],opStr=[${opStr}],opCmd=[${opCmd}]
     trsType=[${trsType}],typeStr=[${typeStr}]
     trsMode=[${trsMode}],modeStr=[${modeStr}],modeOpt=[${modeOpt}]
     logFile=[${logFile}]
     ---------ftp para begine--------
     ----ftpIP     =[${ftpIP}]
     ----ftpUser   =[${ftpUser}]
     ----ftpPwd    =[${ftpPwd}]
     ----ftpRdir   =[${ftpRdir}]
     ----ftpLdir   =[${ftpLdir}]
     ----fileName  =[${fileName}]
     ----ftpCtrPNum=[${ftpCtrPNum}]
     ---------ftp para end----------
     "
writeLog 16 "${outmsg}"

ftpRet=$(getFtpSerStatu "${opFlag}" "${trsType}" "${trsMode}" "${ftpIP}" "${ftpUser}" "${ftpPwd}" "${ftpRdir}" "${ftpLdir}" "${fileName}" "${ftpCtrPNum}")
ret=$?
logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

#local path error
if [ ${ret} -eq 10 ];then
    writeLog 2 "${logTime}the local file path [${ftpLdir}] is error\n"
    exit 5
fi

if [ ${ret} -eq 11 ];then
    writeLog 2 "${logTime} connet ftp server [${ftpIP} ${ftpCtrPNum}] is error\n"
    exit 1
fi


#wrong user name or password
if [ ${ret} -eq 12 ];then
    writeLog 2 "\n${logTime} ftpRet=[${ftpRet}]"
    writeLog 2 "${logTime} the ftp username [${ftpUser}] or passwd [${ftpPwd}] is error\n"
    exit 2
fi

#remote path error
if [ ${ret} -eq 13 ];then
    writeLog 2 "\n${logTime} ftpRet=[${ftpRet}]"
    writeLog 2 "${logTime} the file path [${ftpRdir}]is error\n"
    exit 3
fi

#local file name does not exist
if [ ${ret} -eq 14 ];then
    writeLog 8 "\n${logTime} ftpRet=[${ftpRet}]"
    writeLog 8 "${logTime}the local file  [${fileName}] is not exists\n"
    exit 4
fi

writeLog 4 "\n${logTime} ftpRet=[${ftpRet}]"
writeLog 1 "${logTime} The ftp server [${ftpIP} ${ftpCtrPNum}] is in a normal state,and the file [${fileName}] exists in the local [${ftpLdir}] path!\n"

exit 0

