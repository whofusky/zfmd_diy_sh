#!/bin/bash
#
##############################################################################
#
#
#
#
##############################################################################
#





#判断当前执行用户是否为root用户,不是则退出
function F_needRootUser()
{
    #User restrictions: only the root user can operate
    local tUID=$(id -u)
    if [[ -z "${tUID}" || ${tUID} -ne 0 ]];then
        F_writeLog ${ERROR} "Please execute as root! the current user is ${USER}\n"
        exit 1
    fi

    #return 0
}



#判断当前操作系统类型是否为的要求的类型,不是则退出;
#    符合要求则赋值g_sys_type 和 g_sys_name
function F_judgeOsSysType()
{
    local initS="$(ps -p 1|tail -1|awk '{print $NF}')"
    g_sys_type="${cmpt_os_type_init:=init}"
    [ "x${initS}" = "xsystemd" ] && g_sys_type="${cmpt_os_type_systemd:=systemd}"


    g_sys_name="${cmp_os_name_ct78:=centos78}"
    local tmpType="$(uname -r)"
    #centos78:   3.10.0-1127.el7.x86_64
    #rhe67:      2.6.32-573.el6.x86_64
    #unikylin33: 3.10.0-1062.9.1.ky3.kb2.pg.x86_64
    tmpType="${tmpType%.*}"
    if [ "x${tmpType}" = "x3.10.0-1127.el7" ];then
        g_sys_name="${cmp_os_name_ct78}"
    elif [ "x${tmpType}" = "x2.6.32-573.el6" ];then
        g_sys_name="${cmpt_os_name_rh67:=redhat67}"
    elif [ "x${tmpType}" = "x3.10.0-1062.9.1.ky3.kb2.pg" ];then
        g_sys_name="${cmpt_os_name_uk33:=unikylin33}"
    else
        F_writeLog $ERROR "The current function only supports system ${cmp_os_name_ct78},redhat67,unikylin33"
        exit 1
    fi

    export g_sys_type
    export g_sys_name

    #hostnamectl |grep Operating|awk -F'[:(]' '{print $2}'|sed -e 's/^\s\+//g;s/\s\+$//g'
    #return 0
}

#init 类型的系统关闭系统服务
function F_init_shutdownservice()
{
    [ $# -lt 1 ] && return 0
    while [ $# -gt 0 ]
    do
        service "$1" status >/dev/null 2>&1
        if [ $? -eq 0 ];then
            service "$1" stop
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| service $1 stop"
        fi
        chkconfig --list "$1" >/dev/null 2>&1
        if [ $? -eq 0 ];then
            chkconfig "$1" off
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| chkconfig $1 off"
        fi
        shift
    done
}

#init 类型的系统打开系统服务
function F_init_openservice()
{
    [ $# -lt 1 ] && return 0

    while [ $# -gt 0 ]
    do
        chkconfig --list "$1" >/dev/null 2>&1
        if [ $? -eq 0 ];then
            chkconfig "$1" on
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| chkconfig $1 on"
            service "$1" start >/dev/null 2>&1
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| service $1 start"
        else
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|WARNING service $1 not exist!"
        fi
        shift
    done
}



#systemd 类型的系统关闭系统服务
function F_systemd_shutdownservice()
{
    [ $# -lt 1 ] && return 0
    local tmpRet
    while [ $# -gt 0 ]
    do
        tmpRet=$(systemctl is-active "$1" 2>/dev/null)
        if [ "x${tmpRet}" = "xactive" ];then
            systemctl stop "$1"
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| systemctl stop $1"
        fi
        tmpRet=$(systemctl is-enabled "$1" 2>/dev/null)
        if [ "x${tmpRet}" = "xenabled" ];then
            systemctl disable "$1"
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| systemctl disable $1"
        fi
        shift
    done
}


#systemd 类型的系统打开系统服务
function F_systemd_openservice()
{
    [ $# -lt 1 ] && return 0
    local tmpRet
    while [ $# -gt 0 ]
    do
        tmpRet=$(systemctl is-active "$1" 2>/dev/null)
        if [ "x${tmpRet}" = "xinactive" ];then
            systemctl start "$1"
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| systemctl start $1"
        fi
        tmpRet=$(systemctl is-enabled "$1" 2>/dev/null)
        if [ "x${tmpRet}" = "xdisabled" ];then
            systemctl enable "$1"
            F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| systemctl enable $1"
        fi
        shift
    done
}


###########################################################################
#        以下是与系统相关的函数:
#           注意,函数名F_xxxx_name中的xxx是系统名
#                脚本根据当前系统名称拼装函数名，然后调用
#                拼装后的函数进行相应功能处理
#      
###########################################################################

########################### centos78 ######################################
function F_centos78_test()
{
    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| test"
    local i
    for((i=1;i<=$#;i++));do
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|para[$i]=[${!i}]"
    done
    #return 0
}

#根据入参par1="service1|service2|..."对多个系统服务进行关闭
function F_centos78_shutdownservice()
{
    if [ $# -ne 1 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|input para nums not eq 1!"
        return 1
    fi
    if [ -z "$1" ];then
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|input para 1 is null"
        return 0
    fi
    local tmpsc strs tfun
    tfun="$(declare -F F_convertVLineToSpace)"
    if [ -z "${tfun}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|function [F_convertVLineToSpace] not defined!"
        return 1
    fi
    #将入参的|转化为空格
    strs=$(F_convertVLineToSpace "$1")
    for tmpsc in ${strs}
    do
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| servicename=[${tmpsc}]"
        #F_systemd_shutdownservice "${tmpsc}"
    done

}

########################### redhat67 ######################################
function F_redhat67_test()
{
    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| test"
    local i
    for((i=1;i<=$#;i++));do
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|para[$i]=[${!i}]"
    done
    return 3
}

#根据入参par1="service1|service2|..."对多个系统服务进行关闭
function F_redhat67_shutdownservice()
{
    if [ $# -ne 1 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|input para nums not eq 1!"
        return 1
    fi
    if [ -z "$1" ];then
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|input para 1 is null"
        return 0
    fi
    local tmpsc strs tfun
    tfun="$(declare -F F_convertVLineToSpace)"
    if [ -z "${tfun}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|function [F_convertVLineToSpace] not defined!"
        return 1
    fi
    #将入参的|转化为空格
    strs=$(F_convertVLineToSpace "$1")
    for tmpsc in ${strs}
    do
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| servicename=[${tmpsc}]"
        #F_init_shutdownservice "${tmpsc}"
    done

}


########################### unikylin33 ######################################
function F_unikylin33_test()
{
    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| test"
    for((i=1;i<=$#;i++));do
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|para[$i]=[${!i}]"
    done
    #return 0
}

#根据入参par1="service1|service2|..."对多个系统服务进行关闭
function F_unikylin33_shutdownservice()
{
    if [ $# -ne 1 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|input para nums not eq 1!"
        return 1
    fi
    if [ -z "$1" ];then
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|input para 1 is null"
        return 0
    fi
    local tmpsc strs tfun
    tfun="$(declare -F F_convertVLineToSpace)"
    if [ -z "${tfun}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|function [F_convertVLineToSpace] not defined!"
        return 1
    fi
    #将入参的|转化为空格
    strs=$(F_convertVLineToSpace "$1")
    for tmpsc in ${strs}
    do
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| servicename=[${tmpsc}]"
        #F_systemd_shutdownservice "${tmpsc}"
    done

}



