#!/bin/bash


    #while read rTime rEc rPwrat rPwrreact rSpd rState rFault
    #do
    #    echo ""

    #    #16,17 ->  (16)(17)
    #    echo "rFault1=[${rFault}]"
    #    ##rFault=$(echo "${rFault}"|sed 's/\(\s\+0\|0\s\+\|\s\+0\s\+\)//g')
    #    #rFault=$(echo "${rFault}"|sed 's/\(\s\+0\|0\s\+\)//g')
    #    #echo "rFault2=[${rFault}]"
    #    #rFault=$(echo "${rFault}"|sed -e 's/\(\s\+0\|0\s\+\)//g;s/\s\+/,/g')
    #    #echo "rFault3=[${rFault}]"

    #    tFault="'("$(echo "${rFault}"|sed 's/\(\s\+0\|0\s\+\)//g;s/\s\+/,/g;s/\s*,\s*/)(/g')")'"
    #    echo "tFault=[${tFault}]"

    #done<tmp_fj_EC_45.bak

    #g_turbn_exception_ec="0, 3, 20-30,40,45 "
    g_turbn_exception_ec=""

    kk=$(echo ${g_turbn_exception_ec}|sed 's/\s\+//g;s/,/ /g')

    echo "g_turbn_exception_ec=[${g_turbn_exception_ec}]"
    echo "kk=[${kk}]"

    tnum=0
    g_turbn_exception_ec=""
    for i in ${kk}
    do
        tnum=$(echo "${i}"|sed -n '/-\+/p'|wc -l)
        if [ ${tnum} -gt 0 ];then
            ttStr=$(echo "${i}"|sed 's/-\+/ /g')
            for j in $(seq ${ttStr})
            do
                g_turbn_exception_ec="${g_turbn_exception_ec} ${j}"
            done
        else
            g_turbn_exception_ec="${g_turbn_exception_ec} ${i}"
        fi
    done
    g_turbn_exception_ec=$(echo "${g_turbn_exception_ec}"|sed 's/^\s\+//g')

    echo "new g_turbn_exception_ec=[${g_turbn_exception_ec}]"
    
    [ -z "${g_turbn_exception_ec}" ] && echo " g_turbn_exception_ec is null"


