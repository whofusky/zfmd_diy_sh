#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20190415
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    获取某个程序的运行时间
#           1.默认返回值为xx（单位秒）
#           2.当有2入输出参数且第二个参数为程序名是返回:
#               xx days yy hours kk minutes tt seconds
#    
#revision history:
#       
#       
#
#############################################################################

#软件版本号
versionNo="software version number: v0.0.0.1"

#加载系统环境变量配置
if [ -f /etc/profile ]; then
    . /etc/profile >/dev/null 2>&1
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile >/dev/null 2>&1
fi

baseDir=$(dirname $0)
#logFNDate="$(date '+%Y%m%d')"
#logDir="${baseDir}/log"
#if [ ! -d "${logDir}" ];then
#    mkdir -p "${logDir}"
#fi

if [[ $# -ne 1 && $# -ne 2 ]];then
    echo -e "\n\tINPUT ERROR: please like\n\t\t $0 <program_name>\n\t\tOR\n\t\t $0 1 <program_name>\n"
    exit 1
fi

noSedFlag=0
#程序名
if [ $# -eq 1 ];then
    tpName="$1"
    #echo -e "\n\t-----1=[$1]----"
else
    tpName="$2"
    #echo -e "\n\t-----1=[$1]-,2=[$2]---"
    noSedFlag=1
fi


begineStr="start running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"

function F_prtEtimeSeconds()
{
    if [ $# -lt 1 ];then
        return 1
    fi
    local tmpStr="$1"

    #echo "${tmpStr}"
    #echo "${tmpStr}" | sed 's/:\|-/ /g' |awk  '{print $4" "$3" "$2" "$1}'

    echo "${tmpStr}" | sed 's/:\|-/ /g' |awk  '{print $4" "$3" "$2" "$1}'|awk  '{print $1+$2*60+$3*3600+$4*86400}'

    return 0
}

#获取pid对应的程序运行时长（单位秒）
function getPidElapsedSec()
{
    if [ $# -ne 2 ];then
        echo "Error:The number of input parameters of function getPidElapsedSec if not equal 2"
        return 1
    fi

    tInPid=$1
    outFormatFlag=$2

    tEtime=$(ps -p ${tInPid} -o etime|tail -1|awk '{print $NF}')
    if [ "${tEtime}" == "ELAPSED" ];then
        echo "Error:pid=[${tInPid}] does not exist!"
        return 9
    fi

    #echo "---tEtime=[${tEtime}]----"
    tColonNum=$(echo "${tEtime}"|awk -F':' '{print NF}')

    #echo "----tColonNum=[${tColonNum}]----"
    if [ ${tColonNum} -eq 2 ];then

        tMinute=$(echo "${tEtime}"|awk -F':' '{print $1}')
        tSecond=$(echo "${tEtime}"|awk -F':' '{print $2}')
        if [ ${outFormatFlag} -eq 1 ];then
            outVal="\e[1;31m 0 \e[0mDays:\e[1;31m  0 \e[0mHours:\e[1;31m  ${tMinute} \e[0mMinutes:\e[1;31m  ${tSecond} \e[0mSeconds"
        else
            outVal=$(echo "(${tMinute} * 60 ) + ${tSecond}"|bc)
        fi

        #echo "---tMinute=[${tMinute}],tSecond=[${tSecond}]---"
        #echo "----outVal=[${outVal}]---outVal2=[${outVal2}]-----"

    elif [ ${tColonNum} -eq 3 ];then
        tMinute=$(echo "${tEtime}"|awk -F':' '{print $2}')
        tSecond=$(echo "${tEtime}"|awk -F':' '{print $3}')
        tDHorH=$(echo "${tEtime}"|awk -F':' '{print $1}')
        tBarNum=$(echo "${tDHorH}"|awk -F'-' '{print NF}')
        tDay=0
        tHour=0
        if [ ${tBarNum} -eq 1 ];then
            tDay=0
            tHour=${tDHorH}
        elif [ ${tBarNum} -eq 2 ];then
            tDay=$(echo "${tDHorH}"|awk -F'-' '{print $1}')
            tHour=$(echo "${tDHorH}"|awk -F'-' '{print $2}')
        else
            echo "Error1:[${tEtime}] format Error"
            return 2
        fi
        if [ ${outFormatFlag} -eq 1 ];then
            outVal="\e[1;31m ${tDay} \e[0mDays:\e[1;31m  ${tHour} \e[0mHours:\e[1;31m  ${tMinute} \e[0mMinutes:\e[1;31m  ${tSecond} \e[0mSeconds"
        else
            outVal=$(echo "(${tDay} * 86400) + (${tHour} * 3600) + (${tMinute} * 60 ) + ${tSecond}"|bc)
        fi

        #echo "--tDay=[${tDay}],tHour=[${tHour}]---tMinute=[${tMinute}],tSecond=[${tSecond}]---"
        #echo "----outVal=[${outVal}]---outVal2=[${outVal2}]-----"

    else
        echo "Error2:[${tEtime}] format Error"
        return 3
        
    fi

    echo "${outVal}"
    return 0

}


function getFnameOnPath() #get the file name in the path string
{
    if [ $# -ne 1 ];then
        echo "  Error: function getFnameOnPath input parameters not eq 1!"
        return 1
    fi

    allName="$1"
    if [ -z "${allName}" ];then
        echo "  Error: function getFnameOnPath input parameters is null!"
        return 2;
    fi

    slashNum=$(echo ${allName}|grep "/"|wc -l)
    if [ ${slashNum} -eq 0 ];then
        echo ${allName}
        return 0
    fi

    fName=$(echo ${allName}|awk -F'/' '{print $NF}')
    echo ${fName}

    return 0
}

shName=$(getFnameOnPath $0)
pName=$(getFnameOnPath ${tpName})


#已经有脚本在运行则退出
tmpShPid=$(pidof -x ${shName})
tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
if [ ${tmpShPNum} -gt 1 ]; then
    echo  "+++${tmpShPid}+++++${tmpShPNum}+++"
    echo  "script [$0] has been running,this run directly exits!"
    exit 
fi

tPid=$(pidof -x ${pName})
if [ -z "${tPid}" ];then
    echo -e "\n\tError:  The pid of the program [${pName}] does not exist\n"
    exit 1
fi

retMsg=$(getPidElapsedSec "${tPid}" "${noSedFlag}")
ret=$?
if [ ${ret} -ne 0 ];then
    echo -e "\n\t${retMsg}\n"
    exit 1
fi

if [ ${noSedFlag} -eq 0 ];then
    echo -e "\n\tThe running time of program [${tpName}] is:\e[1;31m  ${retMsg} \e[0mseconds\n"
else
    echo -e "\n\tThe running time of program [${tpName}] is: ${retMsg} \n"
fi

endStr="End running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"
#echo  "${begineStr}"
#echo  "${endStr}"
#echo  "\tscript [ $0 ] runs complete!!"

exit 0

