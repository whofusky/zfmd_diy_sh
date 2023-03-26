#!/bin/bash
#
##############################################################################
# date: 2023-02-13_14:34:09
# dsc :
#     根据云平台自动生成批处理文件的bat脚本，自动生成1.7项目的文件夹列表
#
##############################################################################
#


#inFile='批量建立文件夹--2023.2.10 .bat'
inFile='批量建立文件夹--2023.3.3 加长荣.bat'
fs17File="fs17_dir.txt"
fs20File="fs20_dir.txt"
fsallFile="all_dir.txt"
tmpfile="tmp.txt"


function F_check()
{
    if [ ! -e "${inFile}" ];then
        echo -e "\n\tERROR: file [ ${inFile} ] not exist!\n"
        exit 1
    fi
    local tnum
    tnum=$(ed -n '$ {/^\s*$/p}' "${inFile}"|wc -l)
    if [ ${tnum} -eq 0 ];then
        echo "">>"${inFile}"
    fi
    return 0
}

function F_doit()
{
    local tnaa; local tnum=0;
    local blankFlag=0; local cdpath;
    local fs17Flag=0; local fs20Flag=0;
    local dotFlag=0;
    local fs17line=0;
    local fs20line=0;
    local fsalline=0;
    >"${fs17File}"
    >"${fs20File}"
    >"${fsallFile}"

    local lineNo=0; local prtFlag=0;

    local totalLinNo=$(wc -l "${inFile}"|awk '{print $1}')
    echo -e "\nbegine time:[$(date +%F_%T.%N)]"

    while read tnaa
    do
        let lineNo++
        printf "\r----doing lineNo:[%d/%d]"  ${lineNo} ${totalLinNo}

        tnaa=$(echo "${tnaa}"|sed 's///g')

        #fileter blank line
        blankFlag=$(echo "${tnaa}"|sed -n '/^\s**$/p'|wc -l)
        if [[ ${prtFlag} -eq 0 && ${blankFlag} -gt 0 ]];then
            #echo "blank lineNo=[${lineNo}]"
            if [ ! -z "${cdpath}" ];then
                if [ "x${fs20Flag}" = "x1" ];then
                    #echo "fs20 dir=[${cdpath}]"
                    let fs20line++
                    echo "${cdpath}">>"${fs20File}"
                    echo "${cdpath}">>"${fsallFile}"
                else
                    #echo "fs17 dir=[${cdpath}]"
                    let fs17line++
                    echo "${cdpath}">>"${fs17File}"
                    echo "${cdpath}">>"${fsallFile}"
                fi
            fi

            cdpath="";fs17Flag=0;fs20Flag=0;
            prtFlag=0;
            continue
        fi

        #fileter cd ..
        dotFlag=$(echo "${tnaa}"|sed -n '/^\s*cd\s\+\.\.\s*$/p'|wc -l)
        if [ ${dotFlag} -gt 0 ];then
            #echo -n "dot lineNo=[${lineNo}]"
            if [ ! -z "${cdpath}" ];then
                if [ "x${fs20Flag}" = "x1" ];then
                    #echo "fs20 dir=[${cdpath}]"
                    let fs20line++
                    echo "${cdpath}">>"${fs20File}"
                    echo "${cdpath}">>"${fsallFile}"
                else
                    #echo "fs17 dir=[${cdpath}]"
                    let fs17line++
                    echo "${cdpath}">>"${fs17File}"
                    echo "${cdpath}">>"${fsallFile}"
                fi
            fi

            cdpath="";fs17Flag=0;fs20Flag=0;
            prtFlag=1;
            continue
        fi
        tnum=$(echo "${tnaa}"|sed -n '/^\s*cd\s\+/p'|wc -l)
        if [ $tnum -gt 0 ];then
            cdpath=$(echo "${tnaa}"|awk '{print $2}')
            #echo "cdpath=[${cdpath}]"
            continue
        fi

        tnum=$(echo "${tnaa}"|grep -w "tdir1"|wc -l)
        if [ $tnum -gt 0 ];then
            fs20Flag=1
            continue
        fi

    #echo "==== lineNo=[${lineNo}]"

    done<"${inFile}"


    if [ ${fs17line} -gt 0 ];then
        sort "${fs17File}"|uniq >"${tmpfile}" && cp -a "${tmpfile}" "${fs17File}"
        echo -e "\n\t file [${fs17File}] gen [${fs17line}] lines dir\n"
    fi
    if [ ${fs20line} -gt 0 ];then
        sort "${fs20File}"|uniq >"${tmpfile}" && cp -a "${tmpfile}" "${fs20File}"
        echo -e "\n\t file [${fs20File}] gen [${fs20line}] lines dir\n"
    fi

    fsalline=$(echo "${fs17line} + ${fs20line}"|bc)
    if [ ${fsalline} -gt 0 ];then
        sort "${fsallFile}"|uniq >"${tmpfile}" && cp -a "${tmpfile}" "${fsallFile}"
        echo -e "\n\t file [${fsallFile}] gen [${fsalline}] lines dir\n"
    fi

    [ -f "${tmpfile}" ] && rm -rf "${tmpfile}"

    echo -e "\nend time:[$(date +%F_%T.%N)]\n"

    return 0
}

main()
{
    F_check
    F_doit
    return 0
}
main
