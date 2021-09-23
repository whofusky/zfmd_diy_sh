#!/bin/bash

tPwd=/zfmd/syskeeper2000
tExe=serverstart.sh

if [ ! -d "${tPwd}" ];then
    echo -e "\n\tERROR:dir [${tPwd}] not exist!\n"
    exit 1
fi

if [ ! -f "${tExe}" ];then
    echo -e "\n\tERROR:file [${tPwd}/${tExe}] not exist!\n"
    exit 2
fi
cd "${tPwd}"
./${tExe}
