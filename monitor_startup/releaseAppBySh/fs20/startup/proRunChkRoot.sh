#!/bin/bash  
#                                                                            
#############################################################################
#  fusk
#  20171220
#    此脚本主要功能为读配置文件（与此脚本放同一目录）的配置，然后查检配置的程
#    序是否在运行，如果没有运行则启动相应的程序，并输出一条启动的日志到日志文件
#  建议配合crontab使用以达到监控程序是否停止运行并启动停止的程序的目的
#############################################################################
##版本号：v1.0.0.1
##版本号：20180627 v1.0.0.2 在 v1.0.0.1 基础上添加判断如果运行程序不存在则查找下一配置
##版本号：20181108 v1.0.0.3 在 v1.0.0.2 基础上添加对日志目录超大文件进行压缩和超期文件进行删除

#加载系统环境变量配置
if [ -f /etc/profile ]; then
    . /etc/profile
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile
fi

#已经有脚本在运行则退出
tmpShPid=$(pidof -x $0)
tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
if [ ${tmpShPNum} -gt 1 ]; then
    echo "+++${tmpShPid}+++++${tmpShPNum}+++"
    echo "`date +%Y/%m/%d-%H:%M:%S.%N`:$0 script has been running this startup exit!"
    exit 0
fi


#用户自己定义的环境变量 export 在配置文件中（如果需要） 

#配置文件
readDir=`dirname $0`
readAFileN=${readDir}/rcfgRoot.cfg

#年月日变量
tmpYMD=$(date +%Y%m%d)

#程序名个数
numPN=0
#程序对应的日志目录个数
numLogDir=0
#程序运行路径个数
numRunPath=0
#程序运行的前缀
numRunPre=0
#程序对应的参数
numRunPara=0

while read LINE
do
   tmpIsCm=$(echo ${LINE}|tr "\040\011" "\0"|cut -c1)
   
   #去掉注释行
   if [ "${tmpIsCm}" == "#" ]; then
       continue
   fi

   tmpIsExport=$(echo ${LINE}|tr "\040\011" "\0"|cut -c1-6)
   #export 环境变量
   if [ "${tmpIsExport}" == "export" ]; then
       ${LINE}
       continue
   fi

   #得到程序名
   if [ "${tmpIsCm}" == "[" ]; then
       tmpPName[${numPN}]=$( echo ${LINE}|awk -F[ '{print $2}'|awk -F] '{print $1}'|tr "\040\011" "\0")
       let numPN++
       continue
   fi

   preName=$( echo ${LINE}|awk -F '=' '{ if(NF>0){print $1;}}'|tr "\040\011" "\0")
   valName=$( echo ${LINE}|awk -F '=' '{ if(NF>0){print $2;}}'|tr "\040\011" "\0")
   valNameNb=$( echo ${LINE}|awk -F '=' '{ if(NF>0){print $2;}}')

   #得到debug flag
   if [ "${preName}" == "debugFlag" ]; then
       tmpDebugFlag=${valName}
       continue
   fi
   #得到全局日志目录，存放脚本自己的日志
   if [ "${preName}" == "allLogDir" ]; then
       tmpAllLogDir=${valName}
       continue
   fi

   #得到log文件可以存放的最大天数
   if [ "${preName}" == "logMaxDay" ]; then
        if [ ! -z ${valName} ]; then
            tlogMaxDay=${valName}
        else
            tlogMaxDay=2
        fi
       continue
   fi

   #得到log文件大小需要压缩的临界值（单位M)
   if [ "${preName}" == "logMaxSizeM" ]; then
        if [ ! -z ${valName} ]; then
            tlogMaxSizeM=${valName}
        else
            tlogMaxSizeM=10
        fi
       continue
   fi


   #得到程序日志目录
   if [ "${preName}" == "logDir" ]; then
       tmpLogDir[${numLogDir}]=${valName}
       let numLogDir++
       continue
   fi
   #得到程序路径
   if [ "${preName}" == "runPath" ]; then
       tmpRunPath[${numRunPath}]=${valName}
       let numRunPath++
       continue
   fi
   #得到程序运行的前缀
   if [ "${preName}" == "runPrePara" ]; then
       if [ ! -z ${valName} ]; then
           tmpRunPre[${numRunPre}]=${valNameNb}
       else
           tmpRunPre[${numRunPre}]=${valName}
       fi
       let numRunPre++
       continue
   fi
   #得到程序运行的参数
   if [ "${preName}" == "runPara" ]; then
       tmpRunPara[${numRunPara}]=${valNameNb}
       let numRunPara++
       continue
   fi
done <${readAFileN}

#实际要处理的程序数组个数
doNum=${#tmpPName[*]}
let doNum--

#是否只是debug,如果是先校验对应的文件或路径是否存在，不存在则echo错误信息
if [ "${tmpDebugFlag}" == "0" ]; then
    errFlag="0"
    #校验配置的路径或文件是否存在
    for j in $( seq 0 ${doNum} )
    do
        #echo ""
        if [ ! -d "${tmpLogDir[$j]}" ]; then
            echo "DEBUG ECHO:The directory [${tmpLogDir[$j]}] does not exist!"
            errFlag="1"
        fi
        if [ ! -d "${tmpRunPath[$j]}" ]; then
            echo "DEBUG ECHO:The directory [${tmpRunPath[$j]}] does not exist!"
            errFlag="1"
        fi
        if [ ! -d "${tmpAllLogDir}" ]; then
            echo "DEBUG ECHO:The directory [${tmpAllLogDir}] does not exist!"
            errFlag="1"
        fi
         if [ ! -f "${tmpRunPath[$j]}/${tmpPName[$j]}" ]; then
            echo "DEBUG ECHO:File [${tmpRunPath[$j]}/${tmpPName[$j]}] does not exist!"
            errFlag="1"
        fi

        if [ "${errFlag}" == "1" ]; then
            echo ""
        fi
    done
    if [ "${errFlag}" == "0" ]; then
        echo "DEBUG ECHO:The configured file or path is correct!"
        echo ""
    fi

    exit 1
elif [ "${tmpDebugFlag}" == "2" ]; then
    echo "TIP:`date +%Y/%m/%d-%H:%M:%S.%N`:The rcfg.cfg configuration file is being configured"
    exit 2
elif [ "${tmpDebugFlag}" == "3" ]; then
    #不运行实际配置的程序
    exit 3
fi

#判断全局日志目录是否存在，不存在则创建
if [ ! -d ${tmpAllLogDir} ];then
    mkdir -p ${tmpAllLogDir}
fi

#定义日志文件需要重命名的最小值(单位KB）
macroSize=1
macroHour=1

for i in $( seq 0 ${doNum} )
do
    #判断程序是否已经在运行（是否有进行已经存在）,已经存在则查找下一个配置的程序，直至所有程序查找完毕
    if [ -z "${tmpRunPre[$i]}" ]; then
        tmpPid=$(pidof -x ${tmpPName[$i]})
        tmpPNum=$(echo ${tmpPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
        #echo "--pidof--${tmpPName[$i]}--${tmpPNum}--"
    else
        #tmpPNum=$(ps -ef|grep "${tmpRunPre[$i]}"|grep "${tmpPName[$i]}"|grep -v "grep"|wc -l)
        #tmpPNum=$(ps -ef|grep -w "${tmpPName[$i]}"|grep -v "grep"|wc -l)
        tmpPNum=$(ps -ef|egrep "\s+\.\/${tmpPName[$i]}($|\s+)"|grep -v "grep"|wc -l)
        #echo "--ps -ef--${tmpPName[$i]}--${tmpPNum}--"
    fi

    #判断运行程序是否存在，不存在则查找下一配置
    if [ ! -f "${tmpRunPath[$i]}/${tmpPName[$i]}" ]; then
        #echo "${tmpRunPath[$i]}/${tmpPName[$i]} is not exits!!!!!" >>${tmpAllLogDir}/"shStarProRoot"${tmpYMD}".log"
        continue
    fi

    #如果日志目录不存在则在此创建
    if [ ! -d ${tmpLogDir[$i]} ];then
        mkdir -p ${tmpLogDir[$i]}
    fi

    #对日志进行压缩或删除
    if [ "$(date +%H)" == "03" ];then
        ls -1 ${tmpLogDir[$i]}/${tmpPName[$i]}_sh_[0-9]* 2>/dev/null|while read tnaa
        do
            tdnum=$(echo "($(date +%s)-$(stat -c %Y ${tnaa}))/86400"|bc)
            isbz=$(echo $tnaa|grep ".*\.bz2")    
            if [ -z ${isbz} ];then
                tsizeM=$(echo "$(stat -c %s ${tnaa})/(1024*1024)"|bc )
            else
                tsizeM=0
            fi
            tdifftd=$(echo "${tdnum}>${tlogMaxDay}"|bc)
            tdiffts=$(echo "${tsizeM}>${tlogMaxSizeM}"|bc)

            if [ ${tdiffts} -eq 1 ]  && [ -w ${tnaa} ];then
                bzip2 -f ${tnaa} 
            fi    
            if [ ${tdifftd} -eq 1 ] && [ -w ${tnaa} ];then
                rm -rf ${tnaa}
            fi
        done
    fi

    if [ ${tmpPNum} -gt 0 ]; then
        #echo "`date +%Y/%m%d-%H:%M:%S.%N`: Program [${tmpRunPath[$i]}/${tmpPName[$i]} ${tmpRunPara[$i]}] is already running,and does not need to be started again!">>${tmpAllLogDir}/${tmpYMD}".log"
        actLFile=${tmpLogDir[$i]}/${tmpPName[$i]}"_sh_xxxx.log"
        actFsize=0
        if [ -f ${actLFile} ]; then
            actFsize=$(du -sk ${actLFile} |awk '{print $1}')
        fi
        tmpH=$(date +%H)
        backLFile=${tmpLogDir[$i]}/${tmpPName[$i]}"_sh_"$(date -d last-day +%Y%m%d)".log"
        if [ ${actFsize} -ge ${macroSize} -a ${tmpH} -lt ${macroHour} -a ! -f ${backLFile}  ]; then
            cp ${actLFile} ${backLFile} && >${actLFile}
        fi

        continue
    else
        cd ${tmpRunPath[$i]}
        nohup ${tmpRunPre[$i]} ./${tmpPName[$i]} ${tmpRunPara[$i]} >>${tmpLogDir[$i]}/${tmpPName[$i]}"_sh_xxxx.log" 2>&1 &
        echo "`date +%Y/%m/%d-%H:%M:%S.%N`: Program [${tmpRunPre[$i]} ${tmpRunPath[$i]}/${tmpPName[$i]} ${tmpRunPara[$i]}] start running" >>${tmpAllLogDir}/"shStarProRoot"${tmpYMD}".log"
    fi
done

