
#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20190427
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#   This script updates the scasa configuration file unitMemInit.xml
#       (backup before updating) and restarts scada.
#    
#revision history:
#       
#
#############################################################################


baseDir=$(dirname $0)
scadaCfgFile="${baseDir}/unitMemInit.xml"
suffixDate=$(date +%Y%m%d%H%M%S)
backCfgFile="${baseDir}/unitMemInit.xml_${suffixDate}"
pName="CommSubsystem"
maxSeconds=300


#echo "--[${baseDir}],[${suffixDate}]-[${scadaCfgFile}]-[${backCfgFile}]-"

if [ ! -e "${scadaCfgFile}" ];then
    echo -e "\n\t\e[1;31mERROR:\e[0m File [ ${scadaCfgFile} ] does  not exist!!\n"
    exit 1
fi

findNum=$(sed -n '/multFactor="0"/p' ${scadaCfgFile} |wc -l)
if [ ${findNum} -lt 1 ];then
    echo -e "\n\t\e[1;31mTIPS:\e[0m File [ ${scadaCfgFile} ] does not need to be modified!\n"
    exit 2
fi


#back cfg file
cp ${scadaCfgFile} ${backCfgFile}  && echo -e "\n\tBackup configuration file:\n\t\tcp ${scadaCfgFile} ${backCfgFile}\n"

echo -e "\n\tStart preparing to modify the configuration file [${scadaCfgFile}] ...\n"
echo -e "\n\t--------------------The content to be modified is as follows:"
sed -n '/multFactor="0"/p' ${scadaCfgFile}

sed -i 's/multFactor="0"/multFactor="0.00000000000001"/g' ${scadaCfgFile}
echo -e "\n\t--------------------The content to be modified above is modified as follows:"
sed -n '/multFactor="0.00000000000001"/p' ${scadaCfgFile}

echo -e "\n\t\e[1;31mThe following will restart the scada, please be patient.\e[0m\n"


function writeLog()
{
    timeFlag="$1"
    outMsg="$2"

    if [ ${timeFlag} -eq 1 ];then
        echo -e "`date +%Y/%m/%d-%H:%M:%S.%N`:${shName}:${outMsg}"
    else
        echo -e "${shName}:${outMsg}"
    fi
    return 0
}


function killProgram()
{
    tPid=$(pidof -x ${pName})
    if [ "" = "$tPid" ];then
        writeLog 1 "Program [${pName}] is not running\n"
        return 0
    fi

    kill ${tPid}
    ret=$?
    writeLog 1 "kill ${tPid} return[${ret}]\n"
    if [ ${ret} -ne 0 ];then
        kill -9 ${tPid}
        ret=$?
        if [ ${ret} -ne 0 ];then
            writeLog 1 "kill -9 ${tPid} return[${ret}]\n"
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

    writeLog 1 "waiting for program [${pName}] to exit, waitSeconds=[${waitSeconds}] \n"

    if [ ${waitSeconds} -gt ${tmpwait} ];then
            kill -9 ${tPid}
            writeLog 1 "kill ${tPid} not success and use kill -9 ${tPid} \n"
    fi


    tNewPid=$(pidof -x ${pName})
    waitSeconds=0
    while [[ -z "${tNewPid}" || ${tNewPid} -eq ${tPid} ]]
    do
        sleep 1
        tNewPid=$(pidof -x ${pName})
        let waitSeconds++
        #writeLog 1 "oldPid=[${tPid}],newPid=[${tNewPid}],waitSeconds=[${waitSeconds}]\n"
        if [ ${waitSeconds} -gt ${maxSeconds} ];then
            break
        fi

    done

    writeLog 1 "waiting for program [${pName}] to start, waitSeconds=[${waitSeconds}]\n"

    if [ ${waitSeconds} -gt ${maxSeconds} ];then
        if [[ ! -z ${tNewPid} && ${tNewPid} -eq ${tPid} ]];then
            kill -9 ${tPid}
            writeLog 1 "kill ${tPid} not success and use kill -9 ${tPid}  ---22222 \n"
        else
            writeLog 1 "kill ${tPid} success and  restart ${pName} not success!\n"
        fi
    else
        writeLog 1 "kill ${pName} success and  restart ${pName} success,oldPid=[${tPid}],newPid=[${tNewPid}]\n"
    fi

    return 0
}

#kill and wait restart scada
killProgram


echo -e "\n\tscript [ $0 ] runs complete!!\n"
echo -e "\n\t\e[1;31m请 将 执 行 结 果 用【图片】方 式 反 馈 到 相关人员处,谢谢! \e[0m\n"


exit 0
