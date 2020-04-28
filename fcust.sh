#!/bin/sh


#############################################################################
#author       :    fushikai
#date         :    20181017
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Customize fusky's own habits
#    
#
#############################################################################

#baseDir=$(dirname $0)
#cd ${baseDir}



function writeSkyPP()
{
    tmpFile=$1
    
    if [[ ! -f ${tmpFile} ]];then
        echo "the file \"${tmpFile}\" does not exist"
        echo ""
        return 1
    fi
    
    ps1num=$(grep -v "^#" ${tmpFile} 2>/dev/null|grep -w PS1|wc -l)
    if [[ $ps1num -lt 1 ]];then
        echo 'export PS1="[\u@\h \w]\$"'">>${tmpFile}"
        echo 'export PS1="[\u@\h \w]\$"'>>${tmpFile}
    fi
    
    tmTynum=$(grep -v "^#" ${tmpFile} 2>/dev/null|grep -w TIME_STYLE|wc -l)
    if [[ $tmTynum -lt 1 ]];then
        echo "export TIME_STYLE='+%Y/%m/%d %H:%M:%S'>>${tmpFile}"
        echo "export TIME_STYLE='+%Y/%m/%d %H:%M:%S'">>${tmpFile}
    fi
    
    
    alianum1=$(grep -v "^#" ${tmpFile} 2>/dev/null|grep -w alias|grep -w cdwp|wc -l)
    if [[ $alianum1 -lt 1 ]];then
        echo "alias cdwp='cd /zfmd/wpfs20' >>${tmpFile}"
        echo "alias cdwp='cd /zfmd/wpfs20'">>${tmpFile}
    fi
    
    alianum2=$(grep -v "^#" ${tmpFile} 2>/dev/null|grep -w cdstartup|wc -l)
    if [[ $alianum2 -lt 1 ]];then
        echo "alias cdstartup='cd /zfmd/wpfs20/startup' >>${tmpFile}"
        echo "alias cdstartup='cd /zfmd/wpfs20/startup'">>${tmpFile}
    fi
    
    alianum3=$(grep -v "^#" ${tmpFile} 2>/dev/null|grep -w "ls -F"|wc -l)
    if [[ $alianum3 -lt 1 ]];then
        echo "alias ls='ls -F' >>${tmpFile}"
        echo "alias ls='ls -F'">>${tmpFile}
    fi
    
    alianum4=$(grep -v "^#" ${tmpFile} 2>/dev/null|grep -w "ls -lrt"|wc -l)
    if [[ $alianum4 -lt 1 ]];then
        echo "alias lrt='ls -lrt' >>${tmpFile}"
        echo "alias lrt='ls -lrt'">>${tmpFile}
    fi

}


rtshrc=/root/.bashrc
zfshrc=/home/zfmd/.bashrc

if [[ -f ${rtshrc} && -w ${rtshrc} ]];then
    echo ""
    writeSkyPP "${rtshrc}"
    echo ""
fi

if [[ -f ${zfshrc} && -w ${zfshrc} ]];then

    echo ""
    writeSkyPP "${zfshrc}"
    echo ""
    
    dgzfname=$(stat --format=%G ${zfshrc})
    duzfname=$(stat --format=%U ${zfshrc})
    if [[ "$dgzfname" != "manager" || "$duzfname" != "zfmd" ]];then
        echo "chown -R zfmd:manager ${zfshrc}"
        chown -R zfmd:manager ${zfshrc}
    	echo ""
    fi
fi
