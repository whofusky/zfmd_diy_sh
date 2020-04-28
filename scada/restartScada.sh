
#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20190428
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#   Kill the scada process and wait for the restar
#   
#    
#revision history:
#       
#
#############################################################################


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

baseDir=$(dirname $0)
shName=$(getFnameOnPath $0)

#Exit if there is a script running
pidFile="${baseDir}/.${shName}.pid"
if [ -e "${pidFile}" ];then
    if [ -s "${pidFile}" ];then
        shOldPid="$( cat ${pidFile})"

        if [ -e /proc/${shOldPid}/status ]; then
            echo -e "\n\t\e[1;31mERROR:\e[0mscript [$0] \e[1;31mhas been running\e[0m,this run directly exits!\n"
            exit 0
        fi
    fi
fi

echo $$ >${pidFile}
trap " rm -rf ${pidFile}" 0 1 2 3 9 11 13 15


suffixDate=$(date +%Y%m%d%H%M%S)
pName="CommSubsystem"
maxSeconds=300


#echo "--[${baseDir}],[${suffixDate}]-[${scadaCfgFile}]-[${backCfgFile}]-"


function writeLog()
{
    timeFlag="$1"
    outMsg="$2"

    if [ ${timeFlag} -eq 1 ];then
        echo -e "`date +%Y/%m/%d-%H:%M:%S.%N`:${shName}:${outMsg}"
    elif [ ${timeFlag} -eq 9 ];then
        echo -e "\n\t`date +%Y/%m/%d-%H:%M:%S.%N`:${shName}:${outMsg}"
    elif [ ${timeFlag} -eq 8 ];then
        echo -e "\t`date +%Y/%m/%d-%H:%M:%S.%N`:${shName}:${outMsg}"
    else
        echo -e "${shName}:${outMsg}"
    fi
    return 0
}


function killProgram()
{
    tPid=$(pidof -x ${pName})
    if [ "" = "$tPid" ];then
        writeLog 9 "tProgram [\e[1;31m${pName}\e[0m] is not running\n"
        return 0
    fi

    kill ${tPid}
    ret=$?
    writeLog 9 "kill ${tPid} return[${ret}]\n"
    if [ ${ret} -ne 0 ];then
        kill -9 ${tPid}
        ret=$?
        if [ ${ret} -ne 0 ];then
            writeLog 8 "kill -9 ${tPid} return[${ret}]\n"
        fi
    fi

    tNewPid=$(pidof -x ${pName})
    waitSeconds=0
    tmpwait=30
    while [[ ! -z "${tNewPid}" && ${tNewPid} -eq ${tPid} ]]
    do
        sleep 1
        tNewPid=$(pidof -x ${pName})
        let waitSeconds++
        if [ ${waitSeconds} -gt ${tmpwait} ];then
            break
        fi
    done

    writeLog 8 "waiting for program [\e[1;31m${pName}\e[0m] to exit, waitSeconds=[${waitSeconds}] \n"

    if [ ${waitSeconds} -gt ${tmpwait} ];then
            kill -9 ${tPid}
            writeLog 8 "kill ${tPid} not success and use kill -9 ${tPid} \n"
    fi


    tNewPid=$(pidof -x ${pName})
    waitSeconds=0
    while [[ -z "${tNewPid}" || ${tNewPid} -eq ${tPid} ]]
    do
        sleep 1
        tNewPid=$(pidof -x ${pName})
        let waitSeconds++
        #writeLog 8 "oldPid=[${tPid}],newPid=[${tNewPid}],waitSeconds=[${waitSeconds}]\n"
        if [ ${waitSeconds} -gt ${maxSeconds} ];then
            break
        fi

    done

    writeLog 8 "waiting for program [\e[1;31m${pName}\e[0m] to start, waitSeconds=[${waitSeconds}]\n"

    if [ ${waitSeconds} -gt ${maxSeconds} ];then
        if [[ ! -z ${tNewPid} && ${tNewPid} -eq ${tPid} ]];then
            kill -9 ${tPid}
            writeLog 8 "kill ${tPid} not success and use kill -9 ${tPid}  ---22222 \n"
        else
            writeLog 8 "kill ${tPid} success and  restart [\e[1;31m${pName}\e[0m] not success!\n"
        fi
    else
        writeLog 8 "kill [\e[1;31m${pName}\e[0m] success and  restart [\e[1;31m${pName}\e[0m] success,oldPid=[${tPid}],newPid=[${tNewPid}]\n"
    fi

    return 0
}

#kill and wait restart scada
killProgram


#echo -e "\n\t`date +%Y/%m/%d-%H:%M:%S.%N`:script [ $0 ] runs complete!!\n\n"


exit 0
