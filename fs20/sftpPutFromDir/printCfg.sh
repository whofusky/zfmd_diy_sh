#!/bin/bash

. cfg/cfg.cfg

function F_testPrt()
{
    #echo -e "\ng_curYmd=[${g_curYmd}]"
    #echo -e "g_curY=[${g_curY}],g_curm=[${g_curm}],g_curd=[${g_curd}]\n"

    #echo -e "\ng_tomYmd=[${g_tomYmd}]"
    #echo -e "g_tomY=[${g_tomY}],g_tomm=[${g_tomm}],g_tomd=[${g_tomd}]\n"

    #echo -e "\ng_15mYmd=[${g_15mYmd}]"
    #echo -e "g_15mY=[${g_15mY}],g_15mm=[${g_15mm}],g_15md=[${g_15md}]\n"

    g_do_nums=${#g_src_dir[*]}
    echo -e "\n g_do_nums=[${g_do_nums}]"
    local i=0
    for((i=0;i<${g_do_nums};i++))
    do
        echo -e "\ng_src_dir[$i]=[${g_src_dir[$i]}]"
        echo -e "g_file_name[$i]=[${g_file_name[$i]}]"
        echo -e "g_basicCondition_sec[$i]=[${g_basicCondition_sec[$i]}]"
    done
    echo -e "\n"

    g_do_ser_nums=${#g_ser_ip[*]}
    echo -e "\n g_do_ser_nums=[${g_do_ser_nums}]"
    for((i=0;i<${g_do_ser_nums};i++))
    do
        echo -e "\ng_ser_ip[$i]=[${g_ser_ip[$i]}]"
        echo -e "g_ser_username[$i]=[${g_ser_username[$i]}]"
        echo -e "g_ser_password[$i]=[${g_ser_password[$i]}]"
        echo -e "g_ser_port[$i]=[${g_ser_port[$i]}]"
        echo -e "g_ser_dir[$i]=[${g_ser_dir[$i]}]"
    done
    echo -e "\n"

    return 0
}

main()
{
    F_testPrt
    return 0
}
main
