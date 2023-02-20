#!/bin/bash

TEST_FILE="${1:-aits.ini}"

baseDir=$(dirname $0)

parseToolFile="${baseDir}/../bash-ini-parser"



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
    cfg_parser "$TEST_FILE"

    return 0
}

function F_print_parse()
{
    echo --parse result-- 
    echo "------------------------------------------------------------------------------"
        OLDIFS="$IFS"
        IFS=$'\n'
        echo "${ini[*]}"
        IFS="$OLDIFS"
    echo "------------------------------------------------------------------------------"
    echo --end--
}

function F_print_write()
{
    echo -e "\n"
    echo "cfg_writer print"
    echo "------------------------------------------------------------------------------"
    cfg_writer
    echo "------------------------------------------------------------------------------"
    echo -e "\n"
}


#F_print_key "section" "key"
function F_print_key()
{
    local ret
    #is_ini_cfg "${1}"
    is_section "${1}"; ret=$?

    #echo "${ret}"
    [ ${ret} -ne 0 ] && return ${ret}

    ${PREFIX}${1} 

    #is_ini_cfg "${1}" "${2}"
    is_key "${2}"; ret=$?

    #echo "${ret}"
    [ ${ret} -ne 0 ] && return ${ret}
    #[ ${ret} -eq 0 ] && echo "${!2}"

    echo "[${1}] -> ${2}=${!2}"
}




main()
{
    F_check
    local section="PROD_COMPO_DESC"

    F_print_key "${section}" "copyright"
    F_print_key "${section}" "product_name"
    F_print_key "${section}" "dev_soft_1"
    F_print_key "ID" "pkg_server"

    product_name="wpfs20111"
    fusky=test
    cfg_update "${section}" "product_name"
    cfg_update "${section}" "fusky"

    F_print_key "${section}" "product_name"
    #declare -f cfg_section_PROD_COMPO_DESC

    second_id="04"
    cfg_update "ID_1" "second_id"

    #F_print_write
    
    return 0
}
main
