#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20190214
#linux_version:    Red Hat Enterprise Linux Server release 6.7 
#dsc          :   
#    Output content to the appropriate file as required
#
#eg           :
#   shWriteLog.sh <logFileName> <opFlag> <content1> [content2] ...[contentn]
#                               opFlag 1:overwrite logFile; 0:append logFile
#
#############################################################################


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
    
    dirStr=$(echo "$1"|awk -F'/' '{for(i=1;i<NF;i++){printf "%s/",$i}}'|sed 's/\/$//g')
    if [ -z "${dirStr}" ];then
        dirStr="."
    fi

    echo "${dirStr}"
    return 0
}

minInNum=3
if [ $# -lt ${minInNum} ];then
    echo "  ERROR[1]: The inpput parameter of shell script [$0] should be no less than ${minInNum} !"
    exit 1
fi

logFile="$1"
if [ ! -e "${logFile}" ];then
    logDir=$(getPathOnFname "${logFile}")
    retStat=$?
    if [ ${retStat} -eq 0 -a ! -d ${logDir} ];then
        echo "  ERROR[2]: The directory [${logDir}] of the log file [${logFile}] does not exists !"
        exit 2
    elif [ ${retStat} -ne 0 ];then
        echo "  ERROR[3]: getPathOnFname \"${logFile}\" return message[${logDir}]!"
        exit 3
    fi
    if [ ! -w "${logDir}" ];then
        echo "  ERROR[4]: The target directory [${logDir}] does not have permission to write!"
        exit 4
    fi
    if [ ! -x "${logDir}" ];then
        echo "  ERROR[5]: The target directory [${logDir}] does not have permission to executable!"
        exit 5
    fi
elif [ -f "${logFile}" -a ! -w "${logFile}" ];then
    echo "  ERROR[6]: Log file [${logFile}] does not have permission to write!"
    exit 6
elif [ ! -f  "${logFile}" ];then
    echo "  ERROR[7]: Log file [${logFile}] type error!"
    exit 7
fi

shift

writeFlag="$1"  #1:overwrite logFile; 0:append logFile
tcheck=$(echo "${writeFlag}"|sed -n "/^[01]$/p"|wc -l)
#echo "writeFlag=[${writeFlag}],\$1=[$1],tcheck=[${tcheck}]"
[ ${tcheck} -eq 0 ] && writeFlag=0

shift

[ ${writeFlag} -eq 1 ] && >"${logFile}"

#echo "writeFlag=[${writeFlag}],\$1=[$1],tcheck=[${tcheck}],all=[$@]"
for tmp in "$@"
do
    echo -en "${tmp}">>"${logFile}"
done

exit 0

