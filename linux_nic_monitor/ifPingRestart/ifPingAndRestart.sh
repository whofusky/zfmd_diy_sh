#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20190429
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#       Read the configured interface and ip information from the configuration
#       file [ ${baseDir}/ifIp.cfg ] ,and use the ping command to ping from the
#       fixed interface to the ip, IF NOT ,retsrt the corresponding interface
#
#    
#revision history:
#       
#
#############################################################################

#Èí¼þ°æ±¾ºÅ
versionNo="software version number: v0.0.0.1"


#load system environment configuration
if [ -f /etc/profile ]; then
    . /etc/profile >/dev/null 2>&1
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile >/dev/null 2>&1
fi


#Basic path and file settings
baseDir=$(dirname $0)
logFNDate="$(date '+%Y%m%d')"
logDir="${baseDir}/log"
if [ ! -d "${logDir}" ];then
    mkdir -p "${logDir}"
fi
versionFile="${baseDir}/version.txt"
cfgFile="${baseDir}/ifIp.cfg"
getEthNameFile="${baseDir}/getethname"
pingCount=1



tHostName="$(hostname)"

#Log run level definition
tLevelVal0=0
tLevelVal1=1
tLevelVal2=2
tLevelVal4=4

tmpDebugLevel=1

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




shName=$(getFnameOnPath $0)
preShName="${shName%.*}"
logFile="${logDir}/${preShName}${logFNDate}.log"




function writeLog()
{
    cfgDebugFlag="$1"
    valDebugFlag="$2"
    timeFlag="$3"
    outMsg="$4"

    if [[ ! -z "${timeFlag}" && ${timeFlag} -eq 4 ]];then 
        #Write version number to vertion file
        echo -e "\n\n*--------------------------------------------------\n*">${versionFile}
        echo -e "*\n*\t${versionNo}\n*" >>${versionFile}
        echo -e "*\tshell script name: ${shName}\n*">>${versionFile}
        echo -e "*\tHost name: ${tHostName} \n*">>${versionFile}
        echo -e "*\tRunning time is: $(date +%Y/%m/%d-%H:%M:%S.%N) \n*" >>${versionFile}
        echo -e "*--------------------------------------------------\n">>${versionFile}
        if [[ -e ${getEthNameFile} && -x ${getEthNameFile} ]];then
            #echo -e "--------------------------------------------------">>${versionFile}
            echo -e "The local network card information is as flollows:">>${versionFile}
            ${getEthNameFile} >>${versionFile} 2>&1 
            echo -e "--------------------------------------------------\n">>${versionFile}
        fi
        return 0
    fi

    
    tcheck=$(echo "${cfgDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && cfgDebugFlag=0
    tcheck=$(echo "${valDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && valDebugFlag=0

    #Do not output logs
    if [ ${cfgDebugFlag} -eq 0 ];then
        return 0
    fi
    #Do not output logs
    if [ $((${cfgDebugFlag}&${valDebugFlag})) -ne ${valDebugFlag} ];then
        return 0
    fi  

    if [ ! -e ${logFile} ];then
        echo -e "\n\n*--------------------------------------------------\n*">>${logFile}
        echo -e "*\n*\t${versionNo}\n*">>${logFile}
        echo -e "*\tshell script name: ${shName}\n*">>${logFile}
        echo -e "*\tHost name:${tHostName} \n*">>${logFile}
        echo -e "*--------------------------------------------------\n">>${logFile}
        if [[ -e ${getEthNameFile} && -x ${getEthNameFile} ]];then
            #echo -e "--------------------------------------------------">>${logFile}
            echo -e "The local network card information is as flollows:">>${logFile}
            ${getEthNameFile} >>${logFile} 2>&1 
            echo -e "--------------------------------------------------\n">>${logFile}
        fi
    fi
    if [[ ! -z "${timeFlag}" && ${timeFlag} -eq 3 ]];then
       return 0
    fi

    if [ ${timeFlag} -eq 1 ];then
        echo -e "`date +%Y/%m/%d-%H:%M:%S.%N`:${shName}:${outMsg}">>${logFile}
    elif [ ${timeFlag} -eq 2 ];then
        echo -e "\n\t`date +%Y/%m/%d-%H:%M:%S.%N`:${shName}:${outMsg}">>${logFile}
    else
        echo -e "${shName}:${outMsg}">>${logFile}
    fi
    return 0
}



#Detection script is run repeatedly
pidFile="${baseDir}/.${shName}.pid"
if [ -e "${pidFile}" ];then
    if [ -s "${pidFile}" ];then
        shOldPid="$(cat ${pidFile})"
        if [ -e "/proc/${shOldPid}/status" ];then
            writeLog "${tmpDebugLevel}" "${tLevelVal1}" 2 "TIPS: The script file [ ${shName} ] is already running,and this operation exits directly\n" 
            exit 0
        fi
    fi

fi
echo $$>${pidFile}


if [ ! -e "${cfgFile}" ];then
    writeLog  "${tmpDebugLevel}" "${tLevelVal1}" 2 " ERROR: file [ ${cfgFile} ] does not exist\n"
    exit 1
fi

#Write version number to vertion file 
writeLog  "${tmpDebugLevel}" "${tLevelVal1}" 4


readIpLinNum=0
#Read configuration file
while read LINE
do
    tmpIsCm=$(echo ${LINE}|tr "\040\011" "\0"|cut -c1)

    #Ignore comment lines
    if [ "${tmpIsCm}" == "#" ]; then
        continue
    fi

    #Ignore blank lines
    if [ -z "${tmpIsCm}" ];then
        continue
    fi

    preName=$( echo ${LINE}|awk -F '=' '{ if(NF>0){print $1;}}'|tr "\040\011" "\0")
    valName=$( echo ${LINE}|awk -F '=' '{ if(NF>0){print $2;}}'|tr "\040\011" "\0")

    #Get debug level
    if [ "${preName}" == "debugLevel" ]; then
        tmpDebugLevel=${valName}
        continue
    fi

    #Get the configuration ip line
    if [ "${tmpIsCm}" == "[" ]; then
        checkFormat=$(echo ${LINE}|awk -F'[][]' '{print NF}')
        if [ ${checkFormat} -ne 5 ];then
            continue
        fi
        tIFStr=$(echo ${LINE}|awk -F'[][]' '{print $2}')
        tIPStr=$(echo ${LINE}|awk -F'[][]' '{print $4}')

        preIF=$( echo ${tIFStr}|awk -F '=' '{ if(NF>0){print $1;}}')
        valIF=$( echo ${tIFStr}|awk -F '=' '{ if(NF>0){print $2;}}')
        preIP=$( echo ${tIPStr}|awk -F '=' '{ if(NF>0){print $1;}}')
        valIP=$( echo ${tIPStr}|awk -F '=' '{ if(NF>0){print $2;}}')
        
        #remove the spaces before and after
        preIF=$(echo "${preIF}"|sed  -e 's/^\s*//g;s/\s*$//g')
        valIF=$(echo "${valIF}"|sed  -e 's/^\s*//g;s/\s*$//g')
        preIP=$(echo "${preIP}"|sed  -e 's/^\s*//g;s/\s*$//g')
        valIP=$(echo "${valIP}"|sed  -e 's/^\s*//g;s/\s*$//g')

        #remove the  double quotes before and atfer
        valIP=$(echo "${valIP}"|sed -e 's/^"//g;s/"$//g')

#        echo "----tIFStr=[${tIFStr}]---"
#        echo "++++tIPStr=[${tIPStr}]+++"
#        echo "preIF=[${preIF}]"
#        echo "valIF=[${valIF}]"
#        echo "preIP=[${preIP}]"
#        echo "valIP=[${valIP}]"
#        for i in ${valIP}
#        do
#            echo "----[$i]----"
#        done

        tIFVal_a[${readIpLinNum}]="${valIF}"
        tIPVal_a[${readIpLinNum}]="${valIP}"
        let readIpLinNum++

        continue
    fi

done<"${cfgFile}"

#Exit without correspongding configuration
if [ ${readIpLinNum} -lt 1 ];then
    writeLog "${tmpDebugLevel}" "${tLevelVal2}" 2   "-----readIpLinNum=[${readIpLinNum}]---"
    exit 2
fi

function pingStatus()
{
    if [[ $# -ne 1 && $# -ne 2 ]];then
        echo "  Error: function pingStatus input parameters not eq 1 or 2!"
        return 2
    fi
    if [ $# -eq 2 ];then
        deviceName="$1"
        ipVal="$2"
    else
        ipVal="$1"
    fi

    if [ -z "${deviceName}" ];then
        retMsg=$(ping  -c ${pingCount} ${ipVal})
        retStat=$?
    else
        retMsg=$(ping -I ${deviceName} -c ${pingCount} ${ipVal})
        retStat=$?
    fi

    if [ -z "${retStat}" ];then
        retStat=3
    fi
    
    echo -e "${retMsg}"

    return ${retStat}
}


function restartIF()
{
    if [[ $# -ne 1  ]];then
        echo "  Error: function pingStatus input parameters not eq 1 !"
        return 2
    fi

    deviceName="$1"

    retMsg=$(ifconfig ${deviceName} down 2>&1)
    retStat=$?
    if [ ${retStat} -ne 0 ];then
        echo -e "ifconfig ${deviceName} down Error,retMsg=[${retMsg}]"
        return ${retStat}
    fi
    retMsg=$(ifconfig ${deviceName} up 2>&1)
    retStat=$?
    if [ ${retStat} -ne 0 ];then
        echo -e "ifconfig ${deviceName} up Error,retMsg=[${retMsg}]"
        return ${retStat}
    fi
    
    echo -e "${retMsg}"

    return ${retStat}
}

doNum=${#tIFVal_a[*]}
#echo "---doNum=[${doNum}],readIpLinNum=[${readIpLinNum}]---"

for ((i=0;i<${doNum};i++))
do
    tAllErrFlag=1
    for tIp in ${tIPVal_a[${i}]}
    do
        retMsg=$(pingStatus "${tIFVal_a[${i}]}" "${tIp}")
        retStat=$?
        if [ ${retStat} -eq 0 ];then
            tAllErrFlag=0
            writeLog "${tmpDebugLevel}" "${tLevelVal2}" 2 " interface=[${tIFVal_a[${i}]}],ip=[${tIp}], ping  success"
            writeLog "${tmpDebugLevel}" "${tLevelVal4}" 2 "interface=[${tIFVal_a[${i}]}],ip=[${tIp}], ping  debug return msg=[${retMsg}]\n\n"
        else
            writeLog "${tmpDebugLevel}" "${tLevelVal1}" 2 " interface=[${tIFVal_a[${i}]}],ip=[${tIp}], ping  unsuccessful!!!!!!!!!"
            writeLog "${tmpDebugLevel}" "${tLevelVal4}" 2 " interface=[${tIFVal_a[${i}]}],ip=[${tIp}], ping  debug return msg=[${retMsg}]\n\n"

        fi
        #echo "---i=[${i}]---retStat=[${retStat}],retMsg=[${retMsg}]---" 

        if [ ${tAllErrFlag} -eq 1 ];then
            retMsg=$(restartIF "${tIFVal_a[${i}]}")
            retStat=$?
            if [ ${retStat} -eq 0 ];then
                writeLog "${tmpDebugLevel}" "${tLevelVal2}" 2 " interface=[${tIFVal_a[${i}]}],restart success"
            else
                writeLog "${tmpDebugLevel}" "${tLevelVal1}" 2 " interface=[${tIFVal_a[${i}]}],restart unsuccessful!!!!!!!!!"
                writeLog "${tmpDebugLevel}" "${tLevelVal4}" 2 " interface=[${tIFVal_a[${i}]}], restart debug return msg=[${retMsg}]\n\n"

            fi
        fi
    done

done



writeLog "${tmpDebugLevel}" "${tLevelVal2}" 2 "script [ $0 ] runs complete!!\n\n"




exit 0
