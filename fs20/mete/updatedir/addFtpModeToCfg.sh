#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20190124
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Modify the configuration file of the weather downloader program add
#    "trsType" and "trsMode" configuration attributes to the ftp configuration
#    section.
#
#############################################################################

#edfile=locaCfg.xml
edfile=/zfmd/wpfs20/mete/cfg/locaCfg.xml

if [ ! -f "${edfile}" ];then
    echo -e "\n\tError: the edit file [${edfile}] not exist!\n"
    exit 1
fi

baseDir=$(dirname $0)

fncFile=${baseDir}/../../../shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "eror: [${fncFile}] file does not exist"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}


#declare -i lnum=0
addc1='trsType="0" trsMode="0"'
searw="trsType"
addcm1='<!--trsType 0:ascii ,1:binary;trsMode 0:passive, 1:active-->'

chgFlag=0
for i in $( sed -n "/<FtpSer/=" "${edfile}")
do
    #determine if there is an xml comment
    tnum=$(sed -n "${i}p" ${edfile}|sed -n  '/<\s*!-\{2,\}.*-\{2,\}\s*>/p'|wc -l)
    tnuma=$(sed -n "${i}p" ${edfile}|sed -n "/\<${searw}\>/p"|wc -l)
    if [ ${tnum} -gt 0 -a ${tnuma} -eq 0 ];then
        #remove the xml comment
        chgFlag=1
    fi
    
    #add content
    tnuma=$(sed -n "${i}p" ${edfile}|sed -n "/\<${searw}\>/p"|wc -l)
    if [ ${tnuma} -eq 0 ];then
        chgFlag=1
    fi

done

timestamp=$(date  +%Y%m%d%H%M%S)

zUserN=zfmd
zGrpN=manager

#back up the file to be modified
tFileName=$(getFnameOnPath "${edfile}")
tfret=$?
bkdir=/zfmd/wpfs20/backup
bkmtdir=/zfmd/wpfs20/backup/mete
if [ ${chgFlag} -eq 1 ];then
    if [ ! -d ${bkdir} ];then
        echo -e "\n\tcp ${edfile} \"${edfile}_${timestamp}\"\n"
        cp ${edfile} "${edfile}_${timestamp}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${edfile}_${timestamp}"
    else
        mkpDir "${bkmtdir}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${bkmtdir}"
        if [ ${tfret} -eq 0 ];then
            echo -e "\n\tcp ${edfile} \"${bkdir}/${tFileName}_${timestamp}\"\n"
            cp ${edfile} "${bkdir}/${tFileName}_${timestamp}"
            chgUandGzfmd "${zUserN}" "${zGrpN}" "${bkdir}/${tFileName}_${timestamp}"
        fi
    fi
fi

for i in $( sed -n "/<FtpSer/=" "${edfile}")
do
    #determine if there is an xml comment
    tnum=$(sed -n "${i}p" ${edfile}|sed -n  '/<\s*!-\{2,\}.*-\{2,\}\s*>/p'|wc -l)
    tnuma=$(sed -n "${i}p" ${edfile}|sed -n "/\<${searw}\>/p"|wc -l)
    if [ ${tnum} -gt 0 -a ${tnuma} -eq 0 ];then
        #remove the xml comment
        echo -e "\n\tremove the xml comment before:"
        sed -n "${i}p" ${edfile}
        sed ${i}'s/<\s*!-\{2,\}.*-\{2,\}\s*>//g' -i ${edfile}
        echo -e "\n\tremove the xml comment end:"
        sed -n "${i}p" ${edfile}
        echo -e "\n"
    fi
    
    #add content
    tnuma=$(sed -n "${i}p" ${edfile}|sed -n "/\<${searw}\>/p"|wc -l)
    if [ ${tnuma} -eq 0 ];then
        echo -e "\n\tadd content before:"
        sed -n "${i}p" ${edfile}
        sed -e "${i} s/>/ ${addc1}&/g;${i} s/>/& ${addcm1}/g" -i ${edfile}
        echo -e "\n\tadd content end:"
        sed -n "${i}p" ${edfile}
        echo -e "\n"
    fi

done

exit 0
