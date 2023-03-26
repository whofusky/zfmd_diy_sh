#!/bin/bash

export BASH_INI_PARSER_DEBUG=1

TEST_FILE="${1:-aits.ini}"

baseDir=$(dirname $0)

#parseToolFile="${baseDir}/../bash-ini-parser"
parseToolFile="${baseDir}/../bash-ini-parser.sed"

iniIdex=0



function F_check()
{
    if [ ! -f "${TEST_FILE}" ];then
        echo -e "ERROR:file [${TEST_FILE}] not exist!\n"
        exit 1
    fi
    if [ ! -f "${parseToolFile}" ];then
        echo -e "ERROR:file [${parseToolFile}] not exist!\n"
        exit 1
    fi
    source ${parseToolFile}

    #parsing ini file
    F_ini_cfg_parser "${iniIdex}" "$TEST_FILE"

    return 0
}

function F_print_parse()
{
    local t="g_bash_ini_${iniIdex}[*]"
    echo --parse result-- 
    echo "------------------------------------------------------------------------------"
        OLDIFS="$IFS"
        IFS=$'\n'
        echo "${!t}"
        IFS="$OLDIFS"
    echo "------------------------------------------------------------------------------"
    echo --end--
}

function F_print_write()
{
    echo -e "\n"
    echo "F_ini_cfg_writer ${iniIdex} print"
    echo "------------------------------------------------------------------------------"
    F_ini_cfg_writer "${iniIdex}"
    echo "------------------------------------------------------------------------------"
    echo -e "\n"
}


#F_print_key "section" "key"
function F_print_key()
{
    local ret
    #F_ini_is_section "${iniIdex}" "${1}"; ret=$?
    F_ini_enable_section "${iniIdex}" "${1}" ; ret=$?

    #echo "${ret}"

    [ ${ret} -ne 0 ] && return ${ret}

    #local tpre="PREFIX_${iniIdex}"
    #${!tpre}${1} 

    F_ini_is_key "${2}"; ret=$?

    #echo "${ret}"

    [ ${ret} -ne 0 ] && return ${ret}
    #[ ${ret} -eq 0 ] && echo "${!2}"

    echo "[${1}] -> ${2}=${!2}"
}




main()
{
    F_check

    #return 0

    F_print_parse
    local section="PROD_COMPO_DESC"

    F_print_key "${section}" "copyright"
    F_print_key "${section}" "product_name"
    F_print_key "${section}" "product_ver"
    F_print_key "${section}" "dev_soft_1"
    F_print_key "${section}" "fuskytest"
    F_print_key "ID" "pkg_server"

    product_name="wpfs20111"
    fusky=test
    F_ini_cfg_update "${iniIdex}" "${section}" "product_name"
    F_ini_cfg_update "${iniIdex}" "${section}" "fusky"

    F_print_key "${section}" "product_name"
    #declare -f cfg_section_PROD_COMPO_DESC

    second_id="04"
    F_ini_cfg_update "${iniIdex}" "ID_1" "second_id"

    F_print_write
    
    return 0
}
main
