#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20180929
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    fs2.0 project temporary solution:
#       download weather files and short-term forecast files from the cloud
#       platform to the local, and then merge them into a business list and
#       upload them to the cloud platform for download in the III area weather
#       downloader.
#
#
#############################################################################


#Load system environment variable configuration file
if [ -f /etc/profile ]; then
    . /etc/profile
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile
fi

#This script is already running and exits
tmpShPid=$(pidof -x $0)
tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
if [ ${tmpShPNum} -gt 1 ]; then
    echo "+++${tmpShPid}+++++${tmpShPNum}+++"
    echo "`date +%Y/%m/%d-%H:%M:%S.%N`:$0 script has been running this startup exit!"
    exit 0
fi


#User-defined environment variables in the configuration file (if export is required)

#Configuration file
readDir=`dirname $0`
readAFileN=${readDir}/ftpser.cfg

#log dir
shLogDir=${readDir}/log
if [[ ! -d "${shLogDir}" ]];then
    mkdir -p "${shLogDir}"
fi

#Year, month and day variable
tmpYMD=$(date +%Y%m%d)

preShNAME="tmpAutoBusi"
shNAME="${preShNAME}.sh"
#log file
myLogName="${shLogDir}/${preShNAME}_${tmpYMD}.log"

#Current time required to fill out the business list
curDate1=$(date +%Y/%m/%d_%H:%M:%S)

#echo "-----${readDir}"
#echo "readAFileN=$readAFileN"

ttDateFile="${readDir}/tmpdate.txt"
echo -n ${curDate1}>${ttDateFile}

#cat ${busLisTemp1} ${ttDateFile} ${busLisTemp11} qxsj03201.txt_1 ${busLisTemp2} ycsj03201.txt_1 ${busLisTemp3} >${resBusiFile}
#Business list template file 
busLisTemp1="${readDir}/busilist_1"
busLisTemp11="${readDir}/busilist_1_1"
busLisTemp2="${readDir}/busilist_2"
busLisTemp3="${readDir}/busilist_3"



#Number of server names
numFtpSN=0

#Ip number
numIp=0

#Number of usernames
numUser=0

#Number of passwords
numPwd=0

#Number of ports
numPor=0

#Number of task names
numTskN=0

#Number of server numbers
numSerNo=0

#Number of server paths
numRdir=0

#Number of local paths
numLdir=0

#Number of local target paths
numLAdir=0

#Number of download file lists
numDFile=0

#Number of paths to upload the server
numUpDir=0
numUpDBak=0

while read LINE
do
   tmpIsCm=$(echo ${LINE}|tr "\040\011" "\0"|cut -c1)
   
   #Ignore comment lines
   if [ "${tmpIsCm}" == "#" ]; then
       continue
   fi

   tmpIsExport=$(echo ${LINE}|tr "\040\011" "\0"|cut -c1-6)
   #Export environment variable
   if [ "${tmpIsExport}" == "export" ]; then
       ${LINE}
       continue
   fi

   #Get the server name
   if [ "${tmpIsCm}" == "(" ]; then
       tmpFSname[${numFtpSN}]=$( echo ${LINE}|awk -F'(' '{print $2}'|awk -F')' '{print $1}'|tr "\040\011" "\0")
       let numFtpSN++
       continue
   fi
   
   #Get the download task name
   if [ "${tmpIsCm}" == "[" ]; then
       tmpTskname[${numTskN}]=$( echo ${LINE}|awk -F'[' '{print $2}'|awk -F']' '{print $1}'|tr "\040\011" "\0")
       let numTskN++
       continue
   fi

   preName=$( echo ${LINE}|awk -F '=' '{ if(NF>0){print $1;}}'|tr "\040\011" "\0")
   valName=$( echo ${LINE}|awk -F '=' '{ if(NF>0){print $2;}}'|tr "\040\011" "\0")
   valNameNb=$( echo ${LINE}|awk -F '=' '{ if(NF>0){print $2;}}')

   #Get the global log directory, store the script's own log
   if [ "${preName}" == "allLogDir" ]; then
       tmpAllLogDir=${valName}
       continue
   fi
   
   #Get global print log level values
   if [ "${preName}" == "outDebugLevel" ]; then
       tmpDebugLevel=${valName}
       continue
   fi


   #Get the server ip
   if [ "${preName}" == "ftpIP" ]; then
       tmpftpIP[${numIp}]=${valName}
       let numIp++
       continue
   fi
   #Get the server username
   if [ "${preName}" == "ftpUser" ]; then
       tmpftpUser[${numUser}]=${valName}
       let numUser++
       continue
   fi
   #Get the server password
   if [ "${preName}" == "ftpPwd" ]; then
       tmpftpPwd[${numPwd}]=${valName}
       let numPwd++
       continue
   fi
   #Get the server port
   if [ "${preName}" == "ftpPort" ]; then
       tmpftpport[${numPor}]=${valName}
       let numPor++
       continue
   fi
   
   #Get the server number
   if [ "${preName}" == "serNo" ]; then
       tmpserNo[${numSerNo}]=${valName}
       let numSerNo++
       continue
   fi
   #Get the download server path
   if [ "${preName}" == "ftpRdir" ]; then
       tmpftpRdir[${numRdir}]=${valName}
       let numRdir++
       continue
   fi
   #Get the download local path
   if [ "${preName}" == "ftpLdir" ]; then
       tmpftpLdir[${numLdir}]=${valName}
       let numLdir++
       continue
   fi
   #Get the download target path
   if [ "${preName}" == "ftpLdirAims" ]; then
       tmpftpLdirAims[${numLAdir}]=${valName}
       let numLAdir++
       continue
   fi
   #Get a list of downloaded files
   if [ "${preName}" == "fileName" ]; then
       tmpftpfileName[${numDFile}]=${valNameNb}
       let numDFile++
       continue
   fi
   #Get the upload file path
   if [ "${preName}" == "upRdir" ]; then
       tmpupRdir[${numUpDir}]=${valName}
       let numUpDir++
       continue
   fi
   if [ "${preName}" == "upRdirBak" ]; then
       tmpupRdirBak[${numUpDBak}]=${valName}
       let numUpDBak++
       continue
   fi
   
done <${readAFileN}

#If not configured, the default is 0
if [[ -z "${tmpDebugLevel}" ]];then
    tmpDebugLevel=0
fi


#Load shell function file
. ${readDir}/fuskyfunc.main

#Configured ftp server array size
doSerNum=${#tmpFSname[*]}
let doSerNum--

#The actual task array size to be processed
doTskNum=${#tmpTskname[*]}
let doTskNum--


#echo "doSerNum=${doSerNum}" >>${myLogName} 
#echo "doTskNum=${doTskNum}" >>${myLogName} 
#for i in $( seq 0 ${doSerNum} )
#do
#    echo "${tmpFSname[$i]}" >>${myLogName} 
#done


echo "tmpDebugLevel=${tmpDebugLevel}" >>${myLogName} 
echo "" >>${myLogName} 


haveFlag="0"

#Loop processing configuration download and upload tasks
for i in $( seq 0 ${doTskNum} )
do
    #echo "------------------------i=$i-----------------------" >>${myLogName} 
    #echo "ftpServer=${tmpFSname[${tmpserNo[$i]}]}" >>${myLogName} 
    #echo "tmpTskname=${tmpTskname[$i]}" >>${myLogName} 
    #echo "tmpftpfileName=${tmpftpfileName[$i]}" >>${myLogName} 
    #echo "" >>${myLogName} 
    
    #Get the ftp download server status
    getDFserStas "${tmpDebugLevel}" "${tmpftpIP[${tmpserNo[$i]}]}" "${tmpftpUser[${tmpserNo[$i]}]}" "${tmpftpPwd[${tmpserNo[$i]}]}" "${tmpftpRdir[$i]}" "${tmpftpLdir[$i]}" "${tmpftpfileName[$i]}" "${tmpftpport[${tmpserNo[$i]}]}" >>${myLogName} 
    ftpstat=$?
    
    #echo "------ftpstat=${ftpstat}" >>${myLogName} 
    if [[ ${ftpstat} -eq 0 ]];then
        echo "+++${tmpFSname[${tmpserNo[$i]}]} status is ok!" >>${myLogName} 
        
        haveFlag="1"
        
        #Ftp file download
        getFtpFiles "${tmpDebugLevel}" "${tmpftpIP[${tmpserNo[$i]}]}" "${tmpftpUser[${tmpserNo[$i]}]}" "${tmpftpPwd[${tmpserNo[$i]}]}" "${tmpftpRdir[$i]}" "${tmpftpLdir[$i]}" "${tmpftpfileName[$i]}" "${tmpftpport[${tmpserNo[$i]}]}" >>${myLogName} 
        dnstat=$?
        if [[ ${dnstat} -eq 0 ]];then
            echo "++++++${tmpFSname[${tmpserNo[$i]}]} getFtpFiles is ok!" >>${myLogName} 
            
            #Type identification and transcoding of downloaded files
            tmpQxsjFile=$(echo ${fileName}|awk '{for(i=1;i<=NF;i++) print $i}'|grep qxsj)
            tmpYcsjFile=$(echo ${fileName}|awk '{for(i=1;i<=NF;i++) print $i}'|grep ycsj)
            if [[ -z ${tmpQxsjFile} || -z ${tmpYcsjFile} ]];then
                echo "---------${tmpFSname[${tmpserNo[$i]}]} fileName=${tmpftpfileName[$i]} file name does not include qxsj or ycsj !" >>${myLogName} 
                continue
            fi
            
            pthQxsjFile="${tmpftpLdir[$i]}/${tmpQxsjFile}"
            pthQxsjFileTra="${tmpftpLdir[$i]}/${tmpQxsjFile}_gbk"
            
            pthYcsjFile="${tmpftpLdir[$i]}/${tmpYcsjFile}"
            pthYcsjFileTra="${tmpftpLdir[$i]}/${tmpYcsjFile}_gbk"
            
            #transcoding of downloaded files
            iconv -f utf-8 -t gbk ${pthQxsjFile}  -o ${pthQxsjFileTra} -c
            iconv -f utf-8 -t gbk ${pthYcsjFile} -o ${pthYcsjFileTra}  -c
            
            resBusiFName="busilist_${tmpYMD}_$i.tmp"
            resBusiFile="${readDir}/${resBusiFName}"
            remoBusiXmlF="busilist_${tmpYMD}_$i.xml"

            #Merged into a business list
            #cat ${busLisTemp1} ${ttDateFile} ${busLisTemp11} qxsj03201.txt_1 ${busLisTemp2} ycsj03201.txt_1 ${busLisTemp3} >${resBusiFile}
            cat ${busLisTemp1} ${ttDateFile} ${busLisTemp11} ${pthQxsjFileTra} ${busLisTemp2} ${pthYcsjFileTra} ${busLisTemp3} >${resBusiFile}
            
            #Upload the merged business list to the server
            putFtpFiles "${tmpDebugLevel}" "${tmpftpIP[${tmpserNo[$i]}]}" "${tmpftpUser[${tmpserNo[$i]}]}" "${tmpftpPwd[${tmpserNo[$i]}]}" "${tmpupRdir[$i]}" "${tmpftpLdir[$i]}" "${resBusiFName}" "${remoBusiXmlF}" "${tmpupRdirBak[$i]}" >>${myLogName}
            upstat=$?
            if [[ ${dnstat} -eq 0 ]];then
                echo "+++++++++${tmpFSname[${tmpserNo[$i]}]} putFtpFiles is ok!" >>${myLogName} 
            else
                echo "------${tmpFSname[${tmpserNo[$i]}]} putFtpFiles return ${upstat}" >>${myLogName} 
                continue
            fi
        else
            echo "------${tmpFSname[${tmpserNo[$i]}]} getFtpFiles return ${dnstat}" >>${myLogName} 
            continue
        fi
        
    else
        echo "---ftpServer=${tmpFSname[${tmpserNo[$i]}]} status return ${ftpstat}" >>${myLogName} 
        continue
    fi
    
    echo "" >>${myLogName} 
    
done

if [[ "${haveFlag}" == "1" ]];then
    ${readDir}/rmTmpThis.sh  >>${myLogName} 
    echo $(date "+%Y/%m/%d %H:%M:%S.%N")" shell ${shNAME} execution ends! " >>${myLogName} 
    echo "" >>${myLogName} 
fi

exit 0


