#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20180810
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    create user:zfmd,audit,security;and change passwords 
#history:
#       20181225 modify
#    
#
#############################################################################

if [[ $# -lt 1 ]];then
    echo "please input like: $0 <[mete]/[scada]/[pre1]/[pre2]/[gzz]>"
    echo ""
    exit 1
fi

if [[ "$1" != "mete" && "$1" != "scada" && "$1" != "pre1" && "$1" != "pre2" && "$1" != "gzz" ]];then
    echo "parameter error,please input like: $0 <[mete]/[scada]/[pre1]/[pre2]/[gzz]>"
    echo ""
    exit 2
fi

baseDir=$(dirname $0)

fncFile=${baseDir}/../../shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "eror: [${fncFile}] file does not exist"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}

#define the file to be edited
shadFile=/etc/shadow
pwdFile=/etc/passwd
grpFile=/etc/group

#create new user and change password
################1.add administrator account group
if [[ "$1" = "mete" || "$1" = "scada" || "$1" = "pre1" || "$1" = "pre2" || "$1" = "gzz" ]];then

    groupAdd manager
        
    #################2.add admiistrator account OR modify users group
    useraddOrChgrp "zfmd" "manager"
    useraddOrChgrp "audit" "root"
    useraddOrChgrp "security" "manager"

    echo ""
fi
#################2.1 add gzz account
if [[ "$1" = "gzz" ]];then
    echo "====operate gzz users"
    useraddOrChgrp "gzz" "gzz"
    echo ""
fi    

#################2.2 add oracle account
if [[ "$1" = "pre1" || "$1" = "pre2" ]];then
    echo "====operate oracle users"

    groupAdd oinstall
    groupAdd dba
    
    useraddOrChgrp "oracle" "oinstall" "dba" 
    echo ""
fi    

#################zhuang he 4.change password, "openssl passwd -1"
echo 'chpasswd -e '

chgUPwd "root" '$1$5n5jxvZJ$1A7ogGhPTczgjGYjX/bp51'

chgUPwd "security" '$1$fBUsY7.D$WlETb1sdQP1o8lriKKQ1F0'

chgUPwd "zfmd" '$1$l6LpKKto$UaKdUgTXL/3I5e3gHqA.5.' 

chgUPwd "audit" '$1$L4wFr9Lt$8TxStwZgdgx5Da2umdolC0'

chgUPwd "gzz" '$1$A5ZMv/7u$NNgvcT3aTmRGfvnU8Pyp40'

chgUPwd "oracle" '$1$13ucJhDn$Fs2buo1iHsHwPh86Sol8N/'

cd /

#################5.modify folder owner

mkpDir /zfmd/tmp

chgUandGzfmd zfmd manager /zfmd


uornum=$(egrep -w "^oracle" ${pwdFile}|wc -l)
if [[ $uornum -gt 0 ]]; then

    mkpDir /zfmd/oracle
    chgUandGzfmd oracle oinstall /zfmd/oracle
    
    mkpDir /zfmd/wpfs20/oradata
    chgUandGzfmd oracle oinstall /zfmd/wpfs20/oradata
    
    setPermission /zfmd/oracle 755 

    goranum=$(egrep -w "^oinstall" ${grpFile}|wc -l)
    if [[ $goranum -gt 0 ]];then
        chgUandGzfmd oracle oinstall /zfmd/tmp
    fi

    setPermission /zfmd/tmp 777
    
fi

echo ""
echo "script [$0] execution completed !!"
echo ""
exit 0

