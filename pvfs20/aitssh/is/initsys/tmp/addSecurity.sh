#!/bin/sh


#############################################################################
#author       :    fushikai
#date         :    20180813
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#        change password complexity limit,password expiration date,
#        and login limit 
#modfiy history:
#   20181227@add setEnvOneVal   
#
#############################################################################

baseDir=$(dirname $0)

fncFile=${baseDir}/shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "eror: [${fncFile}] file does not exist"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}

if [[ ${ZFMD_USER} == "" ]];then
    echo "环境变量错误"
    exit 1
fi

#密码限制
#minlen 最少长度
#ucredit 大写
#lcredit 小写
#dcredit 数字
#ocredit 特殊字符
#retry  重试次数
editAuth=/etc/pam.d/system-auth
#editAuth=/root/tmp/fusk/system-auth
addAuth="password    requisite     pam_cracklib.so  retry=5 minlen=8 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1"
setEnvOneVal "${editAuth}" "password" 'requisite\s*pam_cracklib.so' "${addAuth}" "#"


#有效期及长度
pLogName=/etc/login.defs
#pLogName=/root/tmp/fusk/login.defs
pMaxDays="PASS_MAX_DAYS    90"
pMinDays="PASS_MIN_DAYS    0"
pMinLen="PASS_MIN_LEN    8"
pWarnAge="PASS_WARN_AGE    10"

if [[ -f $pLogName ]];then
    setEnvOneVal "${pLogName}" "PASS_MAX_DAYS" '[0-9][0-9]*' "${pMaxDays}" "#" '^\s*#s*PASS_WARN_AGE'
    setEnvOneVal "${pLogName}" "PASS_MIN_DAYS" '[0-9][0-9]*' "${pMinDays}" "#" '^PASS_MAX_DAYS'
    setEnvOneVal "${pLogName}" "PASS_MIN_LEN" '[0-9][0-9]*' "${pMinLen}" "#" '^PASS_MIN_DAYS'
    setEnvOneVal "${pLogName}" "PASS_WARN_AGE" '[0-9][0-9]*' "${pWarnAge}" "#" '^PASS_MIN_LEN'
fi

#------------------------------------登录限制
#ssh
#auth       required     pam_tally2.so deny=5 unlock_time=600 even_deny_root root_unlock_time=600
editsshd=/etc/pam.d/sshd
#editsshd=/root/tmp/fusk/sshd
addsshd="auth       required     pam_tally2.so deny=4 unlock_time=600"
setEnvOneVal "${editsshd}" "auth" 'required\s*pam_tally2.so' "${addsshd}" "#"


#login
#auth       required     pam_tally2.so deny=5 unlock_time=600 even_deny_root root_unlock_time=600
editlogin=/etc/pam.d/login
#editlogin=/root/tmp/fusk/login
addlogin="auth       required     pam_tally2.so deny=4 unlock_time=600"
setEnvOneVal "${editlogin}" "auth" 'required\s*pam_tally2.so' "${addlogin}" "#"

#remote
editremote=/etc/pam.d/remote
#editremote=/root/tmp/fusk/remote
addremote="auth       required     pam_tally2.so deny=4 unlock_time=600"
setEnvOneVal "${editremote}" "auth" 'required\s*pam_tally2.so' "${addremote}" "#"


echo ""
echo "script [$0] execution completed !!"
echo ""

exit 0




