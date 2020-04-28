#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20181026
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    excute this shell script to update the user's last password change time 
#    in the system,in order to solve the problem that the user password will
#    expire without changing the password
#
#############################################################################


function upPwdChgTm()
{
	curYMD=$(date "+%Y-%m-%d")
	curYMDF1=$(date "+%Y%m%d")
	
	
	pwdFile=/etc/passwd
	shadFile=/etc/shadow
	
	uname=$1
	unum=$(egrep "^${uname}" ${pwdFile}|wc -l)
	if [ ${unum} -gt 0 ]; then
		tdays=$(egrep "^${uname}" ${shadFile}|awk -F':' '{print $3}')
		tchgdate=$(date -d "1970-01-01  $(($tdays * 86400)) seconds" +"%Y%m%d")
		if [ "${tchgdate}" != "${curYMDF1}" ];then
		    chage -d ${curYMD} ${uname} && echo "" && echo "chage -d ${curYMD} ${uname}" && echo ""
		fi
	fi
}

upPwdChgTm "zfmd"
upPwdChgTm "audit"
upPwdChgTm "security"
upPwdChgTm "root"
upPwdChgTm "oracle"
upPwdChgTm "gzz"

echo ""
echo "script [$0] execution completed !!"
echo ""

