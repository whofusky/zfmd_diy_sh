#!/bin/bash

#shell功能描述:上传文件到sftp服务器
#author:
#date:201808100919

. ~/.bash_profile >/dev/null 2>&1

#打印日志级别标识
#可辨别的级别为2的N(N>=0)次方,即0，1，2，4，8 ...;其中0为不打印日志
#各级别之间可以组合
shDebugFlag=0

#如需要个性化的日志目录需要配置环境变量 RMETEMAINP 如 RMETEMAINP = /home/zfmd
#否则默认在程序运行的上级目录下log文件夹 
if [ -z ${RMETEMAINP} ]; then
    RMETEMAINP=$(dirname $0)
    if [ ! -d ${RMETEMAINP}/log ]; then
        mkdir -p ${RMETEMAINP}/log
    fi
fi
logFile=${RMETEMAINP}/log/sftpPut1.log


busiName=busilist_$(date "+%Y%m%d")_*.xml


#ip地址
ftpIP=192.168.0.51
#用户名
ftpUser=zfmd
#密码
ftpPwd=Hnglsfdc_0791
#ftp服务器上的下载目录
ftpRdir=/zfmd/wpfs20/ri2data
#ftp客户端文件下载的目标目录
ftpLdir=/zfmd/wpfs20/ri2data
#需要下载的文件名
fileName=${busiName}

#默认端口号
ftpCtrPNum=22


busiNum=$(ls -1 ${ftpLdir}/${fileName} 2>/dev/null|wc -l)

#echo ${busiNum}
#echo ${ftpLdir}/${fileName}

if [[ ${busiNum} -lt 1 ]];then
	if [[ "$((${shDebugFlag}&1))" -eq 1 ]]; then
		echo $(date "+%Y/%m/%d %H:%M:%S.%N")" sftpPut1.sh:$#:no file ${ftpLdir}/${fileName}">>${logFile}
	fi
	exit 0
fi


echo $(date "+%Y/%m/%d %H:%M:%S.%N")" sftpPut1.sh:$#:start -->">>${logFile}
echo "busiNum=[$busiNum]">>${logFile}


echo "cd ${ftpRdir}
          lcd ${ftpLdir}
          mput ${fileName}
          bye"|lftp -e "set net:timeout 10;set net:max-retries 2;set net:reconnect-interval-base 10;" -u ${ftpUser},${ftpPwd} sftp://${ftpIP}:${ftpCtrPNum} 2>&1 |while read aa
do

		echo "[${aa}]">>${logFile}

		#登录失败
		TTNUM=$(echo ${aa}|grep "严重错误"|wc -l)
		if [ "${TTNUM}" -gt 0 ];then
				echo "login error!">>${logFile}
				exit 1
		fi

		#登录失败
		TTNUM=$(echo ${aa}|grep -E "Login[ ]+incorrect"|wc -l)
		if [ "${TTNUM}" -gt 0 ];then
				echo "Incorrect username or password,login faild!">>${logFile}
				exit 1
		fi

		#没有服务的目录
		TTNUM=$(echo ${aa}|grep -E "Access[ ]+failed"|grep "${ftpRdir}"|wc -l)
		if [ "${TTNUM}" -gt 0 ];then
				echo "The server's specific directory ${ftpRdir} does not exist!">>${logFile}
				exit 2
		fi

		#本地客户端上传文件目录不存在
		TTNUM=$(echo ${aa}|grep "${ftpLdir}"|wc -l)
		if [ "${TTNUM}" -gt 0 ];then
				echo "There is no local directory ${ftpLdir}!">>${logFile}
				exit 3
		fi

		#上传文件不存在
		TTNUM=$(echo ${aa}|grep -E "mput:[ ]+${fileName}:[ ]+no[ ]+files[ ]+found"|wc -l)
		if [ "${TTNUM}" -gt 0 ];then
				echo "Upload file ${fileName} does not exist!">>${logFile}
				exit 4
		fi

done

retFlag=$?
#echo ${retFlag}
if [ "${retFlag}" -ne 0 ];then
	echo "retFlag=$retFlag}">>${logFile}
    exit ${retFlag}
fi


if [ ! -d ${RMETEMAINP}/baktmp ]; then
        mkdir -p ${RMETEMAINP}/baktmp
		echo "mkdir -p ${RMETEMAINP}/baktmp">>${logFile}
fi

mv ${ftpLdir}/${fileName} ${RMETEMAINP}/baktmp
if [[ $? -ne 0 ]];then
	echo "mv ${ftpLdir}/${fileName} ${RMETEMAINP}/baktmp  error=$?">>${logFile}
fi


echo $(date "+%Y/%m/%d %H:%M:%S.%N")" putFileSFtp.sh:$#:end -->$(date "+%Y/%m/%d %H:%M:%S.%N")">>${logFile}

exit 0


