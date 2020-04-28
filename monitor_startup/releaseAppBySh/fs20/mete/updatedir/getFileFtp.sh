#!/bin/bash
#shell功能描述:从ftp服务器下载文件
#author:
#date:20170622135956
#getFileFtp.sh
#eg:getFileFtp.sh "192.168.0.154" "Administrator" "qwer1234" "/tmp" "/home/zfmd/tmp" "Makefile"		

. ~/.bash_profile >/dev/null 2>&1

shNAME="getFileFtp"

#打印日志级别标识
#可辨别的级别为2的N(N>=0)次方,即0，1，2，4，8 ...;其中0为不打印日志
#各级别之间可以组合
shDebugFlag=16

#如需要个性化的日志目录需要配置环境变量 RMETEMAINP 如 RMETEMAINP = /home/zfmd
#否则默认在程序运行的上级目录下log文件夹 
if [[ -z ${RMETEMAINP} ]]; then
    RMETEMAINP=$(dirname $(dirname $0))
    if [[ ! -d ${RMETEMAINP}/log ]]; then
        mkdir -p ${RMETEMAINP}/log
        if [[ $? -eq 0 && "$((${shDebugFlag}&1))" -eq 1 ]]; then
            echo $(date "+%Y/%m/%d %H:%M:%S.%N")" mkdir -p ${RMETEMAINP}/log" >>${RMETEMAINP}/log/${shNAME}.log
        fi
    fi
fi
logFile=${RMETEMAINP}/log/${shNAME}.log


if [[ "$((${shDebugFlag}&16))" -eq 16 ]]; then
    echo $(date "+%Y/%m/%d %H:%M:%S.%N")" ${shNAME}.sh:$#:start -->" >>${logFile}
fi
if [[ "$((${shDebugFlag}&2))" -eq 2 ]]; then
    echo $(date "+%Y/%m/%d %H:%M:%S.%N")" --debug:input param nums:$#" >>${logFile}
    echo $(date "+%Y/%m/%d %H:%M:%S.%N")" --logFile=[${logFile}]" >>${logFile}
fi



if [[ $# -ne 6 && $# -ne 7 ]];then
	echo $(date "+%Y/%m/%d %H:%M:%S.%N")" input error,please input like this:"|tee -a ${logFile}
	echo $(date "+%Y/%m/%d %H:%M:%S.%N")"       ${shNAME}.sh <ftpIP> <ftpUser> <ftpPwd> <ftpRdir> <ftpLdir> <fileName>"|tee -a ${logFile}
	exit 1
fi

#最得临时目录
runDir=$(dirname $0)
tmpDir=${runDir}/tmpD
if [[ ! -d ${tmpDir} ]]; then
    mkdir -p ${tmpDir}
    if [[ "$((${shDebugFlag}&1))" -eq 1 ]]; then
        echo $(date "+%Y/%m/%d %H:%M:%S.%N")" mkdir -p ${tmpDir}" >>${logFile}
    fi
fi

if [ "${runDir}" == "." ];then
    prunDir=".."
else
    prunDir=$(dirname ${runDir})
fi

dRelaPath=filedo/down/back
dBackDir=${prunDir}/${dRelaPath}
if [ ! -d ${dBackDir} ];then
	if [ -f ${dBackDir} ];then
		echo "mv ${dBackDir} ${dBackDir}.$(date '+%Y%m%d%H%M%S')">>${logFile}
		mv ${dBackDir} ${dBackDir}.$(date '+%Y%m%d%H%M%S')
	fi
    echo "mkdir -p ${dBackDir}">>${logFile}
    mkdir -p ${dBackDir}
fi

funcFlag=0
diyFuncFile=${runDir}/meteShFunc.sh
if [ -f ${diyFuncFile} ];then
	. ${diyFuncFile}
	funcFlag=1
fi

#ip地址
ftpIP=$1
#用户名
ftpUser=$2
#密码
ftpPwd=$3
#ftp服务器上的下载目录
ftpRdir=$4
#ftp客户端文件下载的临时目标目录
ftpLdir=${tmpDir}
#ftp客户端文件下载后移动的目标目录
ftpLdirAims=$5
#需要下载的文件名
fileName=$6

#默认端口号
if [[ $# -eq 6 ]];then
    ftpCtrPNum=21
else
    ftpCtrPNum=$7
fi  
  
#ftp -n ${ftpIP} ${ftpCtrPNum}<<!
#	user ${ftpUser} ${ftpPwd}
#	cd ${ftpRdir}
#	lcd ${ftpLdir}
#	get ${fileName}
#	bye
#!

ftpTrType="ascii"

if [[ "$((${shDebugFlag}&4))" -eq 4 ]]; then
    echo "shDebugFlag=[${shDebugFlag}]">>${logFile}
    echo "">>${logFile}
    echo "---------ftp para begine--------">>${logFile}
    echo "----ftpIP     =[${ftpIP}]">>${logFile}
    echo "----ftpUser   =[${ftpUser}]">>${logFile}
    echo "----ftpPwd    =[${ftpPwd}]">>${logFile}
    echo "----ftpRdir   =[${ftpRdir}]">>${logFile}
    echo "----ftpLdir   =[${ftpLdir}]">>${logFile}
    echo "----fileName  =[${fileName}]">>${logFile}
    echo "----ftpCtrPNum=[${ftpCtrPNum}]">>${logFile}
    echo "----ftpTrType =[${ftpTrType}]">>${logFile}
    echo "---------ftp para end----------">>${logFile}
fi

ftpRet=$(echo "user ${ftpUser} ${ftpPwd}
      ${ftpTrType}
	  cd ${ftpRdir}
	  lcd ${ftpLdir}
	  prompt
	  mget ${fileName}
	  bye"|ftp -n ${ftpIP} ${ftpCtrPNum} 2>&1|while read tmpRead
do	  
echo ${tmpRead}	 
done);

if [[ "$((${shDebugFlag}&1))" -eq 1 ]]; then
        echo $(date "+%Y/%m/%d %H:%M:%S.%N")" ftpRet=[${ftpRet}]" >>${logFile}
fi


declare -i mvFlag=0
declare -i rmFlag=0

#判断文件是否下到相应目录
numDFiles=$(ls -1 ${ftpLdir}/${fileName} 2>/dev/null|wc -l)
if [[ ${numDFiles} -gt 0 ]];then
    #删除ftp server上的文件
     ftpRetD=$(echo "user ${ftpUser} ${ftpPwd}
	  cd ${ftpRdir}
	  lcd ${ftpLdir}
	  prompt
	  mdelete ${fileName}
	  bye"|ftp -n ${ftpIP} ${ftpCtrPNum} 2>&1|while read tmpRead
      do	  
        echo ${tmpRead}	 
      done);
      
      if [[ "$((${shDebugFlag}&1))" -eq 1 ]]; then
        echo $(date "+%Y/%m/%d %H:%M:%S.%N")" numDFiles=[${numDFiles}],ftpRetD=[${ftpRetD}]" >>${logFile}
      fi
      
     #去掉文件的回车符号
    ls -1 ${ftpLdir}/${fileName}|while read trName
    do
        if [[ "$((${shDebugFlag}&8))" -eq 8 ]]; then
            echo "++++++${trName} ">>${logFile}
        fi
        tr -d '\r' < ${trName} >${trName}".rtmp" && mv -f ${trName}".rtmp" ${trName}
    done
    
     #移动下载后的文件到目标目录
	 declare -i opNum=0
	 declare -i maxOpNum=100
	 ls -1 ${ftpLdir}/${fileName}|while read rfName
	 do
		 mvFlag=0
         rmFlag=0
         opNum=0

		 trfName=$(getFnameOnPath ${rfName})
		 statf=$?
		 if [ ${funcFlag} -eq 1 ] && [ ${statf} -eq 0 ];then
			deterSameFile ${shDebugFlag} ${dBackDir} ${trfName}	
			stat=$?
			if [ ${stat} -eq 2 ];then
				cp -f ${rfName} ${dBackDir}
				mvFlag=1
			elif [ ${stat} -eq 0 ];then
				#文件已经存在则把新下载的文件进行删除
				rmFlag=1
			fi
		 else
			 mvFlag=1
		 fi
            echo "++++fusktest++++mvFlag=[${mvFlag}],rmFlag=[${rmFlag}],trfName=[${trfName}],statf=[${statf}],stat=[${stat}] ">>${logFile}

		 if [ ${rmFlag} -eq 1 ];then
			 opNum=0
			 rm -rf ${rfName}
			 while [[ $? -ne 0 ]]
			 do
				 let opNum++
				 if [ ${opNum} -gt ${maxOpNum} ];then
					echo "$(date '+%Y/%m/%d %H:%M:%S.%N') rm ${rfName} error">>${logFile}
					break
				 fi
				 sleep 1
				 rm -rf ${rfName}
			 done
			echo "$(date '+%Y/%m/%d %H:%M:%S.%N') The file[${trfName}] downloaded from the [${ftpIP}:${ftpCtrPNum}${ftpRdir}]service already exists and will be deleted ">>${logFile}
		fi

		 if [ ${mvFlag} -eq 1 ];then
			 opNum=0
			 mv ${rfName} ${ftpLdirAims}
			 while [[ $? -ne 0 ]]
			 do
				 let opNum++
				 if [ ${opNum} -gt ${maxOpNum} ];then
					echo "$(date '+%Y/%m/%d %H:%M:%S.%N') mv ${rfName} ${ftpLdirAims} error">>${logFile}
					break
				 fi
				 sleep 1
				 mv ${rfName} ${ftpLdirAims}
			 done
		fi

	 done

#	 if [ ${mvFlag] -eq 1 ];then
#		 mv ${ftpLdir}/${fileName} ${ftpLdirAims}
#		 while [[ $? -ne 0 ]]
#		 do
#			 let opNum++
#			 if [ ${opNum} -gt ${maxOpNum} ];then
#				echo "$(date '+%Y/%m/%d %H:%M:%S.%N') mv ${ftpLdir}/${fileName} ${ftpLdirAims} error">>${logFile}
#				break
#			 fi
#			 sleep 1
#			 mv ${ftpLdir}/${fileName} ${ftpLdirAims}
#		 done
# 	fi
	
	#删除过期的文件
	rmExName="busilist_*"
	rmExDay=5
	if [ ${funcFlag} -eq 1 ];then
		rmExpiredFile "${dBackDir}" "${rmExDay}" "${rmExName}" >>${logFile} 2>&1
	fi
    
    if [[ "$((${shDebugFlag}&16))" -eq 16 ]]; then
        echo $(date "+%Y/%m/%d %H:%M:%S.%N")" ${shNAME}.sh:$#:end ">>${logFile}
        echo "">>${logFile}
    fi
    if [ ${rmFlag} -eq 1 ];then
        exit 3
    else
        exit 0
    fi
else
    if [[ "$((${shDebugFlag}&16))" -eq 16 ]]; then
        echo $(date "+%Y/%m/%d %H:%M:%S.%N")" ${shNAME}.sh:$#:unsucessfull ">>${logFile}
        echo "">>${logFile}
    fi
    exit 2
fi




