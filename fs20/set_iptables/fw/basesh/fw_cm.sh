#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20190519
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#       Read the configuration file and configure the firewall
#
#    
#revision history:
#   v0.0.0.1 @ 20190519
#   2019-09-23 modify v0.0.0.1 version to V20.01.000
#       
#
#############################################################################



if [ $# -ne 1 ];then

    echo -e "\n\tError: input like [$0 <server_flag>]!!\n"
    exit 1
fi

tSerFlag="$1"

baseDir=$(dirname $0)
funcFile="${baseDir}/functions"

if [ ! -e ${funcFile} ];then
    echo -e "\n\tError: File [${funcFile}] does not exist!!\n"
    exit 1
fi

. ${funcFile}

echo -e "\n\t\e[1;31mdebugFlag=[${debugFlag}]\e[0m"
echo -e "\t\e[1;31menablePing=[${enablePing}]\e[0m"
echo -e "\t\e[1;31menInterSsh=[${enInterSsh}]\e[0m"
echo -e "\t\e[1;31mbindNICByIP=[${bindNICByIP}]\e[0m"

#--------------------------------------------------------------------------------
# new_fw_onerule_op( outPrtFlag, server_opFlag, op_protocol, NIC_name, local_ip:port, remote_ip:port )
#----------------------------------------------------------------------
# input:
#-------
#   outPrtFlag:        0:OUTPUT,INPUT; 1:OUTPUT; 2:INPUT 
#   server_opFlag      0:client; 1:server; 2:client,server; 3:stat null
#   op_protocol        tcp,upd,all
#   NIC_name           Network card name
#   local_Addr         local_ip:loca_port
#   remote_addr        remote_ip:remote_port
#----------------------------------------------------------------------
# output:
#-------
#   error msg OR null
#----------------------------------------------------------------------
# return:
#-------
#          0:      success
#      other:      error
# 
#--------------------------------------------------------------------------------

# Initiate Server.
FW_INIT

#Set the entry rules in the configuration file
if [ "${tSerFlag}" == "ms" ];then
    tdStr="${cfg_rule_items_qx}"
elif [ "${tSerFlag}" == "scada" ];then
    tdStr="${cfg_rule_items_scada}"
    tsshStr="${cfg_rule_ssh_scada}"
elif [ "${tSerFlag}" == "ps1" ];then
    tdStr="${cfg_rule_items_ps1}"
    tsshStr="${cfg_rule_ssh_ps1}"
elif [ "${tSerFlag}" == "ps2" ];then
    tdStr="${cfg_rule_items_ps2}"
    tsshStr="${cfg_rule_ssh_ps2}"
elif [ "${tSerFlag}" == "wk" ];then
    tdStr="${cfg_rule_items_wk}"
    tsshStr="${cfg_rule_ssh_wk}"
else
    echo -e "\n\t\e[1;31mError:in [$0]\e[0m tSerFlag [ ${tSerFlag} ] is not recognized!!\n"

fi

if [[ ! -z "${enInterSsh}" && ${enInterSsh} -eq 1 ]];then

    if [[ ! -z "${tsshStr}" ]];then

        cfg_ssh_items=$(convertVLineToSpace "${tsshStr}") 
        for titem in ${cfg_ssh_items}
        do
            tfiledNum=$(echo "${titem}"|awk -F'/' '{print NF}')
            if [ ${tfiledNum} -ne 6 ];then
                echo -e "\n\t[${titem}] format error\n"
                continue
            fi
            tPrtFlag=$(echo "${titem}"|cut -d '/' -f 1)
            tSrvOp=$(echo "${titem}"|cut -d '/' -f 2)
            tprotocol=$(echo "${titem}"|cut -d '/' -f 3)
            tNICname=$(echo "${titem}"|cut -d '/' -f 4)
            tLocalAddr=$(echo "${titem}"|cut -d '/' -f 5)
            tRemoteAddr=$(echo "${titem}"|cut -d '/' -f 6)
            new_fw_onerule_op "${tPrtFlag}" "${tSrvOp}" "${tprotocol}" "${tNICname}" "${tLocalAddr}" "${tRemoteAddr}"
        done

    fi

fi

#echo "tSerFlag=[${tSerFlag}]"
#echo "tdStr=[${tdStr}]"

cfg_rule_items=$(convertVLineToSpace "${tdStr}") 
for titem in ${cfg_rule_items}
do
    tfiledNum=$(echo "${titem}"|awk -F'/' '{print NF}')
    if [ ${tfiledNum} -ne 6 ];then
        echo -e "\n\t[${titem}] format error\n"
        continue
    fi
    tPrtFlag=$(echo "${titem}"|cut -d '/' -f 1)
    tSrvOp=$(echo "${titem}"|cut -d '/' -f 2)
    tprotocol=$(echo "${titem}"|cut -d '/' -f 3)
    tNICname=$(echo "${titem}"|cut -d '/' -f 4)
    tLocalAddr=$(echo "${titem}"|cut -d '/' -f 5)
    tRemoteAddr=$(echo "${titem}"|cut -d '/' -f 6)
    new_fw_onerule_op "${tPrtFlag}" "${tSrvOp}" "${tprotocol}" "${tNICname}" "${tLocalAddr}" "${tRemoteAddr}"
done


# Save it.
FW_SAVE

# View it.
FW_VIEW

echo -e "\n"
exit 0

