#!/bin/bash
#shell��������:��ftp�����������ļ�
#author:
#date:20170622135956
#getFileFtp.sh
#eg:getFileFtp.sh "192.168.0.154" "Administrator" "qwer1234" "/tmp" "/home/zfmd/tmp" "Makefile"		

. ~/.bash_profile >/dev/null 2>&1

shNAME="getFileFtp"

#��ӡ��־�����ʶ
#�ɱ��ļ���Ϊ2��N(N>=0)�η�,��0��1��2��4��8 ...;����0Ϊ����ӡ��־
#������֮��������
shDebugFlag=16

#����Ҫ���Ի�����־Ŀ¼��Ҫ���û������� RMETEMAINP �� RMETEMAINP = /home/zfmd
#����Ĭ���ڳ������е��ϼ�Ŀ¼��log�ļ��� 
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

#�����ʱĿ¼
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

#ip��ַ
ftpIP=$1
#�û���
ftpUser=$2
#����
ftpPwd=$3
#ftp�������ϵ�����Ŀ¼
ftpRdir=$4
#ftp�ͻ����ļ����ص���ʱĿ��Ŀ¼
ftpLdir=${tmpDir}
#ftp�ͻ����ļ����غ��ƶ���Ŀ��Ŀ¼
ftpLdirAims=$5
#��Ҫ���ص��ļ���
fileName=$6

#Ĭ�϶˿ں�
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

#�ж��ļ��Ƿ��µ���ӦĿ¼
numDFiles=$(ls -1 ${ftpLdir}/${fileName} 2>/dev/null|wc -l)
if [[ ${numDFiles} -gt 0 ]];then
    #ɾ��ftp server�ϵ��ļ�
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
      
     #ȥ���ļ��Ļس�����
    ls -1 ${ftpLdir}/${fileName}|while read trName
    do
        if [[ "$((${shDebugFlag}&8))" -eq 8 ]]; then
            echo "++++++${trName} ">>${logFile}
        fi
        tr -d '\r' < ${trName} >${trName}".rtmp" && mv -f ${trName}".rtmp" ${trName}
    done
    
     #�ƶ����غ���ļ���Ŀ��Ŀ¼
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
				#�ļ��Ѿ�������������ص��ļ�����ɾ��
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
	
	#ɾ�����ڵ��ļ�
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




