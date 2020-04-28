#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20181113
#linux_version:    Red Hat Enterprise Linux Server release 6.7 
#dsc          :   
#    Some functions used in the Zone III weather download script
#
#############################################################################


#Print function input parameter
#  usage: prtFuncInput [function_name] $@
function prtFuncInput()
{
    if [ $# -lt 2 ];then
        return 0
    fi
    
    fName=$1
    shift
    echo "The input of function [ ${fName}] is as follows:"
    declare -i i=1
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

    allName="$1"
    if [ -z "${allName}" ];then
        echo "  Error: function getFnameOnPath input parameters is null!"
        return 2;
    fi

    slashNum=$(echo ${allName}|grep "/"|wc -l)
    if [ ${slashNum} -eq 0 ];then
        echo ${allName}
        return 0 
    fi

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

    inum=$#
    logFile="$1"
    cfgDebugFlag="$2"
    valDebugFlag="$3"
    puttxt="$4"
    
    tcheck=$(echo "${cfgDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && cfgDebugFlag=0
    tcheck=$(echo "${valDebugFlag}"|sed -n "/^[1-9][0-9]*$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && valDebugFlag=0

    if [ $((${cfgDebugFlag}&${valDebugFlag})) -ne ${valDebugFlag} ];then
        return 0
    fi
    
    #output content to standard output device if the log file name is empty
    if [ -z "${logFile}" ];then
        echo -e "${puttxt}"
        return 0
    fi

    tmpdir=$(getPathOnFname "${logFile}")
    ret=$?
    [ ${ret} -ne 0 ] && echo "${tmpdir}" && return ${ret}

    if [ ! -d "${tmpdir}" ];then
        echo "  Error: dirname [${tmpdir}] not exist!"
        return 2
    fi

    clearFlag=0
    [ ${inum} -eq 5 ] && clearFlag=$5
    tcheck=$(echo "${clearFlag}"|sed -n "/^[0-9]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && clearFlag=0
    [ ${clearFlag} -eq 1 ] && >"${logFile}"
    
    if [ ${clearFlag} -eq 2 ];then
        echo -e "${puttxt}"|tee -a "${logFile}"
    else
        echo -e "${puttxt}">>"${logFile}"
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

    tpath=$1
    if [ ! -d ${tpath} ];then
        return 2
    fi

    tdays=$2
    if [ $# -eq 3 ];then
        tname=$3
    else
        tname="*"
    fi

    #echo "++++++[${tpath}/${tname}]+++"
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
    myFuncName="deterSameFile"
    
    if [ $# -lt 3 ];then
        outShDebugMsg "" 0 0 "\nCall shell function [ ${myFuncName} ] parameter number error"
        return 100
    fi

    #print log level:identifiable level 2 N-th power combination
    shDebugFlag=$1

    tDir=$2
    tFname=$3

    declare -i ret=0
    
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

    debugflag=0

    tpath="$1"
    sfname="$2"
    
    [ ! -d "${tpath}" ] && return 2
    [ -z "${sfname}" ] && return 3

    #check whether there are ${sfname} related files in the ${tpath} directory
    fileRet=$(cd ${tpath} 2>&1 && ls -1 2>&1|while read tmpRead
    do
    echo ${tmpRead}
    done);

    outShDebugMsg "" ${debugflag} 4 "\n${fileRet}\n"

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

    opFlag=$1 #0:download; 1:upload
    tcheck=$(echo "${opFlag}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && opFlag=0
    shift

    trsType=$1 #0:ascii ,1:binary
    tcheck=$(echo "${trsType}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsType=0
    shift

    trsMode=$1 #0:passive mode for data transfers, 1:active mode for data transfers
    tcheck=$(echo "${trsMode}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsMode=0
    shift

    
    debugflag=1

    ftpIP=$1      #ftp ip address
    ftpUser=$2    #ftp username
    ftpPwd=$3     #ftp password
    ftpRdir="$4"  #ftp server path
    ftpLdir="$5"  #ftp client local path
    fileName="$6" #file name on the service to be processed
    ftpCtrPNum=$7 #the port number

    #if the file name ${fileName} is mutiple file names(separated by spaces or table keys),replaced with | ,and remove the head and tail | (if any)
    #if the file name R{fileName} contains . replace it whith \. ther is a wildcard * replaced by .{0,} for the subsequent grep -E syntax lookup
    if [ -n "${fileName}" ];then
       fileNameTmp=$(echo $fileName|sed 's/[ ,\t]\{1,\}/\|/g'|sed 's/^|//'|sed 's/|$//'|sed 's/\./\\./g'|sed 's/\*\{1,\}/.\{0,\}/g')
    fi

    logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

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

    outmsg="function getFtpSerStatu input param ${logTime} 
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
    ret=$?
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
    v220=$(echo ${ftpRet}|grep -E "\s+\<220\>\s+"|wc -l)
    #Password required
    v331=$(echo ${ftpRet}|grep -E "\s+\<331\>\s+"|wc -l)
    #not logging in to the network
    v530=$(echo ${ftpRet}|grep -E "\s+\<530\>\s+"|wc -l)
    #login to the internet
    v230=$(echo ${ftpRet}|grep -E "\s+\<230\>\s+"|wc -l)
    #The system cannot find the file specified.
    v550=$(echo ${ftpRet}|grep -E "\s+\<550\>\s+"|wc -l)

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

    opFlag=$1 #0:download; 1:upload
    tcheck=$(echo "${opFlag}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && opFlag=0
    shift

    trsType=$1 #0:ascii ,1:binary
    tcheck=$(echo "${trsType}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsType=0
    shift

    trsMode=$1 #0:passive mode for data transfers, 1:active mode for data transfers
    tcheck=$(echo "${trsMode}"|sed -n "/^[0-1]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && trsMode=0
    shift

    
    debugflag=1

    ftpIP=$1      #ftp ip address
    ftpUser=$2    #ftp username
    ftpPwd=$3     #ftp password
    ftpRdir="$4"  #ftp server path
    ftpLdir="$5"  #ftp client local path
    fileName="$6" #file name on the service to be processed
    ftpCtrPNum=$7 #the port number

    #if the file name ${fileName} is mutiple file names(separated by spaces or table keys),replaced with | ,and remove the head and tail | (if any)
    #if the file name R{fileName} contains . replace it whith \. ther is a wildcard * replaced by .{0,} for the subsequent grep -E syntax lookup
    if [ -n "${fileName}" ];then
       fileNameTmp=$(echo $fileName|sed 's/[ ,\t]\{1,\}/\|/g'|sed 's/^|//'|sed 's/|$//'|sed 's/\./\\./g'|sed 's/\*\{1,\}/.\{0,\}/g')
    fi

    logTime="$(date '+%Y/%m/%d %H:%M:%S.%N')"

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
    outmsg="function getOrPutFtpFile input param ${logTime} 
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
    ret=$?
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
    v220=$(echo ${ftpRet}|grep -E "\s+\<220\>\s+"|wc -l)
    #User logged in
    v230=$(echo ${ftpRet}|grep -E "\s+\<230\>\s+"|wc -l)
    #Transfer complete
    v226=$(echo ${ftpRet}|grep -E "\s+\<226\>\s+"|wc -l)
    #Password required
    v331=$(echo ${ftpRet}|grep -E "\s+\<331\>\s+"|wc -l)
    #not logging in to the network
    v530=$(echo ${ftpRet}|grep -E "\s+\<530\>\s+"|wc -l)
    #login to the internet
    v230=$(echo ${ftpRet}|grep -E "\s+\<230\>\s+"|wc -l)
    #The system cannot find the file specified.
    v550=$(echo ${ftpRet}|grep -E "\s+\<550\>\s+"|wc -l)

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

