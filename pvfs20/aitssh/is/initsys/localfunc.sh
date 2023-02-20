#!/bin/bash
#
##############################################################################
#
#
#
#
##############################################################################
#





function F_needRootUser()
{
    #User restrictions: only the root user can operate
    local tUID=$(id -u)
    if [[ -z "${tUID}" || ${tUID} -ne 0 ]];then
        F_writeLog ${ERROR} "Please execute as root! the current user is ${USER}\n"
        exit 1
    fi

    return 0
}

function F_judgeOsSysType()
{
    local initS="$(ps -p 1|tail -1|awk '{print $NF}')"
    g_init_type="init"
    [ "x${initS}" = "xsystemd" ] && g_init_type="systemd"


    g_sys_name="centos78"
    local tmpType="$(uname -r)"
    #centos78:   3.10.0-1127.el7.x86_64
    #rhe67:      2.6.32-573.el6.x86_64
    #unikylin33: 3.10.0-1062.9.1.ky3.kb2.pg.x86_64
    tmpType="${tmpType%.*}"
    if [ "x${tmpType}" = "x3.10.0-1127.el7" ];then
        g_sys_name="centos78"
    elif [ "x${tmpType}" = "x2.6.32-573.el6" ];then
        g_sys_name="redhat67"
    elif [ "x${tmpType}" = "x3.10.0-1062.9.1.ky3.kb2.pg" ];then
        g_sys_name="unikylin33"
    else
        F_writeLog $ERROR "The current function only supports system centos78,redhat67,unikylin33"
        exit 1
    fi

    export g_init_type
    export g_sys_name

    #hostnamectl |grep Operating|awk -F'[:(]' '{print $2}'|sed -e 's/^\s\+//g;s/\s\+$//g'
    return 0
}
