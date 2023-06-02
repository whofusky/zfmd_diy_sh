#!/bin/bash
#
################################################################################
#
# athor    : fushikai
# date     : 2023-06-02
# dsc      : 自动生成一个风场业务清单合成配置(只能包含2个文件:一个qx,一个yc)
#
################################################################################
#

inShName="$0"
inExName="${inShName##*/}"
inNum="$#"
inFile="$1" ; tmpFile="" ; tmptmp=""
frmdirname="$2"
qxfname="$3"; ycfname="$4"; cyctime="$5"
fixModStr='
            <taskItem> <!-- tuoli110 任务信息-->
                <usHostNum>12</usHostNum>
                <arrHostName>2.0运算中心</arrHostName>
                <usTaskId>46</usTaskId>
                <arrTaskName>tuoli110</arrTaskName>
                <ucTaskRole>1</ucTaskRole>
                <ucDispStegy>1</ucDispStegy>
                <tWarn>100</tWarn>
                <tEnd>200</tEnd>
                <usJobCfg>65</usJobCfg>
                <afterDnDelFlag>0</afterDnDelFlag>
		        		
                <arrCycleList>
                    <arrCycle timeHMS="05-15-31" > 
                        <downFile downDir="/tuoli110" dnLocDir="filepath/ftpdown/tuoli110" fsSrcDir="filepath/ftpdown/tuoli110" dnFileName="qxsj01756.txt" />
                        <downFile downDir="/tuoli110" dnLocDir="filepath/fsLocDir/tuoli110" fsSrcDir="filepath/fsLocDir/tuoli110" dnFileName="ycsj01756.txt" />
                    </arrCycle>
                </arrCycleList>
                
                <startImdtly imdFlag="0" >
                    <imdStartCycIdx>0</imdStartCycIdx> 
                </startImdtly>
                
                <dnErrOp>
                    <numOfDnErrOp>60</numOfDnErrOp>
	                <tmOfDnErrOp>11</tmOfDnErrOp>
                </dnErrOp>
                
                <downServer outTime="60"><!--ftp http -->
                    <server sharSerNo="0" />
                </downServer >
		            
                <forcastCfg>
                    
                    <outTime>120</outTime>
                    <endTime>240</endTime>
                    
                    <fsFileLst num="1">
                        <filecfg fileNameCfgMethod="3">
                            <fsLocDir>tuoli110</fsLocDir>
                            <srcEncodeFs>utf8</srcEncodeFs>
                            <filePre>1</filePre> 
                            <fwFileNameHHSS></fwFileNameHHSS> 
                        </filecfg>
                    </fsFileLst>
                </forcastCfg>
                
                <upCfg>
                    
                    <outTime>60</outTime>
                    <upDirs>
                        <upDir>/tuoli110/tdir1</upDir>
                        <upDir>/tuoli110/up</upDir>
                    </upDirs>       
                    
                    <upLocDir>filepath/ftpup/tuoli110</upLocDir>
                    
                    <upFileLst num="1">
                        <upFile>busilist_</upFile>
                    </upFileLst>
                    
                    <ucSerNum>1</ucSerNum>
                </upCfg>
                
                <busiInfo>
	                <file>
	                    <fileSuffixNum>0</fileSuffixNum>
	                    <submitter>1</submitter>
	                    <coordinate>100</coordinate>
	                    <submitTime>2000</submitTime>
	                    <taskID>1</taskID>
	                    
	                    <jobNumber>1</jobNumber>
	                    
	                    <jobDescList>
	                        <jobItemDesc>
	                            <jobID>0110</jobID>
	                            <featureCode>0021</featureCode>
	                            <statisticalRange>0</statisticalRange>
	                            <validAralID>00</validAralID>
	                            <dataComeIntoTime>2017-07-10:16-00-00</dataComeIntoTime>
	                            <dataTimeFeature>0084-15-0001</dataTimeFeature>
	                            <postProcessCode>00-00-00-0-0</postProcessCode>
	                        </jobItemDesc>
	                    </jobDescList>
	                    
	                    <jobDataList>
	                        <jobItemData>
	                            <jobID>0110</jobID>
	                            <dataDir>filepath/ftpdown/tuoli110</dataDir>
	                            <fileEncode>utf8</fileEncode>
	                            <jobDataList>
	                                <dataID>0</dataID>
	                                <jobData fileNameCfgMethod="3">0</jobData>
	                            </jobDataList>
	                        </jobItemData>
	                    </jobDataList>
	                </file>
	              </busiInfo>
            </taskItem>
'

function F_checkSysCmd() #call eg: F_checkSysCmd "cmd1" "cmd2" ... "cmdn"
{
    [ $# -lt 1 ] && return 0

    local errFlag=0
    while [ $# -gt 0 ]
    do
        which $1 >/dev/null 2>&1
        if [ $? -ne 0 ];then 
            echo -e "${LINENO}|${FUNCNAME}|ERROR|The system command \"$1\" does not exist in the current environment!"
            errFlag=1
        fi
        shift
    done

    [ ${errFlag} -eq 1 ] && exit 1
}

function F_getFileName() #get the file name in the path string
{
    [ $# -ne 1 ] && return 0
    [  -z "$1" ] && return 0
    echo "${1##*/}" && return 0
}


function F_getPathName() #get the path value in the path string(the path does not have / at the end)
{
    [ $# -ne 1 ] && return 0
    [  -z "$1" ] && return 0

    local tpath="${1%/*}"
    [ "${tpath}" = "$1" ] && tpath="."
    echo "${tpath}" && return 0
}

function F_tips()
{
    echo -e "\n\t提示:自动生成一个风场业务清单合成配置(只能包含2个文件:一个qx,一个yc)"
    echo -e "\n\tuse: ${inExName} <compute_2.0_config.xml> <frm_dir_name> <qxsj_file_name> <ycsj_file_name> <cycle_time>"
    echo -e "\t\tcycle_time:HH24-MI-SS, eg 05-59-51\n"
    return 0
}


function F_init()
{
    F_checkSysCmd "iconv"

    if [ ${inNum} -ne 5 ];then
        F_tips
        exit 1
    fi
    if [ ! -e "${inFile}" ];then
        echo -e "\n\tERROR:file [ ${inFile} ] not exist!\n"
        exit 2
    fi
    if [[ -z "${qxfname}" || -z "${ycfname}" ]];then
        F_tips
        exit 1
    fi

    #结果文件与气象文件同目录
    rstf_dir=$(F_getPathName "${qxfname}")

    #校验气象及预测文件名前缀是否对
    #气象文件名需要是:qxsj开头
    #预设文件名需要是:ycsj开头
    local tname=$(F_getFileName "${qxfname}")
    if [ "${tname:0:4}" != "qxsj" ];then
        F_Tips
        echo -e "\n${LINENO}|${FUNCNAME}|ERROR|其中qxsj_file[${qxfname}]文件名需要是qxsj开头!\n"
        exit 1
    fi
    tname=$(F_getFileName "${ycfname}")
    if [ "${tname:0:4}" != "ycsj" ];then
        F_Tips
        echo -e "\n${LINENO}|${FUNCNAME}|ERROR|其中ycsj_file[${ycfname}]文件名需要是ycsj开头!\n"
        exit 1
    fi
    local fileSufix="${inFile##*.}"
    local filePre="${inFile%.*}"
    #echo "filePre=[${filePre}],fileSufix=[${fileSufix}]"
    tmpFile="${filePre}_utf8.${fileSufix}"
    tmptmp="${filePre}.tmp"
    [ -f "${tmpFile}" ] && rm -rf "${tmpFile}"

    iconv -f gbk -t utf-8 "${inFile}" -o "${tmpFile}"
    sed -i 's///g' "${tmpFile}"
    return 0
}

function F_get_usTaskId()
{
    sed -n '/^\s*<\s*usTaskId\s*>/{s/\s\+<!.*//g;s/<\/*[a-zA-Z]\+\|>//g;s/\s\+//g;p}' "${tmpFile}"|sort -n >${tmptmp} 

    local i j findflag

    j=0; findflag=0;
    while read i
    do
        let j++
        if [ "$i" != "$j" ];then
            findflag=1
            break
        fi
    done<"${tmptmp}"
    if [ ${findflag} -eq 0 ];then
        let j++
    fi
    #echo "${j}"
    newTaskId="${j}"
}

function F_change_modstr()
{
    #tmpStr
    #修改usTaskId
    tmpStr=$(echo "${fixModStr}"|sed "s/\(^\s*<\s*usTaskId\s*>\)\(\s*[^<]*\)/\1${newTaskId}/")
    #修改风场文件夹名
    tmpStr=$(echo "${tmpStr}"|sed "s/\<tuoli110\>/${frmdirname}/g")
    #修改定时时间
    tmpStr=$(echo "${tmpStr}"|sed "/^\s*<\s*arrCycle\s/{s/05-15-31/${cyctime}/}")
    #修改气象和预测数据文件名
    tmpStr=$(echo "${tmpStr}"|sed "/^\s*<\s*downFile\s/{s/qxsj01756.txt/${qxfname}/g;s/ycsj01756.txt/${ycfname}/g}")
    #echo "${tmpStr}"
}

function F_write_result()
{
    rstfile="${rstf_dir}/tmp_result_file.xml"
    if [ -f "${rstfile}" ];then
        rm -rf "${rstfile}"
    fi
    echo "${tmpStr}">"${tmptmp}"
    iconv -f utf-8 -t gb18030 "${tmptmp}" -o "${rstfile}"
    sed -i 's/$//g' "${rstfile}"
    echo -e "\n\t结果文件为:[ ${rstfile} ]\n"
}

function F_cleartmp()
{
    [ -f "${tmptmp}" ] && rm -rf "${tmptmp}"
    [ -f "${tmpFile}" ] && rm -rf "${tmpFile}"
}


main()
{
    F_init
    F_get_usTaskId
    F_change_modstr
    F_write_result
    F_cleartmp
}
main
