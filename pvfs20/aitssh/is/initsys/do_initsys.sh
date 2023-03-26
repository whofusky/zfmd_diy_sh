#!/bin/bash
#
########################################################################
#author        :    fushikai
#creation date :    2022-12-19
#linux_version :    Red Hat / UniKylin
#dsc           :
#       Initialize the system environment
#    
#revision history:
#
#   v20.000.001 2022-12-19: pvfs20 basic
#
########################################################################

#$0 serv_type 固定网卡号 授权文件(带路径)

thisObj="$0"; inOpType="$1"; inFile="$2"
inNumbs="$#"


shName="${thisObj##*/}"




#baseDirM=$(dirname $0)

########## 定义可以支持操作系统的 名称 和类型 ##########

#cmpt: compatible

cmpt_os_type_init="init"; cmpt_os_type_systemd="systemd"

cmpt_os_name_rh67="redhat67"; cmp_os_name_ct78="centos78";
cmpt_os_name_uk33="unikylin33"

########################################################

########## 定义ini解析接口2套接口对应的序号 ##########

gSelfIniIdx=0  #ini接口中0下标的方法解析软件自己的ini配置文件
gParaIniIdx=1  #ini接口中1下标的方法解析入参是ini文件

########################################################


NOOUT=0 ; levelName[0]="NOOUT";
ERROR=1 ; levelName[1]="ERROR";
INFO=2  ; levelName[2]="INFO" ;
DEBUG=3 ; levelName[3]="DEBUG";

#all_levelName=$(declare -p levelName)

OUT_LOG_LEVEL=${DEBUG}


g_baseicDir="$(cd "$(dirname "$0")" >/dev/null 2>&1 || exit; pwd -P)" 
export g_baseicDir

logDir="${g_baseicDir}/log"
[ ! -d "${logDir}" ] && mkdir -p "${logDir}"
logFile="${logDir}/${shName}.log"







function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
{

    [ $# -lt 2 ] && return 1

    #特殊调试时用
    local print_to_stdin_flag=1  # 0:可能输出到日志文件; 1: 输出到屏幕; 2可能同时输出到屏幕和日志文件

    #input log level
    local i="${1-3}"   
    

    ##debug to open this
    #[ $(echo "${i}"|sed -n '/^[0-9]*$/p' |wc -l) -eq 0 ] && i=${DEBUG}
    #[ $(echo "${NOOUT}<=${i} && ${i}<=${DEBUG}"|bc) -eq 0 ] && i=${DEBUG}


    [ ${i} -gt ${OUT_LOG_LEVEL:=3} ] && return 0

    local puttxt="$2"

    #echo "fusktest:puttxt=[${puttxt}]"

    # 1.换行符;2.空; 3.多个-;
    # 以上作一情况 则直接输出而不在输出内容之前添加日期等内容
    local tflag=$(echo "${puttxt}"|sed -n '/^\s*\(\(\\n\)\+\)*$\|^\s*-\+$/p'|wc -l)

    #没有设置日志文件时默认也是输出到屏幕
    [ -z "${logFile}" ] && print_to_stdin_flag=1

    local timestring
    local timeSt
    if [ ${tflag} -eq 0 ];then
        timestring="$(date +%F_%T.%N)"
        timeSt="$(date +%T.%N)"
    fi
        

    if [ ${print_to_stdin_flag} -eq 1 ];then
        if [ ${tflag} -gt 0 ];then
            echo -e "${puttxt}"
        else
            echo -e "${timestring}|${levelName[$i]}|${puttxt}"
        fi
        return 0
    fi

    [ -z "${logDir}" ] &&  logDir="${logFile%/*}"
    if [ "${logDir}" = "${logFile}" ];then
        logDir="./"
    elif [ ! -d "${logDir}" ];then
        mkdir -p "${logDir}"
    fi

    if [ ${tflag} -gt 0 ];then
        if [ "${print_to_stdin_flag}x" = "2x" ];then
            echo -e "${puttxt}"|tee -a  "${logFile}"
        else
            echo -e "${puttxt}" >> "${logFile}"
        fi
    else
        if [ "${print_to_stdin_flag}x" = "2x" ];then
            echo -e "${timeSt}|${levelName[$i]}|${puttxt}"
            echo -e "${timestring}|${levelName[$i]}|${puttxt}" >>"${logFile}"
        else
            echo -e "${timestring}|${levelName[$i]}|${puttxt}" >> "${logFile}"
        fi
    fi


    return 0
}


function F_notFileExit() #call eg: notFileExit "file1" "file2" ... "filen"
{
    [ $# -lt 1 ] && return 0
    local tmpS
    while [ $# -gt 0 ]
    do
        tmpS="$1"
        if [ ! -f "${tmpS}" ];then
            F_writeLog "$ERROR" "file [${tmpS}] does not exist!"
            exit 1
        fi
        shift
    done
    return 0
}





#检查并加载相关文件
function F_checkAndLoad()
{
    g_baseFunc="${g_baseicDir}/shfunclib.sh"
    g_localFunc="${g_baseicDir}/localfunc.sh"
    g_parseFunc="${g_baseicDir}/bash-ini-parser"
    g_selfCfg="${g_baseicDir}/my_run_fix.ini"

    F_notFileExit "${g_baseFunc}" "${g_localFunc}" "${g_parseFunc}" "${g_selfCfg}"

    #基本函数
    source "${g_baseFunc}"

    F_shHaveRunThenExit "${shName}"
    F_checkSysCmd "uname"

    #本脚本相关的函数
    source "${g_localFunc}"

    #ini解析公共函数
    source "${g_parseFunc}"

    #fusktest 注释
    F_needRootUser

    #获取g_sys_type 和 g_sys_name
    F_judgeOsSysType

    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|g_sys_type=[${g_sys_type}]"
    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|g_sys_name=[${g_sys_name}]"

    #解析软件自己的ini配置文件
    F_ini_cfg_parser "${gSelfIniIdx}" "${g_selfCfg}"

    return 0
}


#根据系统名称拼装相应的函数名,然后调用拼装后的函数
#usage: call_system_specific_func 函数名 传给函数的参数1 参数2...
#
function call_system_specific_func()
{
    if [ $# -lt 1 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|input para num less 1"
        exit 1
    fi
    local funSuffix="$1"
    shift

    local toCallFunc="F_${g_sys_name:=centos78}_${funSuffix}"
    local funFlag="$(declare -F ${toCallFunc})"
    if [ -z "$funFlag" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|There is no \"${toCallFunc}\" function!"
        return 2
    fi

    ${toCallFunc} "$@"
    return $?
}



function F_ECHO_DO()
{
    local cmd="$*"
    F_writeLog $INFO "$USER@$HOSTNAME@${debugFlag}| ${cmd}"
    if [[ -z "${debugFlag}" || ${debugFlag} -ne 1 ]];then
        ${cmd} 2>&1|tee -a "${logFile}"
    fi
    return 0
}


#根据当前脚本的配置文件中的配置关闭系统服务
function F_closeservice()
{
    local ret funPre i tmpkey

    #判断脚本自己的配置文件中是否有 ${g_sys_name} section
    F_ini_enable_section "${gSelfIniIdx}" "${g_sys_name}" ; ret=$?
    if [ ${ret} -ne 0 ];then
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|section [${g_sys_name}] does not exist in file[${g_selfCfg}]"
        return 1
    fi


    #判断ini配置文件中是否有cls_ser_key_num的key存在 
    F_ini_is_key "cls_ser_key_num" ; ret=$?
    if [ ${ret} -ne 0 ];then
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|section [${g_sys_name}],key cls_ser_key_num does not exist in file[${g_selfCfg}]"
        return 2
    fi

    #循环对cls_ser_key_i进行处理
    for((i=0;i<${cls_ser_key_num};i++));do
        tmpkey="cls_ser_key_${i}"
        F_ini_is_key  "${tmpkey}" ; ret=$?
        [ ${ret} -ne 0 ] && continue

        #调用函数shutdownservice根据配置文件中cls_ser_key_${i}的值将服务进行关闭
        call_system_specific_func "shutdownservice" "${!tmpkey}"
    done

}


#根据当前脚本的配置文件中的配置设置配置文件环境变量
function F_setEvnFileValueBycfg()
{
    local ret funPre i j tedfile

    #判断脚本自己的配置文件中是否有 ${g_sys_name} section
    F_ini_enable_section "${gSelfIniIdx}" "${g_sys_name}" ; ret=$?
    if [ ${ret} -ne 0 ];then
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|section [${g_sys_name}] does not exist in file[${g_selfCfg}]"
        return 1
    fi


    #判断ini配置文件中是否有set_spa_file_num的key存在 
    F_ini_is_key "set_spa_file_num" ; ret=$?
    if [ ${ret} -eq 0 ];then

        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|set_spa_file_num=[${set_spa_file_num}]"

        #有则需要设置用空格分隔的环境变量文件

        #循环对set_spa_file_i进行处理
        for((i=0;i<${set_spa_file_num};i++));do
            
            #判断文件名配置是否存在
            tedfile="set_spa_file_${i}"
            F_ini_is_key "${tedfile}" ; ret=$?
            [ ${ret} -ne 0 ] && continue

            #针对tedfile需要设置多少行值
            local tlineNo tlineKey
            tlineKey="set_spa_f${i}_line_num"
            F_ini_is_key "${tlineKey}" ; ret=$?
            if [ ${ret} -eq 0 ];then
                
                for((j=0;j<${!tlineKey};j++));do

                    local fstKey sndKey cntKey cmtKey lcaKey
                    fstKey="set_spa_f${i}_fst_${j}"
                    sndKey="set_spa_f${i}_scd_${j}"
                    cntKey="set_spa_f${i}_cnt_${j}"
                    cmtKey="set_spa_f${i}_cmt_${j}"
                    lcaKey="set_spa_f${i}_lca_${j}"

                    F_ini_is_key "${fstKey}" ; ret=$?
                    [ ${ret} -ne 0 ] && continue
                    F_ini_is_key "${sndKey}" ; ret=$?
                    [ ${ret} -ne 0 ] && continue
                    F_ini_is_key "${cntKey}" ; ret=$?
                    [ ${ret} -ne 0 ] && continue
                    F_ini_is_key "${cmtKey}" ; ret=$?
                    [ ${ret} -ne 0 ] && continue

                    #F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|F_setEnvSpaceVal [${!tedfile}] [${!fstKey}] ${!sndKey} [${!cntKey}] [${!cmtKey}] [${!lcaKey}]"
                    F_setEnvSpaceVal "${!tedfile}" "${!fstKey}" "${!sndKey}" "${!cntKey}" "${!cmtKey}" "${!lcaKey}"

                done

            fi
        done

    fi


}


function F_test()
{
    call_system_specific_func "test" "a1" "a2" 3 "a4"
    call_system_specific_func "test1" "a1" "a2" 3 "a4"
}

main()
{
    #检查并加载相关文件
    F_checkAndLoad

    #F_test

    #根据当前脚本的配置文件中的配置关闭系统服务
    F_closeservice

    #根据当前脚本的配置文件中的配置设置配置文件环境变量
    F_setEvnFileValueBycfg


    return 0
}


main

exit 0

