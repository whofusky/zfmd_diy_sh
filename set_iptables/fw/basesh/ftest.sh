#!/bin/bash

#fushikai test shell file @ 20190514


baseDir=$(dirname $0)
funcFile="${baseDir}/functions"

if [ ! -e ${funcFile} ];then
    echo -e "\n\tError: File [${funcFile}] does not exist!!\n"
    exit 1
fi

. ${funcFile}

echo "---baseDir=[${baseDir}],funcFile=[${funcFile}]---"

echo "----debugFlag=[${debugFlag}]--"

function ff1()
{
    echo "---in ff1 input number=[$#]---"

    local i=1
    for tnaa in "$@"
    do
        echo "--in ff1--${i}=[${tnaa}]---"
        if [ -z "${tnaa}" ];then
            echo "--in ff1--${i}= is null---"
        fi 
        echo ""
        let i++
    done
    return 0
}

function ff2()
{
    echo "---in ff2 input number=[$#]---"
    local i=1
    for tnaa in "$@"
    do
        echo "--in ff2--${i}=[${tnaa}]---"
        if [ -z "${tnaa}" ];then
            echo "--in ff2--${i}= is null---"
        fi 
        echo ""
        let i++
    done
    echo "========================================"
    ff1 "$@"
    return 0
}

a1="1"
#a2="2"
a3="3"

ff2 1 2 3 "" 5 "" 6
exit 0
#ff2 "${a1}" "${a2}" "${a3}"
echo "METE_LOCAL_INTERNET_IP=[${METE_LOCAL_INTERNET_IP}]"
findNICbyIP "192.168.2.73"

echo -e "\n"
WS_CLIENTS="
    197.167.17.57/197.167.17.17:8081|
	|1	00.110.120.40/100.110.120.100:80
    |100.110.120. 40/10 0.110.120.1  00   :4200
"
SCADA_CLIENTS=$(convertVLineToSpace "${SCADA_CLIENTS}")
echo "--------------------"
for i in ${SCADA_CLIENTS}
do
    echo $i
done
echo "--------------------"

echo -e "\n"
exit 0

tlocalIP=192.168.2.73
tserverIP=192.168.2.200
FW_FTP_CLIENT_20 ${tlocalIP} ${tserverIP}
FW_FTP_CLIENT_21 ${tlocalIP} ${tserverIP}
echo ""
FW_FTP_CLIENT_20  ${tserverIP}
FW_FTP_CLIENT_21  ${tserverIP}

tRemoteIP1=42.121.65.50
tRemoteIP2=182.254.227.250

server_opFlag=1
op_protocol="tcp"
#retMsg=$(get_fw_CorS_str 1 ${server_opFlag} ${op_protocol} ${tlocalIP} ${tserverIP})

#retMsg=$(get_fw_CorS_str 1 ${server_opFlag} ${op_protocol} ":21")
#retMsg=$(get_fw_CorS_str 1 "1" "${op_protocol}" "${tlocalIP}" "${tRemoteIP1}:20")
#retMsg=$(get_fw_CorS_str 1 "0" "${op_protocol}" "${tlocalIP}" "${tRemoteIP1}:21")
retMsg=$(get_fw_CorS_str 1 "0" "${op_protocol}" "${tlocalIP}" "${tRemoteIP1}:1024-65535")
retStat=$?

echo "-----retStat=[${retStat}]-----"
if [ ${retStat} -eq 0 ];then
    tOUTPUT=$(echo "${retMsg}"|awk -F'|' '{print $1}')
    tINPUT=$(echo "${retMsg}"|awk -F'|' '{print $2}')

    echo "tOUTPUT=[${tOUTPUT}]"
    echo "tINPUT=[${tINPUT}]"

fi
