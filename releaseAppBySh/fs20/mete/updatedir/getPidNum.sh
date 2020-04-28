#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20170727
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Query the number of processes of the corresponding program
#
#invoke eg    :
#   getPidNum.sh ftp
#
#version chg  :
#   20190115@improve the function
#
#############################################################################


. ~/.bash_profile >/dev/null 2>&1

shNAME="getPidNum"

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

#print log level:identifiable level 2 N-th power combination
shDebugFlag=0

logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"
logFNDate="$(date '+%Y%m%d')"

#if you need a personalized log directory,you need to configure the environment
#   varible "RMETEMAINP",for exampl RMETEMAINP=/home/zfmd
#if you do not configure the default directory as the log folder under the upper
#   directory
if [ -z ${RMETEMAINP} ]; then
    RMETEMAINP=$(dirname $(dirname $0))
    if [ ! -d ${RMETEMAINP}/log ]; then
        mkdir -p ${RMETEMAINP}/log
        if [[ $? -eq 0  ]]; then
            outmsg="${logTime} mkdir -p ${RMETEMAINP}/log"
            outShDebugMsg "${RMETEMAINP}/log/${shNAME}${logFNDate}.log" ${shDebugFlag} 1 "${outmsg}" 0
        fi
    fi
fi

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


if [ $# -ne 1 ];then
    outmsg="${logTime} input error,please input like this:
                 ${shNAME}.sh <programe_name>"
    writeLog 0 "${outmsg}" 2
	exit 0
fi

#program name
pidName=$1
shNameE=${shNAME}.sh

#pidNum=`ps -ef|grep -w ${pidName}|grep -v grep|grep -v ${shNameE}|wc -l`
pidNum=$(pidof -x ${pidName}|awk 'BEGIN {num=0;}{ if(NF>0){num=NF;}} END{print num}')

writeLog 1 "${logTime} pidNum=[${pidNum}] pidName=[${pidName}]"
  
exit ${pidNum}


