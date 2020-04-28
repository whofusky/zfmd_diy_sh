#!/bin/bash


#############################################################################
#author       :    fushikai
#date         :    20181113
#linux_version:    Red Hat Enterprise Linux Server release 6.7 
#dsc          :   
#    Some functions used in the Zone III weather download script
#
#############################################################################


#打印函数入参
#  用法: prtFuncInput [函数名文件名] $@
function prtFuncInput()
{
	fName=$1
	shift
	echo "The input of function [ ${fName}] is as follows:"
	declare -i i=1
	for tmp in "$@"
	do  
		if [ $i -lt 10 ];then
			echo "  0$i: [${tmp}]"
		else
			echo "  $i: [${tmp}]"
		fi
		let i++ 
	done
	echo ""
	
}


#取路径字符串的文件名
function getFnameOnPath()
{

	allName=$1
	if [ -z ${allName} ];then
		echo ""
		return 1;
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


#取得字符串中的路径值(路径最后不带/)
function getPathOnFname()
{

	allName=$1
	if [ -z ${allName} ];then
		echo ""
		return 1;
	fi

	slashNum=$(echo ${allName}|grep "/"|wc -l)
	if [ ${slashNum} -eq 0 ];then
		echo "" 
		return 2 
	fi

	fPath=$(echo ${allName}|awk -F'/' '{for (i=1;i<NF;i=i+1){printf "%s/",$i}}'|sed 's/\/$//g')
	echo ${fPath}

	return 0
}



#删除目录下过期(超过x天数未修改的)文件
#  入参：
#     (1) 目录 天数 文件名或带通配符的文件名
#     (2) 目录 天数
function rmExpiredFile()
{
	if [ $# -ne 2 ] && [ $# -ne 3 ];then
		return 1
	fi

	tpath=$1
	if [ ! -d ${tpath} ];then
		return 2
	fi

	tdays=$2
	if [ $# -eq 3 ];then
		tname=$3
	else
		tname="*"
	fi

	#echo "++++++[${tpath}/${tname}]+++"
	ls -1d ${tpath}/${tname} 2>/dev/null|while read tnaa
	do
		if [ -d "${tnaa}" ];then
			continue
		fi
		#echo "---[${tnaa}]--"
		tdnum=$(echo "($(date +%s)-$(stat -c %Y ${tnaa}))/86400"|bc)
		tdifftd=$(echo "${tdnum}>${tdays}"|bc)
		if [ ${tdifftd} -eq 1 ] && [ -w ${tnaa} ];then
			rm -rf ${tnaa} 2>/dev/null
		fi	
	done

	return 0
}



#判断某个目录下是否有同样的文件存在
#      用法:  deterSameFile [日志输入级别] [文件所在路径] [文件名]
#  返回状态:
#     100 : 函数参数错误
#     0   : 文件存在
#     1   : 目录不存在
#     2   : 文件不存在
function deterSameFile()
{
	myFuncName="deterSameFile"
	
	if [ $# -lt 3 ];then
		echo ""
		echo "Call shell function [ ${myFuncName} ] parameter number error"
		return 100
	fi

	#打印日志级别标识
	#可辨别的级别为2的N(N>=0)次方,即0，1，2，4，8 ...;其中0为不打印日志
	#各级别之间可以组合
	shDebugFlag=$1

	tDir=$2
	tFname=$3

	declare -i ret=0

	if [[ $((${shDebugFlag}&1)) -eq 1 ]]; then
		echo ""
		echo "$(date '+%Y/%m/%d %H:%M:%S.%N'):Enter the shell function [${myFuncName}]"
	fi
	
	if [[ $((${shDebugFlag}&2)) -eq 2 ]]; then
		prtFuncInput ${myFuncName} $@
	fi
	
	if [ ! -d ${tDir} ];then
		ret=1
	elif [ ! -f ${tDir}/${tFname} ];then
		ret=2
	fi	

	if [[ $((${shDebugFlag}&1)) -eq 1 ]]; then
		echo "$(date '+%Y/%m/%d %H:%M:%S.%N'):shell function [${myFuncName}] excution ends,ret=[${ret}]"
		echo ""
	fi

	return ${ret}
	
}

