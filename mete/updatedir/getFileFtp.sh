#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20170622
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    download files from ftp server
#
#invoke eg    :    
#   getFileFtp.sh "192.168.0.154" "Administrator" "qwer1234" "/tmp" "/home/zfmd/tmp" "Makefile"         
#
#version chg  :
#   20190115@improve the function
#
#############################################################################


. ~/.bash_profile >/dev/null 2>&1

runDir=$(dirname $0)

#load sh func
funcFlag=0
diyFuncFile=${runDir}/meteShFunc.sh
if [ ! -f ${diyFuncFile} ];then
    exit 1
else
    . ${diyFuncFile}
    funcFlag=1
fi

shNAME="getFileFtp"

#print log level:identifiable level 2 N-th power combination
#shDebugFlag=16
shDebugFlag=255

logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"
logFNDate="$(date '+%Y%m%d')"

#function outShDebugMsg() #out put $4 to $1; use like: outShDebugMsg $logfile $cfgdebug $valdebug $putcontent $clearflag

#if you need a personalized log directory,you need to configure the environment
#   varible "RMETEMAINP",for exampl RMETEMAINP=/home/zfmd
#if you do not configure the default directory as the log folder under the upper
#   directory
if [[ -z ${RMETEMAINP} ]]; then
    RMETEMAINP=$(dirname $(dirname $0))
    if [[ ! -d ${RMETEMAINP}/log ]]; then
        mkdir -p ${RMETEMAINP}/log
        if [[ $? -eq 0  ]]; then
            outmsg="${logTime} mkdir -p ${RMETEMAINP}/log"
            outShDebugMsg "${RMETEMAINP}/log/${shNAME}${logFNDate}.log" ${shDebugFlag} 0 "${outmsg}" 0
        fi
    fi
fi
export logFile="${RMETEMAINP}/log/${shNAME}${logFNDate}.log"


function writeLog()
{
    valDebug="$1"
    outmsg="$2"
    clearFlag=0
    [ $# -eq 3 ] && clearFlag=$3

    #echo -e "-------logFile=[${logFile}]"
    outShDebugMsg "${logFile}" "${shDebugFlag}" "${valDebug}" "${outmsg}" "${clearFlag}"
    ret=$?
    return ${ret}
}


writeLog 16 "\n${logTime} ${shNAME}.sh:$#:start -->"


outmsg="${logTime} --debug:input param nums:$#
                   --logFile=[${logFile}]"
writeLog 2 "${outmsg}"


if [[ $# -ne 6 && $# -ne 7 && $# -ne 8 && $# -ne 9 ]];then
    outmsg="${logTime} input error,please input like this:
                 ${shNAME}.sh <ftpIP> <ftpUser> <ftpPwd> <ftpRdir> <ftpLdir> <fileName>
                 or
                 ${shNAME}.sh <trsType> <trsMode> <ftpIP> <ftpUser> <ftpPwd> <ftpRdir> <ftpLdir> <fileName>"
    writeLog 0 "${outmsg}" 2
    exit 1
fi

#get temporary directory
tmpDir=${runDir}/tmpD
if [[ ! -d ${tmpDir} ]]; then
    mkdir -p ${tmpDir}
    writeLog 1 "${logTime} mkdir -p ${tmpDir}"
fi

if [ "${runDir}" == "." ];then
    prunDir=".."
else
    prunDir=$(dirname ${runDir})
fi

dRelaPath=filedo/down/back
dBackDir=${prunDir}/${dRelaPath}
if [ ! -d ${dBackDir} ];then
    if [ -f ${dBackDir} ];then
        mv ${dBackDir} ${dBackDir}.$(date '+%Y%m%d%H%M%S')
        writeLog 0 "${logTime} mv ${dBackDir} ${dBackDir}.$(date '+%Y%m%d%H%M%S')"
    fi
    mkdir -p ${dBackDir}
    writeLog 0 "${logTime} mkdir -p ${dBackDir}"
fi

opFlag=0 #0:download, 1:upload
trsType=0 #0:ascii ,1:binary
trsMode=0 #0:passive mode for data transfers, 1:active mode for data transfers
if [ $# -eq 8 -o $# -eq 9 ];then
    trsType=$1
    shift
    trsMode=$1
    shift
fi

tcheck=$(echo "${trsType}"|sed -n "/^[0-1]$/p"|wc -l)
[ ${tcheck} -eq 0 ] && trsType=0

tcheck=$(echo "${trsMode}"|sed -n "/^[0-1]$/p"|wc -l)
[ ${tcheck} -eq 0 ] && trsMode=0


ftpIP=$1
ftpUser=$2
ftpPwd=$3
ftpRdir=$4  #directory on the server
ftpLdirAims=$5  #ftp client local directory
fileName=$6 #file name to be processed on the ftp server

ftpLdir=${tmpDir}

#default port number
if [[ $# -eq 6 ]];then
    ftpCtrPNum=21
else
    ftpCtrPNum=$7
fi  

if [ ${opFlag} -eq 0 ];then
    opStr="downlaod"
    opCmd="mget"
else
    opStr="upload"
    opCmd="mput"
fi
if [ ${trsType} -eq 0 ];then
    typeStr="ascii"
else
    typeStr="binary"
fi
if [ ${trsMode} -eq 0 ];then
    modeStr="passive"
    modeOpt="-p"
else
    modeStr="active"
    modeOpt="-A"
fi

outmsg="${logTime} ${shNAME}.sh input param
     shDebugFlag=[${shDebugFlag}]
     opFlag=[${opFlag}],opStr=[${opStr}],opCmd=[${opCmd}]
     trsType=[${trsType}],typeStr=[${typeStr}]
     trsMode=[${trsMode}],modeStr=[${modeStr}],modeOpt=[${modeOpt}]
     logFile=[${logFile}]
     ---------ftp para begine--------
     ----ftpIP     =[${ftpIP}]
     ----ftpUser   =[${ftpUser}]
     ----ftpPwd    =[${ftpPwd}]
     ----ftpRdir   =[${ftpRdir}]
     ----ftpLdir   =[${ftpLdir}]
     ----ftpLdirAims=[${ftpLdirAims}]
     ----fileName  =[${fileName}]
     ----ftpCtrPNum=[${ftpCtrPNum}]
     ---------ftp para end----------
     "
writeLog 4 "${outmsg}"

ftpRet=$(getOrPutFtpFile "${opFlag}" "${trsType}" "${trsMode}" "${ftpIP}" "${ftpUser}" "${ftpPwd}" "${ftpRdir}" "${ftpLdir}" "${fileName}" "${ftpCtrPNum}")
retstat=$?

logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"
writeLog 1 "\n${logTime} retstat=[${retstat}],ftpRet=[${ftpRet}]\n"

declare -i mvFlag=0
declare -i rmFlag=0

#determine if the file is downloaded to the corresponding directory
numDFiles=$(ls -1 ${ftpLdir}/${fileName} 2>/dev/null|wc -l)
if [[ ${numDFiles} -gt 0 ]];then

    #delete files on the ftp server
    ftpRetD=$(echo "user ${ftpUser} ${ftpPwd}
      cd ${ftpRdir}
      lcd ${ftpLdir}
      prompt
      mdelete ${fileName}
      bye"|ftp -n -v ${modeOpt} ${ftpIP} ${ftpCtrPNum} 2>&1|while read tmpRead
      do      
        echo ${tmpRead}     
      done);
    writeLog 1 "${logTime} numDFiles=[${numDFiles}],ftpRetD=[${ftpRetD}]"
    
    #remove the carriage return contained in the file contents
    ls -1 ${ftpLdir}/${fileName}|while read trName
    do
        writeLog 8 "${logTime} ++++++${trName} "
        tr -d '\r' < "${trName}" >"${trName}.rtmp" && mv -f "${trName}.rtmp" "${trName}"
    done
    
     #move the downloaded file to the target directory
     declare -i opNum=0
     declare -i maxOpNum=100
     #ls -1 ${ftpLdir}/${fileName}|while read rfName
     for rfName in $(ls -1 ${ftpLdir}/${fileName})
     do
         mvFlag=0
         rmFlag=0
         opNum=0

         #  Multi-date source only needs to use a successfully downloaded data file

         #  Determine if the file exists
         trfName=$(getFnameOnPath ${rfName})
         statf=$?
         if [ ${funcFlag} -eq 1 ] && [ ${statf} -eq 0 ];then
             tmpRet=$(deterSameFile ${shDebugFlag} ${dBackDir} ${trfName})
            stat=$?
            if [ ${stat} -eq 2 ];then
                #if the file not exist,copy the file to the comparison directory first
                cp -f ${rfName} ${dBackDir}
                mvFlag=1
            elif [ ${stat} -eq 0 ];then
                #if the file already exists,delete the newly downloaded file
                rmFlag=1
            fi
            writeLog 8 "\n${tmpRet}\n"
         else
             mvFlag=1
         fi

         outmsg="${logTime} ++++fusktest++++mvFlag=[${mvFlag}],rmFlag=[${rmFlag}],trfName=[${trfName}],statf=[${statf}],stat=[${stat}] "
         writeLog 0 "\n${outmsg}\n"

         #delete file
         if [ ${rmFlag} -eq 1 ];then
             opNum=0
             rm -rf ${rfName}
             while [[ $? -ne 0 ]]
             do
                 let opNum++
                 if [ ${opNum} -gt ${maxOpNum} ];then
                    writeLog 0 "$(date '+%Y/%m/%d %H:%M:%S.%N') rm ${rfName} error"
                    break
                 fi
                 sleep 1
                 rm -rf ${rfName}
             done
            writeLog 0 "$(date '+%Y/%m/%d %H:%M:%S.%N') The file[${trfName}] downloaded from the [${ftpIP}:${ftpCtrPNum}${ftpRdir}]service already exists and will be deleted "
        fi

        #move files to the destination folder
         if [ ${mvFlag} -eq 1 ];then
             opNum=0
             mv ${rfName} ${ftpLdirAims}
             while [[ $? -ne 0 ]]
             do
                 let opNum++
                 if [ ${opNum} -gt ${maxOpNum} ];then
                    writeLog 0 "$(date '+%Y/%m/%d %H:%M:%S.%N') mv ${rfName} ${ftpLdirAims} error"
                    break
                 fi
                 sleep 1
                 mv ${rfName} ${ftpLdirAims}
             done
        fi

     done

#     if [ ${mvFlag] -eq 1 ];then
#         mv ${ftpLdir}/${fileName} ${ftpLdirAims}
#         while [[ $? -ne 0 ]]
#         do
#             let opNum++
#             if [ ${opNum} -gt ${maxOpNum} ];then
#                writeLog 0 "$(date '+%Y/%m/%d %H:%M:%S.%N') mv ${ftpLdir}/${fileName} ${ftpLdirAims} error"
#                break
#             fi
#             sleep 1
#             mv ${ftpLdir}/${fileName} ${ftpLdirAims}
#         done
#     fi
    
    #delte expired files
    rmExName="busilist_*"
    rmExDay=5
    if [ ${funcFlag} -eq 1 ];then
        rmExpiredFile "${dBackDir}" "${rmExDay}" "${rmExName}" >>${logFile} 2>&1
    fi
    
    writeLog 16 "$(date '+%Y/%m/%d %H:%M:%S.%N') rmFlag=[${rmFlag}], ${shNAME}.sh:$#:end \n"
    if [ ${rmFlag} -eq 1 ];then
        exit 3
    else
        exit 0
    fi
else
    writeLog 16 "$(date '+%Y/%m/%d %H:%M:%S.%N') ${shNAME}.sh:$#:unsuccessfull \n"
    exit 2
fi


exit 0

