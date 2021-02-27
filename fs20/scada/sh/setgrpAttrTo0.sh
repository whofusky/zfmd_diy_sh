#!/bin/bash
#
######################################################################
#
#author:fu.sky
#
#date  :2020-12-23
#
#dsc   : modify scdCfg.xml grpAttr="3" to grpAttr="0"
#
######################################################################
#

aShName="$0"
exeName="${aShName##*/}"

function F_help()
{
    echo -e "\n\tplease input like:\n\t  ${exeName}  <scada_cfg_file_name>\n"
    return 0
}


if [ $# -lt 1 ];then
    F_help
    exit 1
fi

edFile="$1"

if [ ! -f "${edFile}" ];then
    echo -e "\n\t\e[1;31mERROR\e[0m: file [${edFile}] not exist!\n"
    exit 2
fi

num=$(sed -n '/grpAttr="3"/p' "${edFile}"|wc -l)
if [ ${num} -lt 1 ];then
    echo -e "\n\t file [ ${edFile} ] not have grpAttr=\"3\" need to modify\n"
    exit 0
fi

sed -i 's/grpAttr="3"/grpAttr="0"/g' "${edFile}"

echo -e "\n\t file [${edFile}] modify grpAttr=\"3\" to grpAttr=\"0\" completely\n"



exit 0
