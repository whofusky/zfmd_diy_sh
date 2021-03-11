#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20181113
#linux_version:    Red Hat Enterprise Linux Server release 6.7 
#dsc          :   
#    Some functions used in the Zone III weather download script
#
#############################################################################

function F_delDosCRCharinFile() #delete DOS Carriage return character in file
{
    if [ $# -lt 1 ];then
        return 1
    fi

    local tfile="$1"

	local tnum=0
	tnum=$(ls -1 ${tfile} 2>/dev/null|wc -l)
    if [ ${tnum} -lt 1 ];then
        return 2
    fi

    sed -i 's///g' ${tfile}

    return 0
}

function F_convertVLineToSpace() #Convert vertical lines to spaces
{

    if [ $# -lt 1 ];then
        echo ""
        return 0
    fi

    echo $(echo "$1"|tr -d "[\040\t\r\n]"|tr -s "|" "\040")
    return 0
}



#Print function input parameter
#  usage: prtFuncInput [function_name] $@
function prtFuncInput()
{
    if [ $# -lt 2 ];then
        return 0
    fi
    
    local fName=$1
    shift
    echo "The input of function [ ${fName}] is as follows:"
    local i=1
    local tmp
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

    return 0
}


function getFnameOnPath() #get the file name in the path string
{
    if [ $# -ne 1 ];then
        echo "  Error: function getFnameOnPath input parameters not eq 1!"
        return 1
    fi

    local allName="$1"
    if [ -z "${allName}" ];then
        echo "  Error: function getFnameOnPath input parameters is null!"
        return 2;
    fi

    local slashNum
    slashNum=$(echo ${allName}|grep "/"|wc -l)
    if [ ${slashNum} -eq 0 ];then
        echo ${allName}
        return 0 
    fi

    local fName
    fName=$(echo ${allName}|awk -F'/' '{print $NF}')
    echo ${fName}

    return 0
}


function getPathOnFname() #get the path value in the path string(the path does not have / at the end)
{

    if [ $# -ne 1 ];then
        echo "  Error: function getPathOnFname input parameters not eq 1!"
        return 1
    fi

    if [  -z "$1" ];then
        echo "  Error: function getPathOnFname input parameters is null!"
        return 2
    fi
    
    local dirStr
    dirStr=$(echo "$1"|awk -F'/' '{for(i=1;i<NF;i++){printf "%s/",$i}}'|sed 's/\/$//g')
    if [ -z "${dirStr}" ];then
        dirStr="."
    fi

    echo "${dirStr}"
    return 0
}


function outShDebugMsg() #out put $4 to $1; use like: outShDebugMsg $logfile $cfgdebug $valdebug $putcontent $clearflag
{
    if [ $# -ne 4 -a $# -ne 5 ];then
        echo "  Error: function outShDebugMsg input parameters not eq 4 or 5 !"
        return 1
    fi

    local inum=$#
    local logFile="$1"
    local cfgDebugFlag="$2"
    local valDebugFlag="$3"
    local puttxt="$4"
    
    local tcheck
    tcheck=$(echo "${cfgDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && cfgDebugFlag=0
    tcheck=$(echo "${valDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && valDebugFlag=0

    if [ $((${cfgDebugFlag}&${valDebugFlag})) -ne ${valDebugFlag} ];then
        return 0
    fi
    
    #output content to standard output device if the log file name is empty
    if [ -z "${logFile}" ];then
        #echo -e "${puttxt}"
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}"
        return 0
    fi

    local tmpdir
    tmpdir=$(getPathOnFname "${logFile}")
    local ret=$?
    [ ${ret} -ne 0 ] && echo "${tmpdir}" && return ${ret}

    if [ ! -d "${tmpdir}" ];then
        echo "  Error: dirname [${tmpdir}] not exist!"
        return 2
    fi

    local clearFlag=0
    [ ${inum} -eq 5 ] && clearFlag=$5
    tcheck=$(echo "${clearFlag}"|sed -n "/^[0-9]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && clearFlag=0
    [ ${clearFlag} -eq 1 ] && >"${logFile}"
    
    #if [ ${clearFlag} -eq 2 ];then
    #    echo -e "${puttxt}"|tee -a "${logFile}"
    #else
    #    echo -e "${puttxt}">>"${logFile}"
    #fi
    
    if [ ${clearFlag} -eq 2 ];then
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}"|tee -a "${logFile}"
    else
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}">>"${logFile}"
    fi
    
    return 0
}


function F_outShDebugMsg() #out put $4 to $1; use like: F_outShDebugMsg $logfile $cfgdebug $valdebug $putcontent $clearflag
{
    if [ $# -ne 4 -a $# -ne 5 ];then
        echo "  Error: function F_outShDebugMsg input parameters not eq 4 or 5 !"
        return 1
    fi

    local inum=$#
    local logFile="$1"
    local cfgDebugFlag="$2"
    local valDebugFlag="$3"
    local puttxt="$4"
    
    local tcheck=$(echo "${cfgDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && cfgDebugFlag=0
    tcheck=$(echo "${valDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && valDebugFlag=0

    if [ $((${cfgDebugFlag}&${valDebugFlag})) -ne ${valDebugFlag} ];then
        return 0
    fi
    
    #output content to standard output device if the log file name is empty
    if [ -z "${logFile}" ];then
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}"
        return 0
    fi

    local tmpdir=$(getPathOnFname "${logFile}")
    local ret=$?
    [ ${ret} -ne 0 ] && echo "${tmpdir}" && return ${ret}

    if [ ! -d "${tmpdir}" ];then
        echo "  Error: dirname [${tmpdir}] not exist!"
        return 2
    fi

    local clearFlag=0
    [ ${inum} -eq 5 ] && clearFlag=$5
    tcheck=$(echo "${clearFlag}"|sed -n "/^[0-9]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && clearFlag=0
    [ ${clearFlag} -eq 1 ] && >"${logFile}"
    
    if [ ${clearFlag} -eq 2 ];then
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}"|tee -a "${logFile}"
    else
        echo -e "$(date +%y-%m-%d_%H:%M:%S.%N) ${puttxt}">>"${logFile}"
    fi
    
    return 0
}

#delete expired(more than x days unmodify)files in the directory
#  Entering:
#     (1) <directory> <number_of_days> <file_name or file_name_with_wildcard>
#     (2) <directory> <number_of_days> 
function rmExpiredFile()
{
    if [ $# -ne 2 ] && [ $# -ne 3 ];then
        return 1
    fi

    local tpath=$1
    if [ ! -d ${tpath} ];then
        return 2
    fi

    local tdays=$2
    local tname
    if [ $# -eq 3 ];then
        tname=$3
    else
        tname="*"
    fi

    #echo "++++++[${tpath}/${tname}]+++"
    local tnaa
    local tdnum
    local tdifftd
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



#Determine if a file exists in a directory
#    usage:  deterSameFile [log_level] [file_directory] [file_name]
#return status:
#     100 : function parameter errro
#     0   : file exists
#     1   : directory does not exist
#     2   : file does not exist
function deterSameFile()
{
    local myFuncName="deterSameFile"
    
    if [ $# -lt 3 ];then
        outShDebugMsg "" 0 0 "\nCall shell function [ ${myFuncName} ] parameter number error"
        return 100
    fi

    #print log level:identifiable level 2 N-th power combination
    local shDebugFlag=$1

    local tDir=$2
    local tFname=$3

    local ret=0
    
    outShDebugMsg "" "${shDebugFlag}" 1 "\n $(date '+%Y/%m/%d %H:%M:%S.%N'):Enter the shell function [${myFuncName}]"
    
    if [[ $((${shDebugFlag}&2)) -eq 2 ]]; then
        prtFuncInput ${myFuncName} $@
    fi
    
    if [ ! -d ${tDir} ];then
        ret=1
    elif [ ! -f ${tDir}/${tFname} ];then
        ret=2
    fi    

    outShDebugMsg "" "${shDebugFlag}" 1 "$(date '+%Y/%m/%d %H:%M:%S.%N'):shell function [${myFuncName}] excution ends,ret=[${ret}]\n"

    return ${ret}
    
}


function wegrepFileDir()
{
    if [ $# -ne 2 ];then
        return 1
    fi

    local debugflag=0

    local tpath="$1"
    local sfname="$2"
    
    [ ! -d "${tpath}" ] && return 2
    [ -z "${sfname}" ] && return 3

    #check whether there are ${sfname} related files in the ${tpath} directory
    local tmpRead
    local fileRet
    fileRet=$(cd ${tpath} 2>&1 && ls -1 2>&1|while read tmpRead
    do
    echo ${tmpRead}
    done);

    outShDebugMsg "" ${debugflag} 4 "\n${fileRet}\n"

    local TTNUM
    TTNUM=$(echo ${fileRet}|grep -Ew "${sfname}"|wc -l)
    if [[ "${TTNUM}" -eq 0 ]];then
        #the file  [${fileName}] is not exists
        echo "${fileRet}"
        return 4
    fi

    return 0
}


function getFtpSerStatu() #get ftp server's status
{
    if [ $# -ne 10 ];then
        return 1
    fi

    local opFlag=$1 #0:download; 1:upload
    local tcheck=$(echo "${opFlag}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && opFlag=0
    shift

    local trsType=$1 #0:ascii ,1:binary
    tcheck=$(echo "${trsType}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsType=0
    shift

    local trsMode=$1 #0:passive mode for data transfers, 1:active mode for data transfers
    tcheck=$(echo "${trsMode}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsMode=0
    shift

    
    local debugflag=1

    local ftpIP=$1      #ftp ip address
    local ftpUser=$2    #ftp username
    local ftpPwd=$3     #ftp password
    local ftpRdir="$4"  #ftp server path
    local ftpLdir="$5"  #ftp client local path
    local fileName="$6" #file name on the service to be processed
    local ftpCtrPNum=$7 #the port number

    #if the file name ${fileName} is mutiple file names(separated by spaces or table keys),replaced with | ,and remove the head and tail | (if any)
    #if the file name R{fileName} contains . replace it whith \. ther is a wildcard * replaced by .{0,} for the subsequent grep -E syntax lookup
    local fileNameTmp
    if [ -n "${fileName}" ];then
       fileNameTmp=$(echo $fileName|sed 's/[ ,\t]\{1,\}/\|/g'|sed 's/^|//'|sed 's/|$//'|sed 's/\./\\./g'|sed 's/\*\{1,\}/.\{0,\}/g')
    fi

    local logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

    local opStr
    local opCmd
    if [ ${opFlag} -eq 0 ];then
        opStr="downlaod"
        opCmd="mget"
    else
        opStr="upload"
        opCmd="mput"
    fi

    local typeStr
    if [ ${trsType} -eq 0 ];then
        typeStr="ascii"
    else
        typeStr="binary"
    fi

    local modeStr
    local modeOpt
    if [ ${trsMode} -eq 0 ];then
        modeStr="passive"
        modeOpt="-p"
    else
        modeStr="active"
        modeOpt="-A"
    fi

    local outmsg="function getFtpSerStatu input param ${logTime} 
         debugflag=[${debugflag}]
         opFlag=[${opFlag}],opStr=[${opStr}],opCmd=[${opCmd}]
         trsType=[${trsType}],typeStr=[${typeStr}]
         trsMode=[${trsMode}],modeStr=[${modeStr}],modeOpt=[${modeOpt}]
         fileNameTmp=[$fileNameTmp]--------
         ---------ftp para begine--------
         ----ftpIP     =[${ftpIP}]
         ----ftpUser   =[${ftpUser}]
         ----ftpPwd    =[${ftpPwd}]
         ----ftpRdir   =[${ftpRdir}]
         ----ftpLdir   =[${ftpLdir}]
         ----fileName  =[${fileName}]
         ----ftpCtrPNum=[${ftpCtrPNum}]
         ---------ftp para end----------
         "
    outShDebugMsg "" ${debugflag} 1 "${outmsg}"
    
    if [[ ! -d "${ftpLdir}" ]];then
        #local path error
        echo "local path [${ftpLdir}] error"
        return 10
    fi

    nc -z ${ftpIP} ${ftpCtrPNum} >/dev/null 2>&1
    local ret=$?
    if [ ${ret} -ne 0 ];then
        #connect ftp server error
        echo "connect ftp server[${ftpIP} ${ftpCtrPNum}] error"
        return 11
    fi

    if [ -z "${ftpRdir}" ];then
        ftpRdir="./"
    fi
    if [ -z "${ftpLdir}" ];then
        ftpLdir="./"
    fi


    local fileRet
    local retStat
    if [ -n "${fileName}" -a ${opFlag} -eq 1 ];then 
        #upload

        #view all files in the directory to be uplaod to determine where the uplaod file exists
        fileRet=$(wegrepFileDir "${ftpLdir}" "${fileNameTmp}")
        retStat=$?
        outShDebugMsg "" ${debugflag} 4 "\n${fileRet}\n"
        if [ "${retStat}" -ne 0 ];then
            #the file  [${fileName}] is not exists
            echo "${fileRet}"
            return 14
        fi
    fi

    local ftpRet
    if [ -n "${fileName}" -a ${opFlag} -eq 0 ];then
        ftpRet=$(echo "open ${ftpIP} ${ftpCtrPNum}
              user ${ftpUser} ${ftpPwd}
              ${typeStr}
              cd ${ftpRdir}
              lcd ${ftpLdir}
              ls
              bye"|ftp -n -v ${modeOpt} 2>&1|while read tmpRead
        do      
        echo ${tmpRead}     
        done);
    else
        ftpRet=$(echo "open ${ftpIP} ${ftpCtrPNum}
              user ${ftpUser} ${ftpPwd}
              ${typeStr}
              cd ${ftpRdir}
              lcd ${ftpLdir}
              bye"|ftp -n -v ${modeOpt} 2>&1|while read tmpRead
        do      
        echo ${tmpRead}     
        done);
    fi

    logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

    #service ready
    local v220=$(echo ${ftpRet}|grep -E "\s+\<220\>\s+"|wc -l)
    #Password required
    local v331=$(echo ${ftpRet}|grep -E "\s+\<331\>\s+"|wc -l)
    #not logging in to the network
    local v530=$(echo ${ftpRet}|grep -E "\s+\<530\>\s+"|wc -l)
    #login to the internet
    local v230=$(echo ${ftpRet}|grep -E "\s+\<230\>\s+"|wc -l)
    #The system cannot find the file specified.
    local v550=$(echo ${ftpRet}|grep -E "\s+\<550\>\s+"|wc -l)

    local TTNUM
    #TTNUM=$(echo ${ftpRet}|grep -E "User[ ]+cannot[ ]+log"|wc -l)
    #if [[ "${TTNUM}" -gt 0 ]];then
    if [[ "${v331}" -gt 0 && "${v530}" -gt 0 ]];then
        #wrong user name or password
        echo "${ftpRet}"
        return 12
    fi

    #TTNUM=$(echo ${ftpRet}|grep -E "cannot[ ]+find[ ]+the[ ]+file"|wc -l)
    #if [[ "${TTNUM}" -gt 0 ]];then
    if [[ "${v230}" -gt 0 && "${v550}" -gt 0 ]];then
        #The system cannot find the file specified.
        echo "${ftpRet}"
        return 13
    fi

    if [ -n "${fileName}" -a ${opFlag} -eq 0 ];then
        #download

        TTNUM=$(echo ${ftpRet}|grep -Ew "${fileNameTmp}"|wc -l)
        if [[ "${TTNUM}" -eq 0 ]];then
            #the file  [${fileName}] is not exists
            echo "${ftpRet}"
            return 14
        fi
    fi

    echo "${ftpRet}"
    return 0
}

#getFtpSerStatu "0" "192.168.0.155" "Administrator" "qwer1234" "/gaolongshan" "./" "busilist_20190114_0.xml" "21"


function getOrPutFtpFile() #download or upload files from ftp server
{
    if [ $# -ne 10 ];then
        return 1
    fi

    local opFlag=$1 #0:download; 1:upload
    local tcheck=$(echo "${opFlag}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && opFlag=0
    shift

    local trsType=$1 #0:ascii ,1:binary
    tcheck=$(echo "${trsType}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsType=0
    shift

    local trsMode=$1 #0:passive mode for data transfers, 1:active mode for data transfers
    tcheck=$(echo "${trsMode}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsMode=0
    shift

    
    local debugflag=1

    local ftpIP=$1      #ftp ip address
    local ftpUser=$2    #ftp username
    local ftpPwd=$3     #ftp password
    local ftpRdir="$4"  #ftp server path
    local ftpLdir="$5"  #ftp client local path
    local fileName="$6" #file name on the service to be processed
    local ftpCtrPNum=$7 #the port number

    #if the file name ${fileName} is mutiple file names(separated by spaces or table keys),replaced with | ,and remove the head and tail | (if any)
    #if the file name R{fileName} contains . replace it whith \. ther is a wildcard * replaced by .{0,} for the subsequent grep -E syntax lookup
    local fileNameTmp
    if [ -n "${fileName}" ];then
       fileNameTmp=$(echo $fileName|sed 's/[ ,\t]\{1,\}/\|/g'|sed 's/^|//'|sed 's/|$//'|sed 's/\./\\./g'|sed 's/\*\{1,\}/.\{0,\}/g')
    fi

    local logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

    local opStr
    local opCmd
    if [ ${opFlag} -eq 0 ];then
        opStr="downlaod"
        opCmd="mget"
    else
        opStr="upload"
        opCmd="mput"
    fi

    local typeStr
    if [ ${trsType} -eq 0 ];then
        typeStr="ascii"
    else
        typeStr="binary"
    fi

    local modeStr
    local modeOpt
    if [ ${trsMode} -eq 0 ];then
        modeStr="passive"
        modeOpt="-p"
    else
        modeStr="active"
        modeOpt="-A"
    fi
    local outmsg="function ${FUNCNAME} input param ${logTime} 
         debugflag=[${debugflag}]
         opFlag=[${opFlag}],opStr=[${opStr}],opCmd=[${opCmd}]
         trsType=[${trsType}],typeStr=[${typeStr}]
         trsMode=[${trsMode}],modeStr=[${modeStr}],modeOpt=[${modeOpt}]
         fileNameTmp=[$fileNameTmp]--------
         ---------ftp para begine--------
         ----ftpIP     =[${ftpIP}]
         ----ftpUser   =[${ftpUser}]
         ----ftpPwd    =[${ftpPwd}]
         ----ftpRdir   =[${ftpRdir}]
         ----ftpLdir   =[${ftpLdir}]
         ----fileName  =[${fileName}]
         ----ftpCtrPNum=[${ftpCtrPNum}]
         ---------ftp para end----------
         "
    outShDebugMsg "" ${debugflag} 1 "${outmsg}"
    
    if [[ -z "${fileName}" ]];then
        #file name is null
        echo "file name is null"
        return 9
    fi

    if [[ ! -d "${ftpLdir}" ]];then
        #local path error
        echo "local path [${ftpLdir}] error"
        return 10
    fi

    nc -z ${ftpIP} ${ftpCtrPNum} >/dev/null 2>&1
    local ret=$?
    if [ ${ret} -ne 0 ];then
        #connect ftp server error
        echo "connect ftp server[${ftpIP} ${ftpCtrPNum}] error"
        return 11
    fi

    if [ -z "${ftpRdir}" ];then
        ftpRdir="./"
    fi
    if [ -z "${ftpLdir}" ];then
        ftpLdir="./"
    fi

    local fileRet
    local retStat
    if [ -n "${fileName}" -a ${opFlag} -eq 1 ];then 
        #upload

        #view all files in the directory to be uplaod to determine where the uplaod file exists
        fileRet=$(wegrepFileDir "${ftpLdir}" "${fileNameTmp}")
        retStat=$?
        outShDebugMsg "" ${debugflag} 4 "\n${fileRet}\n"
        if [ "${retStat}" -ne 0 ];then
            #the file  [${fileName}] is not exists
            echo "${fileRet}"
            return 14
        fi
    fi

    #download or upload
    local ftpRet
    ftpRet=$(echo "user ${ftpUser} ${ftpPwd}
          ${typeStr}
          cd ${ftpRdir}
          lcd ${ftpLdir}
          prompt
          ${opCmd} ${fileName}
          bye"|ftp -n -v ${modeOpt} ${ftpIP} ${ftpCtrPNum} 2>&1|while read tmpRead
    do      
    echo ${tmpRead}     
    done);


    logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

    #service ready
    local v220=$(echo ${ftpRet}|grep -E "\s+\<220\>\s+"|wc -l)
    #User logged in
    local v230=$(echo ${ftpRet}|grep -E "\s+\<230\>\s+"|wc -l)
    #Transfer complete
    local v226=$(echo ${ftpRet}|grep -E "\s+\<226\>\s+"|wc -l)
    #Password required
    local v331=$(echo ${ftpRet}|grep -E "\s+\<331\>\s+"|wc -l)
    #not logging in to the network
    local v530=$(echo ${ftpRet}|grep -E "\s+\<530\>\s+"|wc -l)
    #login to the internet
    local v230=$(echo ${ftpRet}|grep -E "\s+\<230\>\s+"|wc -l)
    #The system cannot find the file specified.
    local v550=$(echo ${ftpRet}|grep -E "\s+\<550\>\s+"|wc -l)

    #TTNUM=$(echo ${ftpRet}|grep -E "User[ ]+cannot[ ]+log"|wc -l)
    #if [[ "${TTNUM}" -gt 0 ]];then
    if [[ "${v331}" -gt 0 && "${v530}" -gt 0 && "${v230}" -eq 0 ]];then
        #wrong user name or password
        echo "${ftpRet}"
        return 12
    fi

    #TTNUM=$(echo ${ftpRet}|grep -E "cannot[ ]+find[ ]+the[ ]+file"|wc -l)
    #if [[ "${TTNUM}" -gt 0 ]];then
    if [[ "${v230}" -gt 0 && "${v550}" -gt 0 ]];then
        #The system cannot find the file specified.
        echo "${ftpRet}"
        return 13
    fi
    if [ "${v226}" -eq 0 -a ${opFlag} -eq 0 ];then
        #the file  [${fileName}] is not exists
        echo "${ftpRet}"
        return 14
    elif [ -n "${fileName}" -a ${opFlag} -eq 0 ];then
        #download
        fileRet=$(wegrepFileDir "${ftpLdir}" "${fileNameTmp}")
        retStat=$?
        outShDebugMsg "" ${debugflag} 4 "\n${fileRet}\n"
        if [ "${retStat}" -ne 0 ];then
            #the downloaded file  [${fileName}] is not exists
            echo "${fileRet}"
            return 15
        fi
    fi


    echo "${ftpRet}"
    return 0
}


function delFtpSerFile() #delete ftp server's file
{
    if [ $# -ne 10 ];then
        return 1
    fi

    local opFlag=$1 #not used
    local tcheck=$(echo "${opFlag}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && opFlag=0
    shift

    local trsType=$1 #0:ascii ,1:binary
    tcheck=$(echo "${trsType}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsType=0
    shift

    local trsMode=$1 #0:passive mode for data transfers, 1:active mode for data transfers
    tcheck=$(echo "${trsMode}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsMode=0
    shift

    
    local debugflag=1

    local ftpIP=$1      #ftp ip address
    local ftpUser=$2    #ftp username
    local ftpPwd=$3     #ftp password
    local ftpRdir="$4"  #ftp server path
    local ftpLdir="$5"  #ftp client local path
    local fileName="$6" #file name on the service to be processed
    local ftpCtrPNum=$7 #the port number


    local logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

    local opStr="mdelete"
    local opCmd="mdelete"

    local typeStr
    if [ ${trsType} -eq 0 ];then
        typeStr="ascii"
    else
        typeStr="binary"
    fi

    local modeStr
    local modeOpt
    if [ ${trsMode} -eq 0 ];then
        modeStr="passive"
        modeOpt="-p"
    else
        modeStr="active"
        modeOpt="-A"
    fi
    local outmsg="function ${FUNCNAME} input param ${logTime} 
         debugflag=[${debugflag}]
         opFlag=[${opFlag}],opStr=[${opStr}],opCmd=[${opCmd}]
         trsType=[${trsType}],typeStr=[${typeStr}]
         trsMode=[${trsMode}],modeStr=[${modeStr}],modeOpt=[${modeOpt}]
         fileNameTmp=[$fileNameTmp]--------
         ---------ftp para begine--------
         ----ftpIP     =[${ftpIP}]
         ----ftpUser   =[${ftpUser}]
         ----ftpPwd    =[${ftpPwd}]
         ----ftpRdir   =[${ftpRdir}]
         ----ftpLdir   =[${ftpLdir}]
         ----fileName  =[${fileName}]
         ----ftpCtrPNum=[${ftpCtrPNum}]
         ---------ftp para end----------
         "
    #outShDebugMsg "" ${debugflag} 1 "${outmsg}"
    
    if [[ -z "${fileName}" ]];then
        #file name is null
        echo "file name is null"
        return 9
    fi


    nc -z ${ftpIP} ${ftpCtrPNum} >/dev/null 2>&1
    local ret=$?
    if [ ${ret} -ne 0 ];then
        #connect ftp server error
        echo "connect ftp server[${ftpIP} ${ftpCtrPNum}] error"
        return 11
    fi

    if [ -z "${ftpRdir}" ];then
        ftpRdir="./"
    fi

    local fileRet
    local retStat

    #delete file
    local ftpRet
    ftpRet=$(echo "user ${ftpUser} ${ftpPwd}
          ${typeStr}
          cd ${ftpRdir}
          prompt
          ${opCmd} ${fileName}
          bye"|ftp -n -v ${modeOpt} ${ftpIP} ${ftpCtrPNum} 2>&1|while read tmpRead
    do      
    echo ${tmpRead}     
    done);


    logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

    #service ready
    local v220=$(echo ${ftpRet}|grep -E "\s+\<220\>\s+"|wc -l)
    #User logged in
    local v230=$(echo ${ftpRet}|grep -E "\s+\<230\>\s+"|wc -l)
    #Transfer complete
    local v226=$(echo ${ftpRet}|grep -E "\s+\<226\>\s+"|wc -l)
    #Password required
    local v331=$(echo ${ftpRet}|grep -E "\s+\<331\>\s+"|wc -l)
    #not logging in to the network
    local v530=$(echo ${ftpRet}|grep -E "\s+\<530\>\s+"|wc -l)
    #login to the internet
    local v230=$(echo ${ftpRet}|grep -E "\s+\<230\>\s+"|wc -l)
    #The system cannot find the file specified.
    local v550=$(echo ${ftpRet}|grep -E "\s+\<550\>\s+"|wc -l)

    #TTNUM=$(echo ${ftpRet}|grep -E "User[ ]+cannot[ ]+log"|wc -l)
    #if [[ "${TTNUM}" -gt 0 ]];then
    if [[ "${v331}" -gt 0 && "${v530}" -gt 0 && "${v230}" -eq 0 ]];then
        #wrong user name or password
        echo "${ftpRet}"
        return 12
    fi

    #TTNUM=$(echo ${ftpRet}|grep -E "cannot[ ]+find[ ]+the[ ]+file"|wc -l)
    #if [[ "${TTNUM}" -gt 0 ]];then
    if [[ "${v230}" -gt 0 && "${v550}" -gt 0 ]];then
        #The system cannot find the file specified.
        echo "${ftpRet}"
        return 13
    fi


    echo "${ftpRet}"
    return 0
}


function getSftpSerStatu() #get sftp server's status
{
    if [ $# -ne 10 ];then
        return 1
    fi

    local opFlag=$1 #0:download; 1:upload
    local tcheck=$(echo "${opFlag}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && opFlag=0
    shift

    local trsType=$1 #0:ascii ,1:binary
    tcheck=$(echo "${trsType}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsType=0
    shift

    local trsMode=$1 #0:passive mode for data transfers, 1:active mode for data transfers
    tcheck=$(echo "${trsMode}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsMode=0
    shift

    
    local debugflag=1

    local sftpIP=$1      #sftp ip address
    local sftpUser=$2    #sftp username
    local sftpPwd=$3     #sftp password
    local sftpRdir="$4"  #sftp server path
    local sftpLdir="$5"  #sftp client local path
    local fileName="$6" #file name on the service to be processed
    local sftpCtrPNum=$7 #the port number

    #if the file name ${fileName} is mutiple file names(separated by spaces or table keys),replaced with | ,and remove the head and tail | (if any)
    #if the file name R{fileName} contains . replace it whith \. ther is a wildcard * replaced by .{0,} for the subsequent grep -E syntax lookup
    local fileNameTmp
    if [ -n "${fileName}" ];then
       fileNameTmp=$(echo $fileName|sed 's/[ ,\t]\{1,\}/\|/g'|sed 's/^|//'|sed 's/|$//'|sed 's/\./\\./g'|sed 's/\*\{1,\}/.\{0,\}/g')
    fi

    local logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

    local opStr
    local opCmd
    #0:download; 1:upload
    if [ ${opFlag} -eq 0 ];then
        opStr="downlaod"
        opCmd="mget"
    else
        opStr="upload"
        opCmd="mput"
    fi

    local typeStr
    if [ ${trsType} -eq 0 ];then
        typeStr="ascii"
    else
        typeStr="binary"
    fi

    local modeStr
    local modeOpt
    if [ ${trsMode} -eq 0 ];then
        modeStr="passive"
        modeOpt="-p"
    else
        modeStr="active"
        modeOpt="-A"
    fi

    local outmsg="function getSftpSerStatu input param ${logTime} 
         debugflag=[${debugflag}]
         opFlag=[${opFlag}],opStr=[${opStr}],opCmd=[${opCmd}]
         trsType=[${trsType}],typeStr=[${typeStr}]
         trsMode=[${trsMode}],modeStr=[${modeStr}],modeOpt=[${modeOpt}]
         fileNameTmp=[$fileNameTmp]--------
         ---------sftp para begine--------
         ----sftpIP     =[${sftpIP}]
         ----sftpUser   =[${sftpUser}]
         ----sftpPwd    =[${sftpPwd}]
         ----sftpRdir   =[${sftpRdir}]
         ----sftpLdir   =[${sftpLdir}]
         ----fileName  =[${fileName}]
         ----sftpCtrPNum=[${sftpCtrPNum}]
         ---------sftp para end----------
         "
    outShDebugMsg "" ${debugflag} 1 "${outmsg}"
    
    if [[ ! -d "${sftpLdir}" ]];then
        #local path error
        echo "local path [${sftpLdir}] error"
        return 10
    fi

    nc -z ${sftpIP} ${sftpCtrPNum} >/dev/null 2>&1
    local ret=$?
    if [ ${ret} -ne 0 ];then
        #connect sftp server error
        echo "connect sftp server[${sftpIP} ${sftpCtrPNum}] error"
        return 11
    fi

    if [ -z "${sftpRdir}" ];then
        sftpRdir="./"
    fi
    if [ -z "${sftpLdir}" ];then
        sftpLdir="./"
    fi

    local fileRet
    local retStat
    #opFlag 0:download; 1:upload
    if [ -n "${fileName}" -a ${opFlag} -eq 1 ];then 
        #upload

        #view all files in the directory to be uplaod to determine where the uplaod file exists
        fileRet=$(wegrepFileDir "${sftpLdir}" "${fileNameTmp}")
        retStat=$?
        outShDebugMsg "" ${debugflag} 4 "\n${fileRet}\n"
        if [ "${retStat}" -ne 0 ];then
            #the file  [${fileName}] is not exists
            echo "${fileRet}"
            return 14
        fi
    fi

    local sftpRet=0
    local sftpSta=0
    #opFlag 0:download; 1:upload
    if [ -n "${fileName}" -a ${opFlag} -eq 0 ];then
        sftpRet=$(echo "debug 3
            set net:timeout 3;set net:max-retries 1;set net:reconnect-interval-base 1;
            cd ./ || exit 1
            cd ${sftpRdir} || exit 2
            lcd ${sftpLdir} || exit 10
            cls -1 *
            bye"|lftp -u ${sftpUser},${sftpPwd} sftp://${sftpIP}:${sftpCtrPNum} 2>&1
        );
        sftpSta=$?
    else
        sftpRet=$(echo "debug 3
            set net:timeout 3;set net:max-retries 1;set net:reconnect-interval-base 1;
            cd ./ || exit 1
            cd ${sftpRdir} || exit 2
            lcd ${sftpLdir} || exit 10
            bye"|lftp -u ${sftpUser},${sftpPwd} sftp://${sftpIP}:${sftpCtrPNum} 2>&1
        );
        sftpSta=$?
    fi

    logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

    if [[ ${sftpSta} -eq 1 ]];then
        #wrong user name or password
        echo "${sftpRet}"
        return 12
    fi

    if [[ ${sftpSta} -eq 2 ]];then
        #The system cannot find the file specified.
        echo "${sftpRet}"
        return 13
    fi

    #opFlag 0:download; 1:upload
    if [ -n "${fileName}" -a ${opFlag} -eq 0 ];then
        #download

        local TTNUM=$(echo ${sftpRet}|grep -Ew "${fileNameTmp}"|wc -l)
        if [[ "${TTNUM}" -eq 0 ]];then
            #the file  [${fileName}] is not exists
            echo "${sftpRet}"
            return 14
        fi
    fi

    echo "${sftpRet}"
    return 0
}

function getOrPutSftpFile() #download or upload files from sftp server
{
    if [ $# -ne 10 ];then
        return 1
    fi

    local opFlag=$1 #opFlag 0:download; 1:upload
    local tcheck=$(echo "${opFlag}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && opFlag=0
    shift

    local trsType=$1 #0:ascii ,1:binary
    tcheck=$(echo "${trsType}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsType=0
    shift

    local trsMode=$1 #0:passive mode for data transfers, 1:active mode for data transfers
    tcheck=$(echo "${trsMode}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsMode=0
    shift

    
    local debugflag=1

    local sftpIP=$1      #sftp ip address
    local sftpUser=$2    #sftp username
    local sftpPwd=$3     #sftp password
    local sftpRdir="$4"  #sftp server path
    local sftpLdir="$5"  #sftp client local path
    local fileName="$6" #file name on the service to be processed
    local sftpCtrPNum=$7 #the port number

    #if the file name ${fileName} is mutiple file names(separated by spaces or table keys),replaced with | ,and remove the head and tail | (if any)
    #if the file name R{fileName} contains . replace it whith \. ther is a wildcard * replaced by .{0,} for the subsequent grep -E syntax lookup
    local fileNameTmp
    if [ -n "${fileName}" ];then
       fileNameTmp=$(echo $fileName|sed 's/[ ,\t]\{1,\}/\|/g'|sed 's/^|//'|sed 's/|$//'|sed 's/\./\\./g'|sed 's/\*\{1,\}/.\{0,\}/g')
    fi

    local logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

    local opStr
    local opCmd
    #opFlag 0:download; 1:upload
    if [ ${opFlag} -eq 0 ];then
        opStr="downlaod"
        opCmd="mget -c "
    else
        opStr="upload"
        opCmd="mput"
    fi

    local typeStr
    if [ ${trsType} -eq 0 ];then
        typeStr="ascii"
        opCmd="${opCmd} -a"
    else
        typeStr="binary"
    fi

    local modeStr
    local modeOpt
    if [ ${trsMode} -eq 0 ];then
        modeStr="passive"
        modeOpt="-p"
    else
        modeStr="active"
        modeOpt="-A"
    fi
    local outmsg="function getOrPutSftpFile input param ${logTime} 
         debugflag=[${debugflag}]
         opFlag=[${opFlag}],opStr=[${opStr}],opCmd=[${opCmd}]
         trsType=[${trsType}],typeStr=[${typeStr}]
         trsMode=[${trsMode}],modeStr=[${modeStr}],modeOpt=[${modeOpt}]
         fileNameTmp=[$fileNameTmp]--------
         ---------sftp para begine--------
         ----sftpIP     =[${sftpIP}]
         ----sftpUser   =[${sftpUser}]
         ----sftpPwd    =[${sftpPwd}]
         ----sftpRdir   =[${sftpRdir}]
         ----sftpLdir   =[${sftpLdir}]
         ----fileName  =[${fileName}]
         ----sftpCtrPNum=[${sftpCtrPNum}]
         ---------sftp para end----------
         "
    outShDebugMsg "" ${debugflag} 1 "${outmsg}"
    
    if [[ -z "${fileName}" ]];then
        #file name is null
        echo "file name is null"
        return 9
    fi

    if [[ ! -d "${sftpLdir}" ]];then
        #local path error
        echo "local path [${sftpLdir}] error"
        return 10
    fi

    nc -z ${sftpIP} ${sftpCtrPNum} >/dev/null 2>&1
    local ret=$?
    if [ ${ret} -ne 0 ];then
        #connect sftp server error
        echo "connect sftp server[${sftpIP} ${sftpCtrPNum}] error"
        return 11
    fi

    if [ -z "${sftpRdir}" ];then
        sftpRdir="./"
    fi
    if [ -z "${sftpLdir}" ];then
        sftpLdir="./"
    fi

    local fileRet
    local retStat
    #opFlag 0:download; 1:upload
    if [ -n "${fileName}" -a ${opFlag} -eq 1 ];then 
        #upload

        #view all files in the directory to be uplaod to determine where the uplaod file exists
        fileRet=$(wegrepFileDir "${sftpLdir}" "${fileNameTmp}")
        retStat=$?
        outShDebugMsg "" ${debugflag} 4 "\n${fileRet}\n"
        if [ "${retStat}" -ne 0 ];then
            #the file  [${fileName}] is not exists
            echo "${fileRet}"
            return 14
        fi
    fi

    #download or upload
    local sftpSta
    local sftpRet
        #set net:timeout 4;set net:max-retries 4;set net:reconnect-interval-base 1;
        #set net:timeout 3;set net:max-retries 1;set net:reconnect-interval-base 1;
    sftpRet=$(echo "debug 3
        set net:timeout 4;set net:max-retries 4;set net:reconnect-interval-base 1;
        cd ./ || exit 1
        cd ${sftpRdir} || exit 2
        lcd ${sftpLdir} || exit 10
        ${opCmd} ${fileName} || exit 3
        bye"|lftp -u ${sftpUser},${sftpPwd} sftp://${sftpIP}:${sftpCtrPNum} 2>&1
    );
    sftpSta=$?

    logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

    #echo "${opCmd} ${fileName} sftpSta=[${sftpSta}],sftpRet=[${sftpRet}]"

    if [[ ${sftpSta} -eq 1 ]];then
        #wrong user name or password
        echo "${sftpRet}"
        return 12
    fi

    if [[ ${sftpSta} -eq 2 ]];then
        #The system cannot find the file specified.
        echo "${sftpRet}"
        return 13
    fi
    #opFlag 0:download; 1:upload
    if [ ${sftpSta} -eq 3  -a ${opFlag} -eq 0 ];then
        #the file  [${fileName}] is not exists
        echo "${sftpRet}"
        return 14
    elif [ -n "${fileName}" -a ${opFlag} -eq 0 ];then
        #download
        fileRet=$(wegrepFileDir "${sftpLdir}" "${fileNameTmp}")
        retStat=$?
        outShDebugMsg "" ${debugflag} 4 "\n${fileRet}\n"
        if [ "${retStat}" -ne 0 ];then
            #the downloaded file  [${fileName}] is not exists
            echo "${fileRet}"
            return 15
        fi
    fi


    echo "${sftpRet}"
    return 0
}


function F_formatFtpBusCnt() #format ftp server's status business file content
{
	if [ $# -ne 2 ];then
		return 1
	fi
	local preDoFile="$1"
	local outputFile="$2"

	sed -n '/\(\btdir1\b\|\bup\b\|busilist_\)/p' ${preDoFile} |sed 's/^\s*250\s*Directory\s*changed\s*to\s*//g'|sed '/tdir/ i\\n'|sed 's/^/  /g'>>${outputFile}

	return 0
}


function F_sendMail()
{
    if [ $# -lt 5 ];then
        return 1
    fi

    local sdmailTitle="$1"
    local smailFile="$2"
    local attachFile="$3"
    local rMailAddr="$4"
    local logFile="$5"

    local rMailAddrList; local enableMail; local mailAddr;
    local it; local outmsg; local attaFlag=0;

    if [[ ! -e "${smailFile}" ]];then
        return 2
    fi

    local tnum=$(wc -l ${smailFile} |awk '{print $1}')
    if [ ${tnum} -lt 1 ];then
        return 3
    fi

    if [[ -z "${attachFile}" || ! -e "${attachFile}" ]];then
        attaFlag=0
    else
        attaFlag=1
    fi

    #rMailAddr="
    #    1#fusk_zfmd@163.com,zhulj_zfmd@163.com,yangm_zfmd@163.com,lix_zfmd@163.com,liwl_zfmd@163.com
    #"

    rMailAddrList=$(F_convertVLineToSpace "${rMailAddr}") 
    for it in ${rMailAddrList}
    do
        enableMail=$(echo "${it}"|cut -d '#' -f 1)
        mailAddr=$(echo "${it}"|cut -d '#' -f 2)
        #echo  "${enableMail}"
        if [ "${enableMail}" = "1" ];then
			if [ ${attaFlag} -eq 1 ];then
				/bin/mail -s "${sdmailTitle}" -a ${attachFile} ${mailAddr} <${smailFile}
				outmsg="/bin/mail -s \"${sdmailTitle}\" -a ${attachFile} ${mailAddr} <${smailFile}"
			else
				/bin/mail -s "${sdmailTitle}" ${mailAddr} <${smailFile}
				outmsg="/bin/mail -s \"${sdmailTitle}\"  ${mailAddr} <${smailFile}"
			fi
            #echo "outmsg=[${outmsg}]"
            F_outShDebugMsg ${logFile} 1 1 "${FUNCNAME}:${outmsg}"
        fi
    done 

    return 0
}
