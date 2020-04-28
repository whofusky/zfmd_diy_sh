#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20190402
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    查询程序${pName}的进程，如果有进程则kill,kill失败尝试用kill -9
#       (1)如果进程kill成功，则会等待程序的启动,如果等待了${maxSeconds}秒后程序没有启来脚本也退出

#    
#
#############################################################################


baseDir=$(dirname $0)
logFNDate="$(date '+%Y%m%d')"

pName="DataCenter"

maxSeconds=300


function getFnameOnPath() #get the file name in the path string
{
    if [ $# -ne 1 ];then
        echo "  Error: function getFnameOnPath input parameters not eq 1!"
        return 1
    fi

    allName="$1"
    if [ -z "${allName}" ];then
        echo "  Error: function getFnameOnPath input parameters is null!"
        return 2;
    fi

    slashNum=$(echo ${allName}|grep "/"|wc -l)
    if [ ${slashNum} -eq 0 ];then
        echo ${allName}
        return 0
    fi

    fName=$(echo ${allName}|awk -F'/' '{print $NF}')
    echo ${fName}

    return 0
}

#加载系统环境变量配置
if [ -f /etc/profile ]; then
    . /etc/profile >/dev/null 2>&1
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile >/dev/null 2>&1
fi

logDir="${baseDir}/log"
if [ ! -d "${logDir}" ];then
    mkdir -p "${logDir}"
fi

logFile="${logDir}/${logFNDate}.log"
shName=$(getFnameOnPath $0)

function writeLog()
{
    timeFlag=$1
    outMsg="$2"
    if [ ${timeFlag} -eq 1 ];then
        echo -e "`date +%Y/%m/%d-%H:%M:%S.%N`:${shName}:${outMsg}">>${logFile}
    else
        echo -e "${shName}:${outMsg}">>${logFile}
    fi
    return 0
}

#已经有脚本在运行则退出
tmpShPid=$(pidof -x $0)
tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
if [ ${tmpShPNum} -gt 1 ]; then
    writeLog 0 "+++${tmpShPid}+++++${tmpShPNum}+++"
    writeLog 1 "script [$0] has been running,this run directly exits!"
    exit 0
fi

tPid=$(pidof ${pName})
if [ "" = "$tPid" ];then
    writeLog 1 "Program [${pName}] is not running\n"
    exit 0
fi

kill ${tPid}
ret=$?
if [ ${ret} -ne 0 ];then
    writeLog 1 "kill ${tPid} return[${ret}]\n"
    kill -9 ${tPid}
    ret=$?
    if [ ${ret} -ne 0 ];then
        writeLog 1 "kill -9 ${tPid} return[${ret}]\n"
    fi
fi

tNewPid=$(pidof ${pName})
waitSeconds=0
tmpwait=60
while [[ ! -z "${tNewPid}" && ${tNewPid} -eq ${tPid} ]]
do
    sleep 1
    let waitSeconds++
    if [ ${waitSeconds} -gt ${tmpwait} ];then
        break
    fi
done

if [ ${waitSeconds} -gt ${tmpwait} ];then
        kill -9 ${tPid}
        writeLog 1 "kill ${tPid} not success and use kill -9 ${tPid} \n"
fi


tNewPid=$(pidof ${pName})
waitSeconds=0
while [[ -z "${tNewPid}" || ${tNewPid} -eq ${tPid} ]]
do
    sleep 1
    tNewPid=$(pidof ${pName})
    let waitSeconds++
    writeLog 1 "oldPid=[${tPid}],newPid=[${tNewPid}],waitSeconds=[${waitSeconds}]\n"
    if [ ${waitSeconds} -gt ${maxSeconds} ];then
        break
    fi

done

if [ ${waitSeconds} -gt ${maxSeconds} ];then
    if [ ${tNewPid} -eq ${tPid} ];then
        kill -9 ${tPid}
        writeLog 1 "kill ${tPid} not success and use kill -9 ${tPid}  ---22222 \n"
    else
        writeLog 1 "kill ${tPid} success and  restart ${pName} not success!\n"
    fi
else
    writeLog 1 "kill ${pName} success and  restart ${pName} success,oldPid=[${tPid}],newPid=[${tNewPid}]\n"
fi

exit 0

