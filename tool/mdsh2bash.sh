#!/bin/bash
#
######################################################################
#
# author  : fushikai
# date    : 20210414
# dsc     : modify shell script "#!/bin/sh" to "#!/bin/bash"
# use     : mdsh2bash.sh  <target_dir>
#
######################################################################
#

thisShName="$0"
onlyShName=${thisShName##*/}
onlyShPre=${onlyShName%.*}
inParNum=$#
dstDir="$1"

function F_help()
{
    echo -e "\n\tpleae input like:${onlyShName} <target_dir>\n"
    return 0
}

function F_check()
{
    if [ ${inParNum} -ne 1 ];then
        F_help
        exit 1
    fi

    if [ ! -d "${dstDir}" ];then
        echo -e "\n\t ERROR: dir [${dstDir}] not exitst!\n"
        exit 2
    fi

    return 0
}

function F_modify()
{
    local tnum=0
    tnum=$(find ${dstDir} -type f|xargs egrep '^\s*#\s*!\s*/bin/sh\s*$' 2>/dev/null|wc -l)
    if [ ${tnum} -lt 1 ];then
        echo -e "\n\tThere are no file that meet the conditions!\n"
        return 0
    fi

    find ${dstDir} -type f|xargs egrep '^\s*#\s*!\s*/bin/sh\s*$' 2>/dev/null|awk -F':' '{print $1}'|sort|uniq|while read tnaa
    do
        echo "doing: [ ${tnaa} ]: \"#!/bin/sh\" to \"#!/bin/bash\""
        sed -i 's=^\s*#\s*!\s*/bin/sh\s*$=#!/bin/bash=g' ${tnaa}
    done

    echo -e "\n\t ${onlyShName} exe complete\n"
    return 0
}


main()
{
    F_check
    F_modify
    return 0
}

main

exit 0

