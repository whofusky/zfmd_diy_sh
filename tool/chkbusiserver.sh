#!/bin/bash
#
##############################################################################
#author  :  fu.sky
#date    :  2022-09-29_08:51:29
#desc    : 
#           查看业务清单2.0的托管服务器是否能连接得上
#
##############################################################################
#

function F_check()
{
    echo -e "\n\t查看2.0业务清单托管服务器是否能远程连接得上..."
    nc -vz 117.34.91.13 19113
    return 0
}

main()
{
    F_check
    return 0
}
main