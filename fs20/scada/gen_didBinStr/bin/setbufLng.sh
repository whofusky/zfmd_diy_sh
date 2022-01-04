#!/bin/bash
#
################################################################################
#
#author: fusky
#date  : 2020-12-07
#Dsc   :
#       modify scdCfg.xml bufLng="256"  to bufLng="255"
#
#
################################################################################


baseDir=$(dirname $0)

if [ $# -lt 1 ];then
    echo -e "\n\t\e[1;31mERROR:\e[0m input like:\n\t\t$0 <scada_cfg_file>\n"
    exit 1
fi

edFile=$1

if [ ! -f "${edFile}" ];then
    echo -e "\n\t\e[1;31mERROR:\e[0m file [ ${edFile} ] not exist!\n"
    exit 2
fi

echo "sed -i 's/bufLng=\"256\"/bufLng=\"255\"/g' ${edFile}"
sed -i 's/bufLng="256"/bufLng="255"/g' ${edFile}

echo -e "\n\t $0 exe complete!\n"

exit 0
