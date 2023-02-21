#!/bin/bash
#
################################################################################
#
#author:fushikai
#date  :2021-03-13
#desc  :根据已经生成的30个单风机1分钟数据文件生成(合成)单风机30分钟数据文件
#
#Precondition :
#       1. 在脚本的同级目录下有配置文件cfg/cfg.cfg，且配置文件已经按要求配置完成
#
#       2. 配置文件中配置的数据源文件已经存在,则业务逻辑满足如下规则:
#          程序根据运行时间找对应数据文件的规则如下：
#              (为了举例说明方便假定1分钟文件名类似:genwnd_1_20210317_1330.cime
#                        生成的30分钟结果文件名类似:JIMENHE_HT_20210317_1430.DJ
#              )
#             (1) 如果程序运行时刻对应的分钟数值在0-29之间（包括0和29）则找前一
#                 小时30-59分钟对应的文件；结果文件名的时间小时值为前一小时分钟
#                 值为30
#                 eg: 程序运行时刻为: 2021-03-17 15:01:**
#                     对应要找的1分钟数据文件名为:genwnd_1_20210317_1430.cime
#                                   到genwnd_1_20210317_1459.cime 这30个文件
#                     生成的目标文件名为:JIMENHE_HT_20210317_1430.DJ
#             (2) 如果程序运行时刻对应的分钟数值在30-59之间（包括30和59）则找当前
#                 小时0-29分钟对应的文件；结果文件名的时间小时值为当前小时分钟
#                 值为00
#                 eg: 程序运行时刻为: 2021-03-17 15:31:**
#                     对应要找的1分钟数据文件名为:genwnd_1_20210317_1500.cime
#                                   到genwnd_1_20210317_1529.cime 这30个文件
#                     生成的目标文件名为:JIMENHE_HT_20210317_1500.DJ
#
#usage like:  
#         #自动根据系统时间找对应1分钟数据文件
#         ./$0  
#       or
#         #根据输入的时间点找对应时间点对应的1分钟数据文件(一般用于手动的情况)
#         ./$0  <YYYYMMDDHHMISS|YYYYMMDDHHMI> 
#
#Deployment method:
#       将此脚本按每分钟都运行的方式配置在某个操作系统用户下的crontab里即可
#
#       (注:如果要生成的文件是当天的，同一结果文件如果用此脚本已经生成再次运
#           行此脚本不会再次生成文件，除非把脚本同级目录下的.tRecorded文件内
#           容记录的结果文件名删除
#       ）
#
#Version change record:
#     2021-03-17 initial version  v20.01.000
#     2020-06-17 因河北尚义石井电场需求(输出多个文件)由 v20.01.000 升级到 v20.01.010
#
#
################################################################################
#





thisShName="$0"
onlyShName=${thisShName##*/}
onlyShPre=${onlyShName%.*}
[ $# -ge 1 ] && manualEnterDate="$1"
inParNum=$#




###############################################
#Load system environment variable configuration
###############################################
 [ -f /etc/profile ] && . /etc/profile >/dev/null 2>&1
 [ -f ${HOME}/.bash_profile ] && . ${HOME}/.bash_profile >/dev/null 2>&1
 [ -f ${HOME}/.profile ] && . ${HOME}/.profile >/dev/null 2>&1




###############################################
# Obtain time dependent variables
###############################################
v_Year=$(date +%Y) ; v_Month=$(date +%m) ; v_Day=$(date +%d)   ;
v_Hour=$(date +%H) ; v_Minute=$(date +%M); v_Second=$(date +%S);

runYMD=$(date +%Y%m%d)




##################################################
#Define the files and paths required by the script
##################################################
runDir="$(dirname ${thisShName})"

tmpDir="${runDir}/tmp"

logDir="${runDir}/log"
logFile="${logDir}/${onlyShPre}_$(date +%Y%m%d).log"
recordFile="${runDir}/.tRecorded"
versionFile="${runDir}/version.txt"
recordMaxLine=50    #记录文件最多保持 recordMaxLine -1 行记录

diyFuncFile="${runDir}/myDiyShFunction.sh"
cfgFile="${runDir}/cfg/cfg.cfg"

doSrcDir="${tmpDir}/do"    #程序处理时将把源文件文件拷贝到此目录
dosrc_delExpirDays=1       #程序临时处理源文件过期则删除文件的天数
curDoFiles=""              #当前程序需要处理的所有文件带有通配符
curDoRltFileName[0]=""     #当前程序需要生成的结果文件名（不带路径)
rltFileHaveDoFlag[0]=0     #当前程序需要生成的结果文件已经生成过标识:0未生成，1已经生成过了

curDoFile_A[0]=""         #当前程序需要处理的所有文件文件名，0-29每个变量存只存一个文件
curDoFileHS_A[0]=""       #当前程序需要处理的所有文件对应的HH:SS(小时:分钟)




###############################################
#Define the header and end of the result file
###############################################
resultHeadStr=""
resultTailStr=""




###############################################
#Other variable definitions
###############################################
need_perEC_items=30  #每个EC（风机)在30分钟里要求的数据条数






#When manually inputting the time, it will correspond according to the manually 
#inputted time
#
function F_chekManualDate()
{
    [ -z "${manualEnterDate}" ] && return 0

    local tStr="input ERROR;please input like: ${onlyShName} <YYYYMMDDHHMISS|YYYYMMDDHHMI>; eg:${onlyShName} 20210316213700"

    local tlng=${#manualEnterDate}
    if [[ ${tlng} -ne 14 && ${tlng} -ne 12 ]];then
        F_outShDebugMsg "${logFile}" 1 1 "${tStr}" 2
        exit 1
    fi

    local retstat=0
    F_isDigital "${manualEnterDate}"
    retstat=$?
    if [ ${retstat} -ne 1 ];then
        F_outShDebugMsg "${logFile}" 1 1 "${tStr}" 2
        exit 1
    fi

    v_Year=$(echo "${manualEnterDate}"|cut -b 1-4)
    v_Month=$(echo "${manualEnterDate}"|cut -b 5-6)
    v_Day=$(echo "${manualEnterDate}"|cut -b 7-8)
    v_Hour=$(echo "${manualEnterDate}"|cut -b 9-10)
    v_Minute=$(echo "${manualEnterDate}"|cut -b 11-12)
    if [ ${tlng} -eq 14 ];then
        v_Second=$(echo "${manualEnterDate}"|cut -b 13-14)
    else
        v_Second="00"
    fi


    return 0
}

#Determine whether the result file has been generated
#
function F_judgeHaveDone() #return: 1 all have done; 0 some not have done
{
    local iYMD="${v_Year}${v_Month}${v_Day}"

    #Not on the same day, no processing
    if [ "${iYMD}" != "${runYMD}" ];then
        return 0
    fi
    if [ ! -e "${recordFile}" ];then
        return 0
    fi

    local tnum; local i=0;
    local someNeedFlag=0
    for((i=0;i<${g_file_nums};i++))
    do
        tnum=$(egrep "^${curDoRltFileName[$i]}$" "${recordFile}"|wc -l)
        if [ ${tnum} -gt 0 ];then
            rltFileHaveDoFlag[$i]=1
        else
            rltFileHaveDoFlag[$i]=0
            someNeedFlag=1
        fi
    done

    if [ ${someNeedFlag} -eq 1 ];then
        return 0
    else
        return 1
    fi

    return 0
}

#Record the result file to the record file to avoid restarting the generation
#
function F_writeDoneRecord()
{
    if [ $# -lt 1 ];then
        return 0
    fi
    local iYMD="${v_Year}${v_Month}${v_Day}"
    local tfileName="$1"

    #Not on the same day, no processing
    if [ "${iYMD}" != "${runYMD}" ];then
        return 0
    fi
    if [ ! -e "${recordFile}" ];then
        #echo "${curDoRltFileName}">"${recordFile}"
        echo "${tfileName}">"${recordFile}"
        return 0
    fi

    #sed -i "1 i ${curDoRltFileName}" "${recordFile}"
    sed -i "1 i ${tfileName}" "${recordFile}"
    sed -i "${recordMaxLine},$ d" "${recordFile}"

    return 0
}


#The header and end of the resulting file
#
function F_genRltFileFixHT()
{
    #格式进行处理，各字段之间只能用一个空格分隔
    g_upfile_fixCnt_itemH=$(echo "${g_upfile_fixCnt_itemH}"|sed 's/\s\+/ /g')

    # <DANJI::JIMENHE DATE='2021-03-11'>
    #resultHeadStr="<DANJI::${g_upfile_fixCnt_frmName} DATE='"${v_Year}-${v_Month}-${v_Day}"'>"
    resultHeadStr="<DANJI::${g_upfile_fixCnt_frmName} DATE=${g_upfile_Head_TIM_QMARKS}${v_Year}-${v_Month}-${v_Day}${g_upfile_Head_TIM_QMARKS}>"

    # </DANJI::JIMENHE>
    resultTailStr="</DANJI::${g_upfile_fixCnt_frmName}>"

    return 0
}

#Generate the source 1-minute file name and result file name to be processed 
#according to the program running time
#
function F_genFileNames()
{
    local trueFlag=0

    #程序当前运行的时刻所在的分钟数为30到59之间则找当前小时对应的0-29分钟的文件进行处理
    #程序当前运行的时刻所在的分钟数为00到29之间则找前1小时对应的30-59分钟的文件进行处理
    
    trueFlag=$(echo "${v_Minute}>=30 && ${v_Minute}<=59"|bc)

    local i=0; local ii

    if [ ${trueFlag} -eq 1 ];then  #当前小时的0-29分钟的文件

        #ls -l genwnd_1_20210315_03[012][0-9].cime|wc -l

        #genwnd_1_20210315_0300.cime --- genwnd_1_20210315_0329.cime
        curDoFiles="${g_1mi_filePre_domain}${g_1mi_joiner_char}${v_Year}${v_Month}${v_Day}${g_1mi_joiner_char}${v_Hour}[012][0-9]${g_1mi_suffix_domian}"

        #JIMENHE_HT_20210315_0300.DJ

        for ((i=0;i<${g_file_nums};i++))
        do
            curDoRltFileName[$i]="${g_upfile_frmName_domain[$i]}${g_upfile_joiner_char[$i]}${g_upfile_fanCode_domain[$i]}${g_upfile_joiner_char[$i]}${v_Year}${v_Month}${v_Day}${g_upfile_joiner_char[$i]}${v_Hour}00${g_upfile_suffix_domain[$i]}"
        done

        for ((i=0;i<30;i++))
        do
            if [ ${i} -lt 10 ];then
                ii="0${i}" 
            else
                ii="${i}"
            fi
            curDoFileHS_A[$i]="${v_Hour}:${ii}"
            curDoFile_A[$i]="${g_1mi_filePre_domain}${g_1mi_joiner_char}${v_Year}${v_Month}${v_Day}${g_1mi_joiner_char}${v_Hour}${ii}${g_1mi_suffix_domian}"
        done


    else #前1小时的30-59分钟的文件

        local tCurYMD="${v_Year}-${v_Month}-${v_Day} ${v_Hour}:${v_Minute}:${v_Second}"
        local tCurScds=$(date -d "${tCurYMD}" +"%s")
        local fixAddSnds=$(echo "8*60*60"|bc)
        local tHScds=$(echo "1*60*60"|bc)
        local allSnds=$(echo "${tCurScds} + ${fixAddSnds} - ${tHScds}"|bc)
        #local bYmdHMS=$(date -d "1970-01-01 ${allSnds} seconds" +"%Y%m%d_%H:%M:%S")
        local bYmdHMS=$(date -d "1970-01-01 ${allSnds} seconds" +"%Y%m%d_%H")
        local tYMD=$(echo "${bYmdHMS}"|awk -F'_' '{print $1}')
        local tH=$(echo "${bYmdHMS}"|awk -F'_' '{print $2}')

        #ls -l genwnd_1_20210315_03[345][0-9].cime|wc -l

        #genwnd_1_20210315_0230.cime --- genwnd_1_20210315_0259.cime
        curDoFiles="${g_1mi_filePre_domain}${g_1mi_joiner_char}${tYMD}${g_1mi_joiner_char}${tH}[345][0-9]${g_1mi_suffix_domian}"

        #JIMENHE_HT_20210315_0230.DJ
        for ((i=0;i<${g_file_nums};i++))
        do
            curDoRltFileName[$i]="${g_upfile_frmName_domain[$i]}${g_upfile_joiner_char[$i]}${g_upfile_fanCode_domain[$i]}${g_upfile_joiner_char[$i]}${tYMD}${g_upfile_joiner_char[$i]}${tH}30${g_upfile_suffix_domain[$i]}"
        done
        for ((i=0;i<30;i++))
        do
            ii=$(echo "${i} + 30"|bc)
            curDoFileHS_A[$i]="${tH}:${ii}"
            curDoFile_A[$i]="${g_1mi_filePre_domain}${g_1mi_joiner_char}${tYMD}${g_1mi_joiner_char}${tH}${ii}${g_1mi_suffix_domian}"
        done

    fi

    return 0
}

#Some checks that the program needs to run
#
function F_check()
{
    #load sh func
    if [ ! -f ${diyFuncFile} ];then
        echo "$(date +%Y/%m/%d-%H:%M:%S.%N):ERROR:file [${diyFuncFile}] not exits!"
        exit 1
    else
        . ${diyFuncFile}
    fi

    F_chekManualDate

    #Exit if a script is already running
    F_shHaveRunThenExit "${thisShName}"

    if [ ! -d "${doSrcDir}" ];then
        mkdir -p "${doSrcDir}"
    fi

    if [ ! -d "${logDir}" ];then
        mkdir -p "${logDir}"
    fi

    F_checkSysCmd  "${logFile}"  
    F_cfgFileCheck "${logFile}"

    F_writeVersion "${versionFile}"

    return 0
}

#Some initialization operations required for program operation
function F_init()
{
    F_initCfgDefaultValue
    return 0
}


#30 1-minute data for a certain fan, replace the insufficient ones with 
#the latest time
#
function F_fillMiss1miItem()
{
    if [ $# -lt 3 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:${FUNCNAME} input parameters less than 3!"
        return 1
    fi
    local tDir="$1"
    local tECNo="$2"
    #local tmpFileBak="${tDir}/tmp_fj_EC_${tECNo}.bak"
    local tmpFileBak="$3"

    local i=0; local tstr=""; local tHS=""; 
    local curStr=""; local oneLinNullFlag=0; local j=0
    local k=0 ; local tHSPre="" ; local preStr="" ;

    for((i=0;i<30;i++))
    do
        tHS="${curDoFileHS_A[$i]}"
        curStr=$(sed -n "/^${tHS}\s\+/p" ${tmpFileBak})
        if [ -z "${curStr}" ];then
            if [ ${i} -eq 0 ];then
                oneLinNullFlag=1
                continue
            fi
            if [ ${oneLinNullFlag} -eq 1 ];then
                continue
            fi

            j=$i
            let j--
            tHSPre="${curDoFileHS_A[$j]}"
            preStr=$(sed -n "/^${tHSPre}\s\+/p" ${tmpFileBak})
            tstr=$(echo "${preStr}"|sed  "s/^[0-9]\{2\}:[0-9]\{2\}/${tHS}/")

            sed -i "/^${tHSPre}\s\+/ a ${tstr}" ${tmpFileBak}
            F_outShDebugMsg "${logFile}" 1 1 "WARNING:${FUNCNAME}:replace time:EC=${tECNo} ${tHSPre} ---> ${tHS}" 

        else #curStr no null

            if [ ${oneLinNullFlag} -eq 1 ];then
                j=$i
                let j--
                for((;j>=0;j--))
                do
                    tstr=$(echo "${curStr}"|sed  "s/^[0-9]\{2\}:[0-9]\{2\}/${curDoFileHS_A[$j]}/")

                    k=${j}
                    let k++
                    sed -i "/^${curDoFileHS_A[$k]}\s\+/ i ${tstr}" ${tmpFileBak}
                    F_outShDebugMsg "${logFile}" 1 1 "WARNING:${FUNCNAME}:replace time:EC=${tECNo} ${curDoFileHS_A[$k]} ---> ${curDoFileHS_A[$j]}" 
                done
                oneLinNullFlag=0
            fi
        fi

    done

    return 0
}

#Generate 30-minute data of a certain wind turbine according to the ec 
#number of the wind turbine and the 1-minute data source file
#
function F_doOneTurbByEcNo()  #根据风机的EC编号对某一个风机进行处理
{
    if [ $# -lt 4 ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:${FUNCNAME} input parameters less than 4!" 2
        return 1
    fi
    local tECNo="$1"
    local doDir="$2"
    local doFiles="$3"
    local tDir="$4"
    local i=0; local tnum=0;
    for((i=0;i<${g_file_nums};i++))
    do
        tnum=$(F_judgeEcInStr "${g_file_ec[$i]}" "${tEcNo}")
        if [ ${tnum} -lt 1 ];then
            continue
        fi
        local tmpFile="${tDir}/tmp_fj_EC_${tECNo}_f${i}.txt"
        local tmpFileBak="${tDir}/tmp_fj_EC_${tECNo}_f${i}.bak"
        
        tnum=0

        egrep -H "^#\s+${tECNo}\s+" "${doDir}/"${doFiles} >"${tmpFile}"
        tnum=$(wc -l "${tmpFile}"|awk '{print $1}')
        if [ ${tnum} -eq 0 ];then
            F_outShDebugMsg "${logFile}" 1 1 "ERROR:${FUNCNAME}:[${curDoRltFileName[$i]}] ${doFiles} FJ EC=${tECNo} nums=${tnum}" 
            return 0
        fi


        #sed -i "s/\(^.*_\)\([0-9][0-9]\)\([0-9][0-9]\)${g_1mi_suffix_domian}:#/\2:\3/g" "${tmpFile}" 
        sed -i "s/\(^.*${g_1mi_joiner_char}\)\([0-9][0-9]\)\([0-9][0-9]\)${g_1mi_suffix_domian}:#/\2:\3/g" "${tmpFile}" 
        sort -n -k 1,1 "${tmpFile}" >"${tmpFileBak}"
        >"${tmpFile}"

        if [ ${tnum} -lt ${need_perEC_items}  ];then
            F_outShDebugMsg "${logFile}" 1 1 "ERROR:${FUNCNAME}:[${curDoRltFileName[$i]}] ${doFiles} FJ EC=${tECNo} nums=${tnum},need_perEC_items=[${need_perEC_items}],g_supp_miss_item=[${g_supp_miss_item}]" 
            if [[ ! -z "${g_supp_miss_item}" && "${g_supp_miss_item}" = "1" ]];then
                F_fillMiss1miItem  "${tDir}" "${tECNo}" "${tmpFileBak}"
            fi
        fi
        
        local rTime;     local rEc;   local  rPwrat; local rPwrreact;
        local rSpd;      local rState;local  rFault;

        local tIdex;     local tID;  local tType;  local tTime;  local tPwrat;
        local tPwrreact; local tSpd; local tState; local tFault; local tnaa

        #       时间  ec编号 有功   无功     风速   状态 故障码
        #      14:00   0   5.123   6.369   2.464   41  16,17
        while read rTime rEc rPwrat rPwrreact rSpd rState rFault
        do
            
            #result file format
            # @INDEX ID TYPE TIME PWRAT PWRREACT SPD STATE FAULT
            # #1 1#FJ HT01 14:30 250.76 -156.00 4.67 2 '(0)'

            tIdex="#${g_file_SerialNo[$i]}"
            tID=$(echo "${rEc} + 1"|bc)"${g_turbn_ID_suffix}"
            tType="${g_turbn_TTYPE[${rEc}]}"
            tTime="${rTime}"
            tPwrat=$(F_getFloatScaleResult ${g_PP_scale} ${rPwrat} ${g_PP_divisor})
            tPwrreact=$(F_getFloatScaleResult ${g_PQ_scale} ${rPwrreact} ${g_PQ_divisor})
            tSpd=$(F_getFloatScaleResult ${g_WS_scale} ${rSpd} ${g_WS_divisor})
            if [ ${rState} -gt ${g_STATE_maxValue} ];then
                #获取的状态值在配置的状态最大值之外则默认用默认状态并写一条错误日志
                F_outShDebugMsg "${logFile}" 1 1 "ERROR:${FUNCNAME}:FJ EC=${tECNo} state=${rState} bigger than cfgMaxState=[${g_STATE_maxValue}]" 
                tState=${g_default_TSTATE}
            else
                tState=${g_turbn_TSTATE[${rState}]}
            fi

            #16,17 ->  (16)(17)
            #rFault=$(echo "${rFault}"|sed 's/\(\s\+0\|0\s\+\)//g')
            #rFault=$(echo "${rFault}"|sed 's/\s\+/,/g')
            #tFault="'("$(echo "${rFault}"|sed 's/\s*,\s*/)(/g')")'"
            #tFault="'("$(echo "${rFault}"|sed 's/\(\s\+0\b\|\b0\s\+\)//g;s/\s\+/,/g;s/\s*,\s*/)(/g')")'"
            #tFault="'("$(echo "${rFault}"|sed 's/\(\s\+0\b\|\b0\s\+\)//g;s/\s\+/^/g;s/\s*^\s*/)(/g')")'"
            tFault="'("$(echo "${rFault}"|sed "s/\(\s\+0\b\|\b0\s\+\)//g;s/\s\+/${g_1mi_fixCnt_FaultJinChar}/g;s/\s*${g_1mi_fixCnt_FaultJinChar}\s*/)(/g")")'"

            echo "${tIdex} ${tID} ${tType} ${tTime} ${tPwrat} ${tPwrreact} ${tSpd} ${tState} ${tFault}"|sed 's/\s\+/ /g' >>"${tmpFile}"

            let g_file_SerialNo[$i]++

        done<"${tmpFileBak}"
    done

    return 0
}


#30 data files of 1 minute for a single fan, replace the files with the 
#latest time if they are insufficient
#
function F_fillMiss1miFile()
{
    local i=0;             local j=0;
    local tFile
    local zeroPosNullFlag=0

    for((i=0;i<30;i++))
    do
        tFile="${doSrcDir}/${curDoFile_A[$i]}"
        if [ -f "${tFile}" ];then
            if [ ${zeroPosNullFlag} -eq 1 ];then
                j=$i
                let j--
                for((;j>=0;j--))
                do
                    cp ${tFile} "${doSrcDir}/${curDoFile_A[$j]}"
                    F_outShDebugMsg "${logFile}" 1 1 "WARNING:${FUNCNAME}:replace file: cp ${tFile} ${doSrcDir}/${curDoFile_A[$j]}" 
                done
                zeroPosNullFlag=0
            fi
            continue
        else
            if [ ${i} -eq 0 ];then
                zeroPosNullFlag=1
                continue
            fi
            if [ ${zeroPosNullFlag} -eq 1 ];then
                continue
            fi

            j=$i
            let j--
            cp "${doSrcDir}/${curDoFile_A[$j]}" "${tFile}"
            F_outShDebugMsg "${logFile}" 1 1 "WARNING:${FUNCNAME}:replace file: cp ${doSrcDir}/${curDoFile_A[$j]} ${tFile}" 
        fi
    done

    return 0
}


#Generate a 30-minute result file according to the configuration of the 
#configuration file and the 1-minute data source file
#
function F_doTurb() #处理所有风机的数据
{
    F_genRltFileFixHT
    #F_genFileNames

    #g_file_SerialNo=1 #初始化上传文件的开始序号

    F_outShDebugMsg "${logFile}" ${g_debugL_value} 1 "${FUNCNAME}:g_1mi_src_dir=[${g_1mi_src_dir}],curDoFiles=[${curDoFiles}]"
    F_outShDebugMsg "${logFile}" ${g_debugL_value} 1 "${FUNCNAME}:g_1mi_basicCondition_num=[${g_1mi_basicCondition_num}],need_perEC_items=[${need_perEC_items}]"

    local k=0
    for((k=0;k<${g_file_nums};k++))
    do
        F_outShDebugMsg "${logFile}" ${g_debugL_value} 1 "${FUNCNAME}:g_dst_result_dir[$k]=[${g_dst_result_dir[$k]}],curDoRltFileName[$k]=[${curDoRltFileName[$k]}],g_file_ec[$k]=[${g_file_ec[$K]}]"
        tRFileR[$k]="${g_dst_result_dir[$k]}/${curDoRltFileName[$k]}"
        tRFile[$k]="${doSrcDir}/${curDoRltFileName[$k]}"

        echo "${resultHeadStr}">"${tRFile[$k]}"
        echo "${g_upfile_fixCnt_itemH}">>"${tRFile[$k]}"

    done

    
    local tnum=0
    tnum=$(ls -1 "${doSrcDir}/"${curDoFiles} 2>/dev/null|wc -l)
    if [ ${tnum} -gt 0 ];then
        rm -rf "${doSrcDir}/"${curDoFiles}
    fi

    local fillFlag=0

    tnum=$(ls -1 "${g_1mi_src_dir}/"${curDoFiles} 2>/dev/null|wc -l)
    if [ ${tnum} -lt ${g_1mi_basicCondition_num} ];then
        F_outShDebugMsg "${logFile}" 1 1 "ERROR:${FUNCNAME}:${g_1mi_src_dir}/${curDoFiles} files ${tnum} less than ${g_1mi_basicCondition_num},g_supp_miss_file=[${g_supp_miss_file}]!" 0
        if [[ ! -z "${g_supp_miss_file}" && "${g_supp_miss_file}" = "1" && ${tnum} -gt 0 ]];then
            fillFlag=1
        else
            return 1
        fi
    fi

    cp -a "${g_1mi_src_dir}/"${curDoFiles} "${doSrcDir}"
    if [ ${fillFlag} -eq 1 ];then
            F_fillMiss1miFile
    fi


    local tEcNo=0; local tmpFile; local retstat=0

    local tMaxEc=$(echo "${g_turbn_num} -1"|bc)

    for((tEcNo=0;tEcNo<${g_turbn_num};tEcNo++))
    do
        tnum=$(F_judgeEcInStr "${g_turbn_exception_ec}" "${tEcNo}")
        if [ ${tnum} -gt 0 ];then
            F_outShDebugMsg "${logFile}" ${g_debugL_value} 1 "WARNING:${FUNCNAME}:Ec=[${tEcNo}] In the configuration exception,not to do----"
            continue
        fi

        #if [ ! -z "${g_turbn_exception_ec}" ];then
        #    tnum=$(echo "${g_turbn_exception_ec}"|sed -n "/\b${tEcNo}\b/p"|wc -l)
        #    if [ ${tnum} -gt 0 ];then
        #        F_outShDebugMsg "${logFile}" ${g_debugL_value} 1 "WARNING:${FUNCNAME}:Ec=[${tEcNo}] In the configuration exception,not to do----"
        #        continue
        #    fi
        #fi

        F_doOneTurbByEcNo ${tEcNo} "${doSrcDir}" "${curDoFiles}" "${tmpDir}"

        for((k=0;k<${g_file_nums};k++))
        do
            #判断此Ec在哪些文件中包括
            tnum=$(F_judgeEcInStr "${g_file_ec[$k]}" "${tEcNo}")
            #echo "fusktest:tnum=[${tnum}],g_file_ec[$k]=[${g_file_ec[$k]}],tEcNo=[${tEcNo}]"
            if [ ${tnum} -gt 0 ];then
                if [ ${rltFileHaveDoFlag[$k]} -eq 1 ];then
                    F_outShDebugMsg "${logFile}" ${g_debugL_value} 16 "${FUNCNAME}:doing Ec[${tEcNo}]/${tMaxEc} has been generated in the file [${curDoRltFileName[$k]},and continue----"
                    continue
                fi
            else
                F_outShDebugMsg "${logFile}" ${g_debugL_value} 32 "${FUNCNAME}:doing Ec[${tEcNo}]/${tMaxEc} is not included in file [${curDoRltFileName[$k]}]----"
                continue
            fi

            F_outShDebugMsg "${logFile}" ${g_debugL_value} 16 "${FUNCNAME}:doing Ec[${tEcNo}]/${tMaxEc} to file[${curDoRltFileName[$k]}]----"

            tmpFile="${tmpDir}/tmp_fj_EC_${tEcNo}_f${k}.txt"
            cat "${tmpFile}" >> "${tRFile[$k]}"
        done
    done
    
    for((k=0;k<${g_file_nums};k++))
    do
        if [ ${rltFileHaveDoFlag[$k]} -eq 1 ];then
            continue
        fi
        echo "${resultTailStr}">>"${tRFile[$k]}"

        if [ -e "${tRFileR[$k]}" ];then
            rm -rf "${tRFileR[$k]}"
        fi

        mv "${tRFile[$k]}"  "${g_dst_result_dir[$k]}"
        retstat=$?
        if [ ${retstat} -eq 0 ];then
            F_outShDebugMsg "${logFile}" ${g_debugL_value} 1 "${FUNCNAME}:[${g_dst_result_dir[$k]}/${curDoRltFileName[$k]}] do complete!"

            F_writeDoneRecord "${curDoRltFileName[$k]}"
        else
            F_outShDebugMsg "${logFile}" ${g_debugL_value} 1 "${FUNCNAME}:mv ${tRFile[$k]} ${g_dst_result_dir[$k]} return ERROR[${retstat}!"
        fi

    done

    return 0
}

#Delete some expired files according to the configuration of the 
#configuration file
#
function F_delSomeExpireFile()
{
    [ -z "${v_Minute}" ] && return 0

    local trueFlag=0

    #Only perform the delete operation during the 15-25 minute period
    #
    trueFlag=$(echo "${v_Minute} >=15 && ${v_Minute} <=25"|bc)
    [ ${trueFlag} -ne 1 ] && return 0

    F_outShDebugMsg "${logFile}" ${g_debugL_value} 32 "${FUNCNAME}: doing...!"

    #1 minute data source file deletion
    F_delExpir1miFile

    #Delete the generated 30-minute result file
    F_delExpirdstFile

    #Log file deletion
    F_delExpirlogFile "${logDir}"

    local tmpStr="${g_upfile_frmName_domain}${g_upfile_joiner_char}${g_upfile_fanCode_domain}*${g_upfile_suffix_domain}"

    #Temporary directory corresponds to 1 minute file deletion
    #F_rmExpiredFile "${doSrcDir}" "${dosrc_delExpirDays}" "${tmpStr}"
    F_rmExpiredFile "${doSrcDir}" "${dosrc_delExpirDays}" "*${g_1mi_suffix_domian}"

    F_outShDebugMsg "${logFile}" ${g_debugL_value} 32 "${FUNCNAME}: do complete!"

    return 0
}

#Test function, abnormal logic
#
function F_printTest()
{
    local i=0
    #for((i=0;i<30;i++))
    #do
    #    echo "curDoFile_A[$i]=[${curDoFile_A[$i]}]"
    #    echo "curDoFileHS_A[$i]=[${curDoFileHS_A[$i]}]"
    #    echo ""
    #done

    #i=$(F_getFloatScaleResult 2 "3.1" )
    #echo "i=[${i}]"

    #for((i=0;i<${g_turbn_num};i++))
    #do
    #    echo "g_turbn_TTYPE[$i]=${g_turbn_TTYPE[$i]}"
    #done

    #echo -e "\n"
    #for((i=0;i<=${g_STATE_maxValue};i++))
    #do
    #    echo "g_turbn_TSTATE[$i]=${g_turbn_TSTATE[$i]}"

    #done

    #F_genFileNames
    #echo "curDoFiles=[${curDoFiles}]"
    #ls -l "${g_1mi_src_dir}/"${curDoFiles}
    #echo "curDoRltFileName=[${curDoRltFileName}]"

    #echo "g_upfile_fixCnt_itemH=[${g_upfile_fixCnt_itemH}]"

    #F_fuskytest

    F_check
    F_init
    echo "g_file_nums=[${g_file_nums}]"
    for((i=0;i<${g_file_nums};i++))
    do
        echo "g_dst_result_dir[$i]=[${g_dst_result_dir[$i]}]"
        echo "g_upfile_frmName_domain[$i]=[${g_upfile_frmName_domain[$i]}]"
        echo "g_upfile_fanCode_domain[$i]=[${g_upfile_fanCode_domain[$i]}]"
        echo "g_upfile_suffix_domain[$i]=[${g_upfile_suffix_domain[$i]}]"
        echo "g_upfile_joiner_char[$i]=[${g_upfile_joiner_char[$i]}]"
        echo "g_file_ec[$i]=[${g_file_ec[$i]}]"

    done


    return 0
}


#Main function logic
main()  
{
    local bgScds=$(date +%s)
    local retstat=0

    #F_printTest
    #return 0

    F_check
    F_init
    F_delSomeExpireFile

    F_genFileNames

    F_judgeHaveDone
    retstat=$?
    if [ ${retstat} -eq 1 ];then #have done;then exit
        
        F_outShDebugMsg "${logFile}" ${g_debugL_value} 32 "The [${curDoRltFileName}] file has been processed before, so exit directly! "
        exit 0
    fi

    F_doTurb
    retstat=$?

    #F_printTest
    #return 0

    if [ ${retstat} -eq 0 ];then

        local edScds=$(date +%s)
        local diffScds=$(echo "${edScds} - ${bgScds}"|bc)
        F_outShDebugMsg "${logFile}" ${g_debugL_value} 1 "The program runs a total of [ ${diffScds} ] seconds"
        F_outShDebugMsg "${logFile}" ${g_debugL_value} 1 "" 3
    fi

    return 0
}

main

exit 0



