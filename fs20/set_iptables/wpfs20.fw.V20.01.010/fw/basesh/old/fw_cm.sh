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

fwcm_shName="$0"
fwcm_inParNum="$#"
fwcm_baseDir=$(dirname $0)
fwcm_serFlag="$1"


function F_fwcm_checkAndLoad()
{
    [ -z "${g_logDir}" ] && g_logDir="${fwcm_baseDir}/../log"
    [ -z "${g_logName}" ] && g_logName="${g_logDir}/$(date +%Y%m%d).log"
    [ ! -d "${g_logDir}" ] && mkdir -p "${g_logDir}"

    if [ ${fwcm_inParNum} -ne 1 ];then

        echo -e "\n\tError: input like [${fwcm_shName} <server_flag>]!!\n" | tee -a "${g_logName}"
        exit 1
    fi


    funcFile="${fwcm_baseDir}/functions"

    if [ ! -e ${funcFile} ];then
        echo -e "\n\tError: File [${funcFile}] does not exist!!\n" | tee -a "${g_logName}"
        exit 1
    fi

    . ${funcFile}

    #Set the entry rules in the configuration file
    if [ "${fwcm_serFlag}" == "ms" ];then
        fwcm_curRule_item="${cfg_rule_items_qx}"
        fwcm_curRule_iptb="${iptb_dir_rule_qx}"
    elif [ "${fwcm_serFlag}" == "scada" ];then
        fwcm_curRule_item="${cfg_rule_items_scada}"
        fwcm_curSsh_item="${cfg_rule_ssh_scada}"
        fwcm_curRule_iptb="${iptb_dir_rule_scada}"
    elif [ "${fwcm_serFlag}" == "ps1" ];then
        fwcm_curRule_item="${cfg_rule_items_ps1}"
        fwcm_curSsh_item="${cfg_rule_ssh_ps1}"
        fwcm_curRule_iptb="${iptb_dir_rule_ps1}"
    elif [ "${fwcm_serFlag}" == "ps2" ];then
        fwcm_curRule_item="${cfg_rule_items_ps2}"
        fwcm_curSsh_item="${cfg_rule_ssh_ps2}"
        fwcm_curRule_iptb="${iptb_dir_rule_ps2}"
    elif [ "${fwcm_serFlag}" == "wk" ];then
        fwcm_curRule_item="${cfg_rule_items_wk}"
        fwcm_curSsh_item="${cfg_rule_ssh_wk}"
        fwcm_curRule_iptb="${iptb_dir_rule_wk}"
    else
        echo -e "\n\t\e[1;31mError:in [$0]\e[0m fwcm_serFlag [ ${fwcm_serFlag} ] is not recognized!!\n" | tee -a "${g_logName}"

    fi

    return 0
}


function F_fwcm_echoFlag()
{
    echo -e "\n\t\e[1;31mdebugFlag=[${debugFlag}]\e[0m" | tee -a "${g_logName}"
    echo -e "\t\e[1;31menablePing=[${enablePing}]\e[0m" | tee -a "${g_logName}"
    echo -e "\t\e[1;31menInterSsh=[${enInterSsh}]\e[0m" | tee -a "${g_logName}"
    echo -e "\t\e[1;31mbindNICByIP=[${bindNICByIP}]\e[0m" | tee -a "${g_logName}"

    return 0
}


function F_fwcm_doIptbItem()
{

    if [[ ! -z "${fwcm_curRule_iptb}" ]];then

        local cfg_iptb_items; local titem; local tnaa;

        echo "${fwcm_curRule_iptb}"|while read tnaa
        do
            titem=$(echo "${tnaa}"|sed 's/^\s\+//g;s/\s\+$//g')
            [ -z "${titem}" ] && continue
            F_ECHO_DO "${titem}"
        done
    fi


    return 0
}


    #--------------------------------------------------------------------------------
    # F_new_fw_onerule_op( outPrtFlag, server_opFlag, op_protocol, NIC_name, local_ip:port, remote_ip:port )
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

function F_fwcm_doSshItem()
{

    if [[ ! -z "${enInterSsh}" && ${enInterSsh} -eq 1 ]];then

        if [[ ! -z "${fwcm_curSsh_item}" ]];then

            local cfg_ssh_items; local titem; local tfiledNum;
            cfg_ssh_items=$(F_convertVLineToSpace "${fwcm_curSsh_item}") 
            for titem in ${cfg_ssh_items}
            do
                tfiledNum=$(echo "${titem}"|awk -F'/' '{print NF}')
                if [ ${tfiledNum} -ne 6 ];then
                    echo -e "\n\t[${titem}] format error\n" | tee -a "${g_logName}"
                    continue
                fi
                tPrtFlag=$(echo "${titem}"|cut -d '/' -f 1)
                tSrvOp=$(echo "${titem}"|cut -d '/' -f 2)
                tprotocol=$(echo "${titem}"|cut -d '/' -f 3)
                tNICname=$(echo "${titem}"|cut -d '/' -f 4)
                tLocalAddr=$(echo "${titem}"|cut -d '/' -f 5)
                tRemoteAddr=$(echo "${titem}"|cut -d '/' -f 6)
                F_new_fw_onerule_op "${tPrtFlag}" "${tSrvOp}" "${tprotocol}" "${tNICname}" "${tLocalAddr}" "${tRemoteAddr}"
            done

        fi

    fi

    return 0
}


function F_fwcm_doCmItem()
{
    #echo "fwcm_serFlag=[${fwcm_serFlag}]" | tee -a "${g_logName}"
    #echo "fwcm_curRule_item=[${fwcm_curRule_item}]" | tee -a "${g_logName}"

    cfg_rule_items=$(F_convertVLineToSpace "${fwcm_curRule_item}") 
    for titem in ${cfg_rule_items}
    do
        tfiledNum=$(echo "${titem}"|awk -F'/' '{print NF}')
        if [ ${tfiledNum} -ne 6 ];then
            echo -e "\n\t[${titem}] format error\n" | tee -a "${g_logName}"
            continue
        fi
        tPrtFlag=$(echo "${titem}"|cut -d '/' -f 1)
        tSrvOp=$(echo "${titem}"|cut -d '/' -f 2)
        tprotocol=$(echo "${titem}"|cut -d '/' -f 3)
        tNICname=$(echo "${titem}"|cut -d '/' -f 4)
        tLocalAddr=$(echo "${titem}"|cut -d '/' -f 5)
        tRemoteAddr=$(echo "${titem}"|cut -d '/' -f 6)
        F_new_fw_onerule_op "${tPrtFlag}" "${tSrvOp}" "${tprotocol}" "${tNICname}" "${tLocalAddr}" "${tRemoteAddr}"
    done

    return 0
}



function F_fwcm_doIt()
{


    # Initiate Server.
    FW_INIT

    F_fwcm_doSshItem

    F_fwcm_doCmItem

    F_fwcm_doIptbItem

    # Save it.
    FW_SAVE

    # View it.
    FW_VIEW

    echo -e "\n" | tee -a "${g_logName}"

    return 0
}



F_fwcm_main()
{

    F_fwcm_checkAndLoad

    F_fwcm_echoFlag

    F_fwcm_doIt
    
    return 0
}

F_fwcm_main

exit 0

