#bin/bash
#
################################################################################
#
#author:fushikai
#date  :2021-03-13
#desc  :根据已经生成的30个单风机1分钟数据文件生成(合成)单风机30分钟数据文件
#
#Precondition :
#       1. 在脚本的同级目录下有配置文件cfg/cfg.cfg，且配置文件已经按要求配置完成
#       2. 配置文件中配置的数据源文件已经已经在在
# usage like:  
#         ./$0
#
#
################################################################################
#

versionNo="software version number: v0.0.0.1"




thisShName="$0"
onlyShName=${thisShName##*/}
onlyShPre=${onlyShName%.*}




###############################################
#Load system environment variable configuration
###############################################
 [ -f /etc/profile ] && . /etc/profile >/dev/null 2>&1
 [ -f ~/.bash_profile ] && . ~/.bash_profile >/dev/null 2>&1
 [ -f ~/.profile ] && . ~/.profile >/dev/null 2>&1




##################################################
#Define the files and paths required by the script
##################################################
runDir="$(dirname ${thisShName})"

logDir="${runDir}/log"
logFile="${logDir}/${onlyShPre}_$(date +%Y%m%d).log"

diyFuncFile="${runDir}/myDiyShFunction.sh"
cfgFile="${runDir}/cfg/cfg.cfg"




function F_check()
{
    #load sh func
    if [ ! -f ${diyFuncFile} ];then
        echo "$(date +%Y/%m/%d-%H:%M:%S.%N):ERROR:file [${diyFuncFile}] not exits!"
        exit 1
    else
        . ${diyFuncFile}
    fi

    #Exit if a script is already running
    F_shHaveRunThenExit "${thisShName}"

    if [ ! -d "${logDir}" ];then
        mkdir -p "${logDir}"
    fi
    
    if [ ! -e "${cfgFile}" ];then
        F_outShDebugMsg "${logFile}" 1 1 "cfgfile [${cfgFile}] not exist!" 2
        exit 1
    fi

    return 0
}


main()
{
    F_check

    F_fuskytest

    return 0
}

main

exit 0



