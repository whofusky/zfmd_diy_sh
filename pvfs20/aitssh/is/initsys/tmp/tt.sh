#!/bin/bash
#
########################################################################
#author        :    fushikai
#creation date :    2023-03-01
#linux_version :    Red Hat / UniKylin
#dsc           :
#       test
#    
#
########################################################################

NOOUT=0 ; levelName[0]="NOOUT";
ERROR=1 ; levelName[1]="ERROR";
INFO=2  ; levelName[2]="INFO" ;
DEBUG=3 ; levelName[3]="DEBUG";


OUT_LOG_LEVEL=${DEBUG}

g_baseicDir="$(cd "$(dirname "$0")" >/dev/null 2>&1 || exit; pwd -P)"
export g_baseicDir

logDir="${g_baseicDir}/log"
[ ! -d "${logDir}" ] && mkdir -p "${logDir}"
logFile="${logDir}/${shName}.log"







function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
{

    [ $# -lt 2 ] && return 1

    #特殊调试时用
    local print_to_stdin_flag=1  # 0:可能输出到日志文件; 1: 输出到屏幕; 2可能同时输出到屏幕和日志文件

    #input log level
    local i="${1:-3}"   
    

    ##debug to open this
    #[ $(echo "${i}"|sed -n '/^[0-9]*$/p' |wc -l) -eq 0 ] && i=${DEBUG}
    #[ $(echo "${NOOUT}<=${i} && ${i}<=${DEBUG}"|bc) -eq 0 ] && i=${DEBUG}


    [ ${i} -gt ${OUT_LOG_LEVEL:=3} ] && return 0

    local puttxt="$2"

    #echo "fusktest:puttxt=[${puttxt}]"

    # 1.换行符;2.空; 3.多个-;
    # 以上作一情况 则直接输出而不在输出内容之前添加日期等内容
    local tflag=$(echo "${puttxt}"|sed -n '/^\s*\(\(\\n\)\+\)*$\|^\s*-\+$/p'|wc -l)

    #没有设置日志文件时默认也是输出到屏幕
    [ -z "${logFile}" ] && print_to_stdin_flag=1

    local timestring
    local timeSt
    if [ ${tflag} -eq 0 ];then
        timestring="$(date +%F_%T.%N)"
        timeSt="$(date +%T.%N)"
    fi
        

    if [ ${print_to_stdin_flag} -eq 1 ];then
        if [ ${tflag} -gt 0 ];then
            echo -e "${puttxt}"
        else
            echo -e "${timestring}|${levelName[$i]}|${puttxt}"
        fi
        return 0
    fi

    [ -z "${logDir}" ] &&  logDir="${logFile%/*}"
    if [ "${logDir}" = "${logFile}" ];then
        logDir="./"
    elif [ ! -d "${logDir}" ];then
        mkdir -p "${logDir}"
    fi

    if [ ${tflag} -gt 0 ];then
        if [ "${print_to_stdin_flag}x" = "2x" ];then
            echo -e "${puttxt}"|tee -a  "${logFile}"
        else
            echo -e "${puttxt}" >> "${logFile}"
        fi
    else
        if [ "${print_to_stdin_flag}x" = "2x" ];then
            echo -e "${timeSt}|${levelName[$i]}|${puttxt}"
            echo -e "${timestring}|${levelName[$i]}|${puttxt}" >>"${logFile}"
        else
            echo -e "${timestring}|${levelName[$i]}|${puttxt}" >> "${logFile}"
        fi
    fi


    return 0
}


##############################################################################
# 在系统配置文件中,设置以空格分隔的的一行值
#
#set the value of the configuration file;
#eg: setEnvOneVal ${file} "set" "encoding" "set encoding=utf-8"   '\"' 'positition_character'
#
#inpara:
#   [1] file_name
#   [2] 第一列值
#   [3] 第二列值定位字符(可以有通配特殊符号)
#   [4] 要添加的一整行内容值
#   [5] 注释符号
#   [6] 参考行定位字符串(此值用于定位在哪一行之后追加要设置的值)(可选参数)(可以使用sed可识别的正则表达符号)
#return:
#   0      要添加的内容已经存在
#   9      添加成功
#   其他值 失败
##############################################################################
function F_setEnvSpaceVal() 
{
    if [ $# -ne 5 -a $# -ne 6 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|input parameters num not eq 5 or 6"
        return 1
    fi

    local referenceLineStr edfile

    [ $# -eq 6 ] && referenceLineStr="$6"
    edfile=$1
    if [ ! -f ${edfile} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|file[${edfile}] not exist!"
        return 2
    fi

    local firstColumn secondColumnPosStr addLineContent commentSymbol speFlag

    firstColumn="$2"; secondColumnPosStr="$3";
    addLineContent="$4"; commentSymbol="$5";

    #判断定位编辑行的字符串中是否有特殊字符(通配,正则语法)
    speFlag=$(echo "${secondColumnPosStr}"|grep "[^0-9a-zA-Z\.\_\-]"|wc -l)

    local haveCol_1 haveCol_1_2 haveComCol_1 haveComCol_1_2 

    #判断文件中是否存在要添加内容首列的内容
    haveCol_1=$(egrep "^\s*${firstColumn}\s+[^$]" ${edfile}|wc -l)

    #判断文件中是否存在要添加内容首列和第二列内容
    if [ ${speFlag} -gt 0 ];then
        haveCol_1_2=$(egrep "^\s*${firstColumn}\s+${secondColumnPosStr}" ${edfile}|wc -l)
    else
        haveCol_1_2=$(egrep "^\s*${firstColumn}\s+\<${secondColumnPosStr}\>" ${edfile}|wc -l)
    fi

    #判断文件中是否存在要添加内容首列的内容(注释掉的)
    haveComCol_1=$(egrep "^\s*${commentSymbol}\s*${firstColumn}\s+[^$]" ${edfile}|wc -l)

    #判断文件中是否存在要添加内容首列和第二列内容(注释掉的)
    if [ ${speFlag} -gt 0 ];then
        haveComCol_1_2=$(egrep "^\s*${commentSymbol}\s*${firstColumn}\s+${secondColumnPosStr}" ${edfile}|wc -l)
    else
        haveComCol_1_2=$(egrep "^\s*${commentSymbol}\s*${firstColumn}\s+\<${secondColumnPosStr}\>" ${edfile}|wc -l)
    fi


    #文件中存在要添加内容首列的内容
    if [[ ${haveCol_1} -gt 0 ]];then

        #文件中存在要添加的整行内容
        if [[ $(grep "^\s*${addLineContent}\s*$" ${edfile}|wc -l) -gt 0 ]];then
            return 0
        fi
        #文件中不存在要添加的整行内容

        #文件中存在要添加内容的第1列内容但不存在第2列值
        if [[ ${haveCol_1_2} -lt 1 ]];then

            #文件中存在注释掉的第1和第2列值
            if [[ ${haveComCol_1_2} -gt 0 ]];then

                #入参中定位第二列值的字符串有特殊字符(通配符等)
                if [ ${speFlag} -gt 0 ];then

                    #将当前行替换成要添加的行内容
                    sed "$(sed -n "/^\s*${commentSymbol}\s*${firstColumn}\s\+${secondColumnPosStr}/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
                else

                    #将当前行替换成要添加的行内容
                    sed "$(sed -n "/^\s*${commentSymbol}\s*${firstColumn}\s\+\<${secondColumnPosStr}\>/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
                fi

                F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change row=[${addLineContent}]"

            #文件中不存在注释掉的第1和第2列值
            else

                #在文件中所有已经存在的第1列值最后一行后添加新内容
                sed "$(sed -n "/^\s*${firstColumn}\s\+[^$]/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
                F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|add row=[${addLineContent}]"
            fi


        #文件中存在要添加内容的第1和第2列值
        else

            #将当前行替换成要添加的行内容
            if [ ${speFlag} -gt 0 ];then
                sed "$(sed -n "/^\s*${firstColumn}\s\+${secondColumnPosStr}/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
            else
                sed "$(sed -n "/^\s*${firstColumn}\s\+\<${secondColumnPosStr}\>/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
            fi

            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change row=[${addLineContent}]"
        fi

        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|edit file=[$edfile]"
        return 9
    fi

        
    #文件中不存在要添加内容首列的内容,但存在注释掉的首列内容
    if [[ ${haveComCol_1} -gt 0 ]];then

        #文件中存在注释掉的第1和第2列内容
        if [[ ${haveComCol_1_2} -gt 0 ]];then

            #将找到的第一行内容替换成新内容
            if [ ${speFlag} -gt 0 ];then
                sed "$(sed -n "/^\s*${commentSymbol}\s*${firstColumn}\s\+${secondColumnPosStr}/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
            else
                sed "$(sed -n "/^\s*${commentSymbol}\s*${firstColumn}\s\+\<${secondColumnPosStr}\>/=" ${edfile}|sed 1q)c${addLineContent}" -i ${edfile}    
            fi

            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change row=[${addLineContent}]"

        #文件中存在注释掉的第1但不存在第2列
        else

            #在注释掉的第1列内容所有行后添加新行内容
            sed "$(sed -n "/^\s*${commentSymbol}\s*${firstColumn}\s\+[^$]/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|add row=[${addLineContent}]"
        fi

        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|edit file=[$edfile]"
        return 9
    fi

    #文件中不存在要添加内容首列的内容,也不存在注释掉的首列内容

    local ttnum

    #空文件则直接将添加的内容追加到文件中
    ttnum=$(sed -n "/.*/=" ${edfile}|wc -l)
    if [ ${ttnum} -eq 0 ];then
        echo "${addLineContent}">>${edfile}
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|old [$edfile] is null,and add[${addLineContent}] to file!"
        return 9
    fi

    local posSpeFlag posnum

    #文件中不存在要添加内容首列的内容,也不存在注释掉的首列内容,所以需要在
    #源文件中追加内容

    # 有定位参考符号(需要把相应内容添加到参考符的行下)
    if [ ! -z "${referenceLineStr}" ];then

        #判断定位符是否有特殊含义字符
        posSpeFlag=$(echo "${referenceLineStr}"|grep "[^0-9a-zA-Z\.\_\-]"|wc -l)
        if [ ${posSpeFlag} -gt 0 ];then

            #是否能根据参考符找到相应参考位置
            posnum=$(sed -n "/${referenceLineStr}/=" ${edfile}|wc -l)

            if [ ${posnum} -gt 0 ];then

                #参考符对应的行下追加新内容
                sed "$(sed -n "/${referenceLineStr}/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
            else
                #文件末尾追加新内容
                sed "$(sed -n "/.*/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
            fi

        else

            #是否能根据参考符找到相应参考位置
            posnum=$(sed -n "/\<${referenceLineStr}\>/=" ${edfile}|wc -l)
            if [ ${posnum} -gt 0 ];then
                #参考符对应的行下追加新内容
                sed "$(sed -n "/\<${referenceLineStr}\>/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
            else
                #文件末尾追加新内容
                sed "$(sed -n "/.*/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
            fi
        fi

    #没有参考符参数
    else
        #文件末尾追加新内容
        sed "$(sed -n "/.*/=" ${edfile}|sed -n '$p')a${addLineContent}" -i ${edfile}    
    fi

    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|add row=[${addLineContent}]"
    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|edit file=[$edfile]"

    return 9
}



##############################################################################
# 在系统配置文件中,key=value;或 export key=value 或 export key 类型的值
#
#eg: F_setEnvKeyVal ${file} "export" "key" "value"   '#' 'positition_character'
# 注意value中的$或"需要用\符号转义
#
#inpara:
#   [1] file_name
#   [2] 前缀值(例如:export)
#   [3] key名称
#   [4] value值
#   [5] 注释符号
#   [6] 参考行定位字符串(此值用于定位在哪一行之后追加要设置的值)(可选参数)(可用sed识别的正则表达式)
#return:
#   0      要添加的内容已经存在
#   9      添加成功
#   其他值 失败
##############################################################################
function F_setEnvKeyVal() 
{
    if [ $# -ne 5 -a $# -ne 6 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|input parameters num not eq 5 or 6"
        return 1
    fi

    local edfile setPrefix setKey setVal setComment setLocator

    edfile="$1"; setPrefix="$2"; setKey="$3"; setVal="$4"; setComment="$5";
    [ $# -eq 6 ] && setLocator="$6"

    if [ ! -f ${edfile} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|file[${edfile}] not exist!"
        return 2
    fi

    if [  -z "${setKey}" ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|in para setKey is null!"
        return 3
    fi

    local haveCol_1_2 sameFlag haveComCol_1_2
    local addCnt locatorNo
    if [ ! -z  "${setPrefix}" ];then
        addCnt="${setPrefix} ${setKey}=${setVal}"
    else
        addCnt="${setKey}=${setVal}"
    fi

    #echo "fusktest=[${addCnt}]"

    #有前缀的时候,比如有 export
    if [ ! -z "${setPrefix}" ];then
        haveCol_1_2=$(egrep "^\s*${setPrefix}\s+\<${setKey}\>" ${edfile}|wc -l)

        #存在相同的前缀和相同的key
        if [ ${haveCol_1_2} -gt 0 ];then

            #已经有要添加的内容
            sameFlag=$(grep -x --fixed-strings "${addCnt}" "${edfile}"|wc -l)
            if [ ${sameFlag} -gt 0 ];then
                return 0
            fi

            #替换成要添加的值
            #echo "sed \"\$(sed -n \"/^\s*${setPrefix}\s\+${setKey}\b/=\" ${edfile}|sed -n '\$p')c${addCnt}\" -i ${edfile}    "
            sed "$(sed -n "/^\s*${setPrefix}\s\+${setKey}\b/=" ${edfile}|sed -n '$p')c${addCnt}" -i ${edfile}    
            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change file[${edfile}] row=[${addCnt}]"
            return 9
        fi

        #不存在相同的前缀和key

        #如果注释字符不为空:查一下是否有注释掉的前缀和key
        if [ ! -z "${setComment}" ];then
            haveComCol_1_2=$(egrep "^\s*${setComment}+\s*${setPrefix}\s+\<${setKey}\>" ${edfile}|wc -l)
            if [ ${haveComCol_1_2} -gt 0 ];then

                #在找到注释行的最后一行进行替换
                sed "$(sed -n "/^\s*${setComment}\+\s*${setPrefix}\s\+\b${setKey}\b/=" ${edfile}|sed -n '$p')c${addCnt}" -i ${edfile}    

                F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change file[${edfile}] row=[${addCnt}]"
                return 9
            fi
        fi

        #如果定位符不为空则查找定位符的位置
        if [ ! -z "${setLocator}" ];then
            locatorNo=$(sed -n "/${setLocator}/=" ${edfile}|sed -n '$p')
            #参考符对应的行下追加新内容
            if [ ! -z "${locatorNo}" ];then
                sed "${locatorNo}a${addCnt}" -i ${edfile}    
                F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|modify file[${edfile}] add row=[${addCnt}]"
                return 9
            fi
        fi

        #直接在文件末尾追加要添加的内容
        echo "${addCnt}">>"${edfile}"
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|modify file[${edfile}] add row=[${addCnt}]"
        return 9
    fi

    #没有前缀的情况

    local haveCol_1 haveComCol_1 haveComCol_1

    #是否有相应key值
    haveCol_1=$(egrep "^\s*\<${setKey}\>\s*=" ${edfile}|wc -l)
    if [ ${haveCol_1} -gt 0 ];then

        #已经有要添加的内容
        sameFlag=$(grep -x --fixed-strings "${addCnt}" "${edfile}"|wc -l)
        if [ ${sameFlag} -gt 0 ];then
           return 0
        fi

        #没有相等的内容,则修改有相同key的那一行值
        sed "$(sed -n "/^\s*\b${setKey}\b\s*=/=" ${edfile}|sed -n '$p')c${addCnt}" -i ${edfile}    
        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change file[${edfile}] row=[${addCnt}]"
        #echo "addCnt=[${addCnt}]"
        return 9
    fi

    #没有相应key值,则查找是否有注释个的相应key值
    #如果注释字符不为空:查一下是否有注释掉的前缀和key
    if [ ! -z "${setComment}" ];then
        haveComCol_1=$(egrep "^\s*${setComment}+\s*\<${setKey}\>\s*=" ${edfile}|wc -l)
        if [ ${haveComCol_1} -gt 0 ];then

            #在找到注释行的最后一行进行替换
            sed "$(sed -n "/^\s*${setComment}\+\s*\b${setKey}\b\s*=/=" ${edfile}|sed -n '$p')c${addCnt}" -i ${edfile}    

            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|change file[${edfile}] row=[${addCnt}]"
            return 9
        fi
    fi

    #如果定位符不为空则查找定位符的位置
    if [ ! -z "${setLocator}" ];then
        locatorNo=$(sed -n "/${setLocator}/=" ${edfile}|sed -n '$p')
        #参考符对应的行下追加新内容
        if [ ! -z "${locatorNo}" ];then
            sed "${locatorNo}a${addCnt}" -i ${edfile}    
            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|modify file[${edfile}] add row=[${addCnt}]"
            return 9
        fi
    fi

    #直接在文件末尾追加要添加的内容
    echo "${addCnt}">>"${edfile}"
    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|modify file[${edfile}] add row=[${addCnt}]"
    return 9
}


function F_md_system-auth()
{
    local tfile cnt ret
    tfile="${g_baseicDir}/system-auth"
    cnt="password    requisite     pam_cracklib.so  retry=5 minlen=8 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1"
    F_setEnvSpaceVal "${tfile}" "password" 'requisite\s*pam_cracklib.so' "${cnt}" "#"
    ret=$?
    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|F_setEnvSpaceVal return[${ret}]"
}

function F_md_login_defs()
{
    local tfile ret pMaxDays pMinDays pMinLen pWarnAge

    tfile="${g_baseicDir}/login.defs"

    pMaxDays="PASS_MAX_DAYS    90"
    pMinDays="PASS_MIN_DAYS    0"
    pMinLen="PASS_MIN_LEN    8"
    pWarnAge="PASS_WARN_AGE    10"

    F_setEnvSpaceVal "${tfile}" "PASS_MAX_DAYS" '[0-9][0-9]*' "${pMaxDays}" "#" '^\s*#s*PASS_WARN_AGE'
    ret=$?
    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|F_setEnvSpaceVal PASS_MAX_DAYS return[${ret}]"

    F_setEnvSpaceVal "${tfile}" "PASS_MIN_DAYS" '[0-9][0-9]*' "${pMinDays}" "#" '^PASS_MAX_DAYS'
    ret=$?
    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|F_setEnvSpaceVal PASS_MIN_DAYS return[${ret}]"

    F_setEnvSpaceVal "${tfile}" "PASS_MIN_LEN" '[0-9][0-9]*' "${pMinLen}" "#" '^PASS_MIN_DAYS'
    ret=$?
    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|F_setEnvSpaceVal PASS_MIN_LEN return[${ret}]"

    F_setEnvSpaceVal "${tfile}" "PASS_WARN_AGE" '[0-9][0-9]*' "${pWarnAge}" "#" '^PASS_MIN_LEN'
    ret=$?
    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|F_setEnvSpaceVal PASS_WARN_AGE return[${ret}]"
}


function F_md_pamd_loginlimit()
{
    if [ $# -lt 1 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}| in para nums less than 1"
        return 1
    fi
    local tfile cnt ret i

    cnt="auth       required     pam_tally2.so deny=4 unlock_time=600" 

    for i in $@ ;do
        tfile="${g_baseicDir}/${i}"
        F_setEnvSpaceVal "${tfile}" "auth" 'required\s*pam_tally2.so' "${cnt}" "#"
        ret=$?
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|F_setEnvSpaceVal $i return[${ret}]"
    done
}

function F_md_key_val()
{
    #eg: F_setEnvKeyVal ${file} "export" "key" "value"   '#' 'positition_character'

    local tfile ret  pre key val locator

    tfile="${g_baseicDir}/profile"
    #alias cddn='cd /home/fusky/Downloads'
    pre=""
    key="kk"
    val="'find . -name \".*.swp\" -type f -print|while read tnaa;do echo \"rm -rf \${tnaa}\";rm -rf \"\${tnaa}\";done'"
    locator='^\s*\[daemon\]\s*$'

    F_setEnvKeyVal "${tfile}" "${pre}" "${key}" "${val}" "#" "${locator}"
    ret=$?
    F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|F_setEnvKeyVal aa return[${ret}]"
}

main()
{
    #F_md_system-auth
    #F_md_login_defs
    #F_md_pamd_loginlimit "sshd" "login" "remote"
    F_md_key_val
}
main
