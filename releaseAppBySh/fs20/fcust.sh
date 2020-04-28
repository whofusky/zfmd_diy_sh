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

baseDir=$(dirname $0)

fncFile=${baseDir}/../shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "eror: [${fncFile}] file does not exist"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}

function writeSkyPP()
{
    tmpDir=$1
    
    if [[ ! -d ${tmpDir} ]];then
        echo "the dir \"${tmpDir}\" does not exist"
        echo ""
        return 1
    fi
    
    bashrcName=${tmpDir}/.bashrc
    edVimrcF=${tmpDir}/.vimrc

    if [ ! -f "${bashrcName}" ];then
        echo "create the file \"${bashrcName}\""
        echo "">${bashrcName}
    fi
    if [ ! -f "${edVimrcF}" ];then
        echo "create the file \"${bashrcName}\""
        echo "">${edVimrcF}
    fi

    aliasN1="alias ls='ls -F'"
    aliasN2="alias l='ls -l'"
    aliasN3="alias lrt='ls -lrt'"
    aliasN4="alias cdwp='cd /zfmd/wpfs20'"
    aliasN5="alias cdstartup='cd /zfmd/wpfs20/startup'"
    PS1Add="export PS1='[\u@\h \w]\$'"
    PS1Addsed='export PS1='"'"'[\\u@\\h \\w]\\$'"'"
    timeStyle="export TIME_STYLE='+%Y/%m/%d %H:%M:%S'"

    if [[ -f $bashrcName ]];then
        setEnvOneVal "$bashrcName" "alias" "ls" "$aliasN1" "#"
        setEnvOneVal "$bashrcName" "alias" "l" "$aliasN2" "#"
        setEnvOneVal "$bashrcName" "alias" "lrt" "$aliasN3" "#"
        setEnvOneVal "$bashrcName" "alias" "cdwp" "$aliasN4" "#"
        setEnvOneVal "$bashrcName" "alias" "cdstartup" "$aliasN5" "#"

        setEnvOneVal "$bashrcName" "export" "PS1" "$PS1Addsed" "#"
        setEnvOneVal "$bashrcName" "export" "TIME_STYLE" "$timeStyle" "#"
    fi

    ecd1="set encoding=utf-8"
    ecd2="set fileencodings=ucs-bom,utf-8,cp936,latin1"
    ecd3="set fileencoding=gb2312"
    ecd4="set termencoding=utf-8"
    ecd5="set hlsearch"
    ecd6="set ts=4"
    ecd7="set expandtab"
    ecd8="set nu"
    ecd9="set shiftwidth=4"

    which vim >/dev/null 2>&1
    if [[ $? -eq 0 && -f $edVimrcF ]];then
        
        setEnvOneVal "$edVimrcF" "set" "encoding" "$ecd1" '\"'
        setEnvOneVal "$edVimrcF" "set" "fileencodings" "$ecd2" '\"'
        setEnvOneVal "$edVimrcF" "set" "fileencoding" "$ecd3" '\"'
        setEnvOneVal "$edVimrcF" "set" "termencoding" "$ecd4" '\"'
        setEnvOneVal "$edVimrcF" "set" "hlsearch" "$ecd5" '\"'
        setEnvOneVal "$edVimrcF" "set" "ts" "$ecd6" '\"'
        setEnvOneVal "$edVimrcF" "set" "expandtab" "$ecd7" '\"'
        setEnvOneVal "$edVimrcF" "set" "nu" "$ecd8" '\"'
        setEnvOneVal "$edVimrcF" "set" "shiftwidth" "$ecd9" '\"'
    fi

    return 0
}


tdir1=/root
shrc1=${tdir1}/.bashrc
vimrc1=${tdir1}/.vimrc

tdir2=/home/zfmd
shrc2=${tdir2}/.bashrc
vimrc2=${tdir2}/.vimrc

#root
writeSkyPP ${tdir1}
#zfmd
writeSkyPP ${tdir2}
chgUandGzfmd "zfmd" "manager" ${shrc2}
chgUandGzfmd "zfmd" "manager" ${vimrc2}

echo ""
echo "script [$0] execution completed !!"
echo ""

exit 0
