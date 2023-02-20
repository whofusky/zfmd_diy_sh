NOOUT=0 ; levelName[0]="NOOUT";
ERROR=1 ; levelName[1]="ERROR";
INFO=2  ; levelName[2]="INFO" ;
DEBUG=3 ; levelName[3]="DEBUG";
all_levelName=$(declare -p levelName)
OUT_LOG_LEVEL=${DEBUG}

basicDir="${baseDirM}"
#if [ "x${baseDirM}" == "x." ];then
if [ $(echo "${baseDirM}"|sed -n '/^\s*\//p'|wc -l) -eq 0 ];then
    basicDir="${PWD}/${baseDirM}"
fi

logDir="${basicDir}/log"
[ ! -d "${logDir}" ] && mkdir -p "${logDir}"
logFile="${logDir}/${shName}.log"

function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
{

    [ $# -lt 2 ] && return 1

    #特殊调试时用
    local print_to_stdin_flag=2  # 0:可能输出到日志文件; 1: 输出到屏幕; 2可能同时输出到屏幕和日志文件

    #input log level
    local i="$1"   
    

    ##debug to open this
    #[ $(echo "${i}"|sed -n '/^[0-9]*$/p' |wc -l) -eq 0 ] && i=${DEBUG}
    #[ $(echo "${NOOUT}<=${i} && ${i}<=${DEBUG}"|bc) -eq 0 ] && i=${DEBUG}


    [ ${i} -gt ${OUT_LOG_LEVEL} ] && return 0

    local puttxt="$2"

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

function F_setKeyValInFile() #use: F_setKeyValInFile <file> "key=val"
{
    if [ $# -lt 2 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|input parameters number less than 2 !"
        return 1
    fi

    local tFile="$1"
    local tKeyVal=$(echo "$2"|sed 's/\s\+=/=/g;s/=\s\+/=/g')
    local tKey=$(echo "${tKeyVal}"|awk -F'=' '{print $1}'|sed 's/^\s\+//g;s/\s\+$//g')
    echo "fusktest:tFile[${tFile}],tKey[${tKey}],tKeyVal[${tKeyVal}]"
    if [ -z "${tKey}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|input parameters 2 format error!"
        return 1
    fi

    if [ ! -f "${tFile}" ];then
        local tdir=$(F_getPathName "${tFile}")
        if [ ! -d "${tdir}" ];then 
            F_writeLog $ERROR "${LINENO}|${FUNCNAME}|file[ ${tFile} ] not exist!"
            return 1
        fi
        echo "${tKeyVal}">>"${tFile}"
        return 0
    fi

    local tnum=$(sed -n "/^\s*${tKey}\b/=" "${tFile}")
    if [ ! -z "${tnum}" ];then
        local tVal=$(echo "${tKeyVal}"|awk -F'=' '{print $2}'|sed 's/^\s\+//g;s/\s\+$//g')
        local tno=$(echo "${tnum}"|head -1)
        if [ $(echo "${tnum}"|wc -l) -gt 1 ];then
            local ttno=$(echo "${tno} + 1"|bc)
            sed -i "${ttno},$ {/^\s*${tKey}\b/ d}" "${tFile}"
        fi
        echo "fusktest:tno[${tno}]"
        #sed -i "/^\s*${tKey}\b/ d" "${tFile}"
        tVal=$(echo "${tVal}"|sed 's/\//\\\//g')
        sed -i "${tno} s/^\s*${tKey}\b\s*=[^=]*/${tKey}=${tVal}/g" "${tFile}"
    else
        echo "${tKeyVal}">>"${tFile}"
    fi

    return 0
}

main()
{
    local tdir="/home/fusky/mygit/zfmd_diy_sh/pvfs20/safe/fw"

    F_setKeyValInFile "${tdir}/tmp/.ttmp.txt" "gui_in_cfg_file=/home/fusky/mygit/zfmd_diy_sh/pvfs20/safe/fw/pv_fw_item_config.ini"
    return 0
}

main
