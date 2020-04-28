#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20181129
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#   Determine whether the cpu occupancy rate of a program's process exceeds
#       a certain value. If it exceeds a certain value and continues for a 
#       while, kill it. 
#    
#
#############################################################################

if [ -f /etc/profile ]; then
    . /etc/profile
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile
fi

#get Cpu occupancy rate of the program
#input: getCputRate <xnum> <pname>
function getCpuRate()
{
	if [ $# -ne 2 ];then
		echo 0
		return 1
    	fi

	shDebugFlag=$1
	pname=$2

	tpid=$(pidof -x "${pname}")
	if [ -z ${tpid} ];then
		echo 0
		return 2
	fi


	tRate=$(top -n 1 -d 1 -b -p $(pidof -x "${pname}")|grep -w "${pname}"|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=$9;}} END{print tNum}')
	echo "${tRate}"

	return 0

}




#There are already scripts running to exit
tmpShPid=$(pidof -x $0)
tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
if [ ${tmpShPNum} -gt 1 ]; then
#    echo "+++${tmpShPid}+++++${tmpShPNum}+++"
#    echo "`date +%Y/%m/%d-%H:%M:%S.%N`:$0 script has been running this startup exit!"
    exit 0
fi


baseDir=$(dirname $0)
logDir=${baseDir}/log
if [ ! -d "${logDir}" ];then
	mkdir -p "${logDir}"
	if [ $? -ne 0 ];then
		exit 1
	fi
fi

maxCpuVal=0.1
interSends=1
numOfTime=20
pname=tt.sh
debufFlag=1

tmpYMD=$(date +%Y%m%d)
logPre=out
logName="${logDir}/${logPre}${tmpYMD}.log"
if [ ${debufFlag} -eq 1 ];then
	echo "">>${logName}
	echo "">>${logName}
	echo "--tmpYMD=[${tmpYMD}]---">>${logName}
	echo "--pname=[${pname}]---">>${logName}
	echo "--interSends=[${interSends}],numOfTime=[${numOfTime}]---">>${logName}
fi

#sleep 100


killFlag=1
for (( i=0;i<${numOfTime};i++))
do
	tRate=$(getCpuRate 0 "${pname}")
	retstat=$?
	if [ ${retstat} -ne 0 ];then
		killFlag=0
		break;
	fi

	isbig=$(echo "${tRate}>${maxCpuVal}"|bc)
	
	if [ ${debufFlag} -eq 1 ];then
		echo "	in for:---[${i}]---:tRate=[${tRate}],maxCpuVal=[${maxCpuVal}],isbig=[${isbig}]----+++">>${logName}
	fi

	if [ ${isbig} -eq 0 ];then
		killFlag=0
		break
	fi
	sleep ${interSends}
done

if [ ${debufFlag} -eq 1 ];then
	echo "======killFlag=[${killFlag}]===">>${logName}
fi

if [ ${killFlag} -eq 1 ];then
	tpid=$(pidof -x "${pname}")
	kill ${tpid}
	retstat=$?
	sleep 1

	tpid=$(pidof -x "${pname}")
	if [ ! -z ${tpid} ];then
		kill ${tpid}
		retstat=$?
	fi

	echo "">>${logName}
	echo "--numOfTime=[${numOfTime}],interSends=[${interSends}]">>${logName}
	echo "--tRate=[${tRate}],maxCpuVal=[${maxCpuVal}]">>${logName}
	echo "`date +%Y/%m/%d-%H:%M:%S.%N`: kill \$(pidof -x ${pname}); pid=[${tpid}];kill retstat=[${retstat}]!">>${logName}
	echo "">>${logName}
fi

#Delete the expired log
tlogMaxDay=300
tlogMaxSizeK=1
if [ "$(date +%H)" == "01" ];then
	ls -1 ${logDir}/${logPre}[0-9][0-9]*.log|while read tnaa
	do
		tdnum=$(echo "($(date +%s)-$(stat -c %Y ${tnaa}))/86400"|bc)
		tdifftd=$(echo "${tdnum}>${tlogMaxDay}"|bc)
		tsizeK=$(echo "$(stat -c %s ${tnaa})/1024"|bc )
		tdiffts=$(echo "${tsizeK}>${tlogMaxSizeK}"|bc)
		if [ ${tdifftd} -eq 1 ] && [ ${tdiffts} -eq 1 ];then
			rm -rf ${tnaa} 2>/dev/null
		fi

		if [ ${debufFlag} -eq 1 ];then
			echo "---Delete the expired log:tdnum=[${tdnum}],tlogMaxDay=[${tlogMaxDay}],tsizeK=[{$tsizeK}],tlogMaxSizeK=[${tlogMaxSizeK}],tnaa=[${tnaa}]">>${logName}
		fi

	done

fi

exit 0

