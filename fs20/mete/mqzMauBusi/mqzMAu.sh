#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20180929
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    fs2.0 project temporary solution:
#       Meiqiaozhen wind farm semi-manually generated business list shell script 
#
#
#############################################################################


baseDir=$(dirname $0)


#log dir
shLogDir=${baseDir}/log
if [[ ! -d "${shLogDir}" ]];then
    echo "mkdir -p ${shLogDir}"
    mkdir -p "${shLogDir}"
fi

#log file
preShNAME=mqzMAu
shNAME="${preShNAME}.sh"
myLogName="${shLogDir}/${preShNAME}_${tmpYMD}.log"

#Current time required to fill out the business list
curDate1=$(date +%Y/%m/%d_%H:%M:%S)

#Year, month and day variable
tmpYMD=$(date +%Y%m%d)

#echo "-----${baseDir}"

if [[ ! -d ${baseDir}/func ]];then
    echo ""
    echo "eror: no [${baseDir}/func] directory"
    echo ""
    exit 1
fi
if [[ ! -f ${baseDir}/func/fuskyfunc.main ]];then
    echo ""
    echo "eror: [${baseDir}/func/fuskyfunc.main] file does not exist"
    echo ""
    exit 2
fi
if [[ ! -f ${baseDir}/func/personal.func ]];then
    echo ""
    echo "eror: [${baseDir}/func/personal.func] file does not exist"
    echo ""
    exit 3
fi
#Load shell function file
. ${baseDir}/func/personal.func
. ${baseDir}/func/fuskyfunc.main



readAFileN=${baseDir}/cfg/readPara.cfg
echo "===$readAFileN"

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

   preName=$( echo ${LINE}|awk -F '=' '{ if(NF>0){print $1;}}'|tr "\040\011" "\0")
   valName=$( echo ${LINE}|awk -F '=' '{ if(NF>0){print $2;}}'|tr "\040\011" "\0")
   valNameNb=$( echo ${LINE}|awk -F '=' '{ if(NF>0){print $2;}}')
   
   #Get global print log level values
   if [ "${preName}" == "outDebugLevel" ]; then
       tmpDebugLevel=${valName}
       continue
   fi
   
   
   if [ "${preName}" == "qxEncode" ]; then
       qxEncode=${valName}
       continue
   fi
   if [ "${preName}" == "ycEncode" ]; then
       ycEncode=${valName}
       continue
   fi
   if [ "${preName}" == "qxFileName" ]; then
       qxFileName=${valName}
       continue
   fi
   if [ "${preName}" == "ycFileName" ]; then
       ycFileName=${valName}
       continue
   fi
   if [ "${preName}" == "dataId" ]; then
       dataId=${valName}
       continue
   fi
   if [ "${preName}" == "sufNum" ]; then
       sufNum=${valName}
       continue
   fi
   if [ "${preName}" == "fileYMD" ]; then
       fileYMD=${valName}
       continue
   fi
   
   #Get the server ip
   if [ "${preName}" == "ftpIP" ]; then
       tmpftpIP=${valName}
       continue
   fi
   #Get the server username
   if [ "${preName}" == "ftpUser" ]; then
       tmpftpUser=${valName}
       continue
   fi
   #Get the server password
   if [ "${preName}" == "ftpPwd" ]; then
       tmpftpPwd=${valName}
       continue
   fi
   #Get the server port
   if [ "${preName}" == "ftpPort" ]; then
       tmpftpport=${valName}
       continue
   fi
   
   #Get the download server path
   if [ "${preName}" == "ftpRdir" ]; then
       tmpftpRdir=${valName}
       continue
   fi
   #Get the download local path
   if [ "${preName}" == "ftpLdir" ]; then
       tmpftpLdir=${valName}
       continue
   fi
   #Get a list of downloaded files
   if [ "${preName}" == "fileName" ]; then
       tmpftpfileName=${valNameNb}
       continue
   fi
   #Get the upload file path
   if [ "${preName}" == "upRdir" ]; then
       tmpupRdir=${valName}
       continue
   fi
   if [ "${preName}" == "upRdirBak" ]; then
       tmpupRdirBak=${valName}
       continue
   fi
done <${readAFileN}

curYMHMS=$(date "+%Y%m%d%H%M%S")

#Get the ftp download server status
getDFserStas "${tmpDebugLevel}" "${tmpftpIP}" "${tmpftpUser}" "${tmpftpPwd}" "${tmpftpRdir}" "${tmpftpLdir}" "${tmpftpfileName}" "${tmpftpport}"  
ftpstat=$?

#echo "------ftpstat=${ftpstat}"  
if [[ ${ftpstat} -eq 0 ]];then
    echo "+++${tmpFSname[${tmpserNo[$i]}]} status is ok!"  
    
    haveFlag="1"
    
    #Ftp file download
    getFtpFiles "${tmpDebugLevel}" "${tmpftpIP}" "${tmpftpUser}" "${tmpftpPwd}" "${tmpftpRdir}" "${tmpftpLdir}" "${tmpftpfileName}" "${tmpftpport}"  
    dnstat=$?
    if [[ ${dnstat} -eq 0 ]];then
        echo "++++++getFtpFiles is ok!"  
        
        #Type identification and transcoding of downloaded files
        tmpQxsjFile=$(echo ${tmpftpfileName}|awk '{for(i=1;i<=NF;i++) print $i}'|grep qxsj)
        tmpYcsjFile=$(echo ${tmpftpfileName}|awk '{for(i=1;i<=NF;i++) print $i}'|grep ycsj)
        if [[ -z ${tmpQxsjFile} || -z ${tmpYcsjFile} ]];then
            echo "---------fileName=${tmpftpfileName} file name does not include qxsj or ycsj !"  
            exit 4
        fi
        
        #Merged into a business list
        composeMqzBusi "$tmpDebugLevel" "${baseDir}" "$qxEncode" "$ycEncode" "$qxFileName" "$ycFileName" "$dataId" "$sufNum" "$fileYMD"
        compstat=$?
        
        #Upload the merged business list to the server
        ls -1 ${baseDir}/result/busilist_[0-9][0-9][0-9]*.tmp|while read tmpname
        do
            tname=$(echo $tmpname|awk -F '/' '{print $NF}')
            remoBusiXmlF=$(echo "$tname"|awk -F '.' '{printf "%s.xml", $1}')
            #putFtpFiles "${tmpDebugLevel}" "${tmpftpIP}" "${tmpftpUser}" "${tmpftpPwd}" "${tmpupRdir}" "${baseDir}/result" "${tname}" "${remoBusiXmlF}" "${tmpupRdirBak}" 
            putFtpFiles "${tmpDebugLevel}" "${tmpftpIP}" "${tmpftpUser}" "${tmpftpPwd}" "${tmpupRdir}" "${baseDir}/result" "${tname}" "${remoBusiXmlF}" 
            upstat=$?
            if [[ ${dnstat} -eq 0 ]];then
                echo "+++++++++putFtpFiles is ok!"
                newName="${tmpname}_${curYMHMS}"
                echo "mv $tmpname  $newName"
                mv $tmpname  $newName
            else
                echo "------putFtpFiles return ${upstat}"  
                exit 5
            fi
        done
        
        
        ls -1 ${tmpftpLdir}/*.txt|while read rdtxt
        do
            newtxt="${rdtxt}_${curYMHMS}"
            echo "mv $rdtxt $newtxt"
            mv $rdtxt $newtxt
        done
        ls -1 ${tmpftpLdir}/*.txt_gbk|while read rdtxt
        do
            newtxt="${rdtxt}_${curYMHMS}"
            echo "mv $rdtxt $newtxt"
            mv $rdtxt $newtxt
        done
    else
        echo "------getFtpFiles return ${dnstat}"  
        exit 6
    fi
    
else
    echo "---getDFserStas return ${ftpstat}"  
    exit 7
fi


#composeMqzBusi "$tmpDebugLevel" "${baseDir}" "$qxEncode" "$ycEncode" "$qxFileName" "$ycFileName" "$dataId" "$sufNum" "$fileYMD"

echo $(date "+%Y/%m/%d %H:%M:%S.%N")" shell ${shNAME} execution success----"
echo ""
