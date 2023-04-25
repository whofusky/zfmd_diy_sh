#!/bin/bash
#
################################################################################
#
#author: fushikai
#date  : 2023-04-14_13:21:23
#desc  : 根据特殊格式的测风塔文件,按测风塔编号和屋高分类生成结果文件
#
#Precondition :
#       1. 在脚本的同级目录下有配置文件cfg/cfg.cfg，且配置文件已经按要求配置完成
#
#       2. 源文件需要满足如下条件:
#          (1) 文件名最好满足格式：JSDLFD_20110614_1930_CFT.WPD,即
#                                "前缀_时间_后缀"
#          (2) 文件内容同一个文件包含:
#              同一个时刻所有层高采集的数据,
#              且文件第一行内容就为: // 2011-06-14_19:30:00  (即// 时间)
#              层高数据类似如下:
#                    <MastData::0001>
#                    @id   属性项        数值	
#                    #1    WS_10        9.1		
#                    #2    WS_BZC_10        3	
#                    #3    WS_SS_10        9.1	
#                    #4    WS_MAX_10        3	
#                    #5    WD_10        9.1		
#                    #6    WD_SS_10        3		
#                    </MastData::0001>
#              其中属生项中"_线后的数字"表示层高；MastData后的数字代表测风塔编号
#              同一个文件中可以有多个测风塔编号包含的内容;
#       3. 结果文件说明:
#          文件名类似: cft_001_010_20230307-20230307.csv
#                      前缀_测风塔编号_数据层高_开始时间-结束时间 文件后缀
#                      其中开始时间和结束时间到天
#                      文件名只有: 前缀 后缀 可配置
#          文件内容: 将同一个测风塔同一个层高的数据,当天所有时刻的数据合成一起
#                    数据类似如下:
#                    DATE,WS,WD,T,P,H
#                    2023-03-07 00:00,5.134,28,20,1014,69.6
#                    2023-03-07 00:10,5.134,28,20,1014,69.6
#                    2023-03-07 00:20,5.134,28,20,1014,69.6
#                 
#usage like:  
#         #自动根据配置文件配置去找相应的数据合成
#         ./$0  
#
#Deployment method:
#       此脚本运行后是长驻内存的;当配置文件有变动后,脚本会自动再重新加载
#       建议将此脚本配置到自启动软件(脚本）中
#
#
#Version change record:
#     2023-04-11 initial version  v20.01.000
#
################################################################################
#





thisShName="$0"
onlyShName=${thisShName##*/}
onlyShPre=${onlyShName%.*}
[ $# -ge 1 ] && manualEnterDate="$1"
inParNum=$#



#设置检测到源文件至少是多少秒之前修改的才处理
v_srcModifySecs=8

###############################################
#Load system environment variable configuration
###############################################
 [ -f /etc/profile ] && . /etc/profile >/dev/null 2>&1
 [ -f ${HOME}/.bash_profile ] && . ${HOME}/.bash_profile >/dev/null 2>&1
 [ -f ${HOME}/.profile ] && . ${HOME}/.profile >/dev/null 2>&1




###############################################
# Obtain time dependent variables
###############################################

NOOUT=0 ; levelName[0]="NOOUT";
ERROR=1 ; levelName[1]="ERROR";
INFO=2  ; levelName[2]="INFO" ;
DEBUG=3 ; levelName[3]="DEBUG";


#OUT_LOG_LEVEL=${DEBUG}
OUT_LOG_LEVEL=${INFO}




##################################################
#Define the files and paths required by the script
##################################################
runDir="$(dirname ${thisShName})"

tmpDir="${runDir}/tmp"

logDir="${runDir}/log"
logFile="${logDir}/${onlyShPre}_$(date +%Y%m%d).log"
versionFile="${runDir}/version.txt"

diyFuncFile="${runDir}/myDiyShFunction.sh"
cfgFile="${runDir}/cfg/cfg.cfg"




##################################################
#Define some global variables used by the script
##################################################
v_Minute=$(date +%M)
v_CfgSec=0
v_FuncSec=0
v_havedo=0
v_haveonedo=0




function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!\n"
{

    [ $# -lt 2 ] && return 1

    #特殊调试时用
    local print_to_stdin_flag=0  # 0:可能输出到日志文件; 1: 输出到屏幕; 2可能同时输出到屏幕和日志文件

    #input log level
    local i="${1-3}"   
    

    ##debug to open this
    #[ $(echo "${i}"|sed -n '/^[0-9]*$/p' |wc -l) -eq 0 ] && i=${DEBUG}
    #[ $(echo "${NOOUT}<=${i} && ${i}<=${DEBUG}"|bc) -eq 0 ] && i=${DEBUG}


    [ ${i} -gt ${OUT_LOG_LEVEL:=3} ] && return 0

    local puttxt="$2"

    #echo "fusktest:puttxt=[${puttxt}]"

    # 1.换行符;2.空; 3.多个-;
    # 以上作一情况 则直接输出而不在输出内容之前添加日期等内容
    local tflag=$(echo "${puttxt}"|sed -n '/^\s*\(\(\\n\)\+\)*$\|^\s*-\+$/p'|wc -l)

    #没有设置日志文件时默认也是输出到屏幕
    [ -z "${logFile}" ] && print_to_stdin_flag=1

    local timestring
    local timeSt
    if [ ${tflag} -eq 0 ];then
        timestring="$(date +%F_%T.%N)"
        timeSt="$(date +%T.%N)"
    fi
        

    if [ ${print_to_stdin_flag} -eq 1 ];then
        if [ ${tflag} -gt 0 ];then
            echo -e "${puttxt}"
        else
            echo -e "${timestring}|${levelName[$i]}|${puttxt}"
        fi
        return 0
    fi

    [ -z "${logDir}" ] &&  logDir="${logFile%/*}"
    if [ "${logDir}" = "${logFile}" ];then
        logDir="./"
    elif [ ! -d "${logDir}" ];then
        mkdir -p "${logDir}"
    fi

    if [ ${tflag} -gt 0 ];then
        if [ "${print_to_stdin_flag}x" = "2x" ];then
            echo -e "${puttxt}"|tee -a  "${logFile}"
        else
            echo -e "${puttxt}" >> "${logFile}"
        fi
    else
        if [ "${print_to_stdin_flag}x" = "2x" ];then
            echo -e "${timeSt}|${levelName[$i]}|${puttxt}"
            echo -e "${timestring}|${levelName[$i]}|${puttxt}" >>"${logFile}"
        else
            echo -e "${timestring}|${levelName[$i]}|${puttxt}" >> "${logFile}"
        fi
    fi

    return 0
}


function F_myExit()
{
    F_writeLog "$INFO" "\n"
    F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|[${onlyShName}] Exit normally after receiving the signal!"
    F_writeLog "$INFO" "\n"
    exit 0
}


#locad diy shell functions
function F_loadDiyFun()
{
    local tFuncSec=0; 

    #load sh func
    if [ ! -f ${diyFuncFile} ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|file [${diyFuncFile}] not exits!"
        exit 1
    else
        tFuncSec=$(stat -c %Y ${diyFuncFile})
        if [ "${tFuncSec}" != "${v_FuncSec}" ];then
            v_FuncSec="${tFuncSec}"
            . ${diyFuncFile}

            F_writeLog "$INFO" "\n"
            F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|load ${diyFuncFile}"
            F_writeLog "$INFO" "\n"
        fi
    fi

    return 0
}


#Some checks that the program needs to run
#
function F_check()
{
    logFile="${logDir}/${onlyShPre}_$(date +%Y%m%d).log"
    F_loadDiyFun

    F_mkpDir "${logDir}"

    F_checkSysCmd "bc" "cut"
    F_cfgFileCheck

    return 0
}




#Some initialization operations required for program operation
function F_init()
{
    if [ $(F_isDigital "${g_log_delExpirDays}") = "0" ];then
        g_log_delExpirDays=10
    fi
    if [ $(F_isDigital "${g_tmp_delExpirDays}") = "0" ];then
        g_tmp_delExpirDays=1
    fi
    return 0
}




#Delete some expired files according to the configuration of the 
#configuration file
#
function F_delSomeExpireFile()
{
    ##Only perform the delete operation during the 15-25 minute period
    ##
    #local trueFlag=0
    #[ -z "${v_Minute}" ] && return 0
    #trueFlag=$(echo "${v_Minute} >=15 && ${v_Minute} <=25"|bc)
    #[ ${trueFlag} -ne 1 ] && return 0

    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}| doing...!"

    #Log file deletion
    if [  "${g_log_delExpirDays}x" != "0x" ];then
        F_rmExpiredFile "${logDir}" "${g_log_delExpirDays}" "*.log"
    fi 

    #tmp file deletion
    if [  "${g_tmp_delExpirDays}x" != "0x" ];then
        F_rmExpiredFile "${logDir}" "${tmp_delExpirDays}" "*"
    fi 

    F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}| do complete!"
}




#处理找到的一个源文件
# 需要用到全局变量
#   src_dir src_file src_nodePrefix src_cntAttrItePrefix
#   dst_dir dst_file_prefix dst_file_suffix
#   dst_file_head dst_time_resolution  
#   tmpCurGrpDoDir
function F_doOneSrcFile()
{
    if [ $# -ne 2 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|[${idx}] The number of input parameters is not equal to 2!"
        return 1
    fi
    local idx="$1"
    local curfile="$2"
    if [ ! -f "${curfile}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|[${idx}] file[ ${curfile} ] not exist!"
        return 1
    fi

    local ret

    #去掉当前要处理的源文件路径,获取文件名
    local tCurOnlyFname="$(F_getFileName "${curfile}")"

    local tjdSrcP="${tmpCurGrpDoDir}/src_bak"
    F_mkpDir "${tjdSrcP}"
    local tjdFile="${tjdSrcP}/${tCurOnlyFname}"

    #判断源文件是否处理过(根据文件名判断)
    if [ -f "${tjdFile}" ];then
        F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|[${idx}] file [${curfile}] has been processed before and will not be processed this timei!"
        \mv "${curfile}" "${tjdFile}"
        ret=$?
        F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|[${idx}] mv \"${curfile}\" \"${tjdFile}\" return[$ret]"
        return 0
    fi

    #将要处理的文件移动到备份目录,后面的处理直接从备份目录获取文件名处理
    \mv "${curfile}" "${tjdFile}"
    ret=$?
    F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|[${idx}] mv \"${curfile}\" \"${tjdFile}\" return[$ret]"

    local retStat=0

    #取文件头的时间值,文件第一行的格式形如:
    #// 2011-06-15_19:30:00
    #tFileHeadTime=2011-06-15_19:30:00
    #
    local tFileHeadTime="$(sed -n '/^\s*\/\/\s\+[0-9]\+/{p;q}' "${tjdFile}"|sed 's///g'|awk '{print $2}')"

    ##调用F_splitTimeStr1后生成全局变量及值的格式形如:
    #   varF_date="2011-06-14 19:30"
    #   varF_minute="30"
    #   varF_ymd="20110614"
    F_splitTimeStr1 "${tFileHeadTime}" ; retStat=$?
    if [ ${retStat} -ne 0 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|[${idx}] file[ ${tjdFile} ] The time format [${tFileHeadTime}] of the file header is wrong, should be like[// 2011-06-15_19:30:00]"
        return 1
    fi

    #判断当前文件是否满足配置的时间频度要求
    local matchRes=$(echo "${varF_minute} % ${dst_time_resolution}"|bc 2>/dev/null)
    if [ "x${matchRes}" != "x0" ];then
        F_writeLog "$INFO" "\n"
        F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|[${idx}] file[ ${tjdFile} ] The time [${tFileHeadTime}] The time of this file does not meet the time frequency value [$dst_time_resolution], discard this file\n"
        return 0
    fi

    #用一个临时文件存当前文件的所有测风塔编号
    # 如存储源文件如下结构
    #     <MastData::0001>
    #     <MastData::0002>
    # 中的 
    #     0001
    #     0002
    local tmpCftNoFile="${tmpCurGrpDoDir}/tmp_cft_no_file.txt"  

    sed -n "/^\s*<${src_nodePrefix}[0-9]\+\s*>/p" "${tjdFile}"|sed 's///g'|awk -F'[:>]' '{print $(NF-1)}' >"${tmpCftNoFile}"
    local tnum=$(wc -l "${tmpCftNoFile}"|awk '{print $1}')
    if [ ${tnum} -eq 0 ];then
        F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|[${idx}] file [${tjdFile}] No matching ID!"
        return 1
    fi

    local cftNo  tmpNoCntDir tmpNoCntFile 
    local rstBno gtColNums gtCol1Name tmpcol1File k
    local ttvolval fstColLine fstColAttr
    local tcolidx theight tcoltname tColAllName
    local tline t r rsthtno tflag

    #当前脚本处理结果文件的目录,以便copy到最终目录
    local tmpRstP="${tmpCurGrpDoDir}/dst_bak"
    #当前正在生成的结果文件名(不带路径)
    local tmpRstF
    #当前正在生成的结果文件名(带路径)
    local tmpRstPF

    #rcd_files记录当前处理生成成功的结果文件名
    rcd_files[0]=""
    #记录rcd_files的文件名个数
    local rcdIdx=0

    #按源文件中包含的所有"测风塔编号" ,依次对每个编号包含的数据进行处理
    while read cftNo
    do
        [ -z "${cftNo}" ] && continue

        #根据配置的长度生成结果文件中规定长度的测风塔编号(结果文件名将要用到此值)
        rstBno=$(F_add0InFront "${g_fname_wno_len}" "${cftNo}")

        #tmpNoCntFile文件存储某个编号对应的源数据
        tmpNoCntDir="${tmpCurGrpDoDir}/${cftNo}"
        F_mkpDir "${tmpNoCntDir}"
        tmpNoCntFile="${tmpNoCntDir}/content.txt"

        #根据测风塔编号将源文件某一个编码号的内容写入到
        #  tmp/idx/测风塔编号/content.txt
        #  如tmp/0/0001/content.txt
        sed -n "/^\s*<${src_nodePrefix}${cftNo}\s*>/,/^\s*<\/\s*${src_nodePrefix}${cftNo}\s*>/ p" "${tjdFile}"|sed 's///g' > "${tmpNoCntFile}"

        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|[${idx}] [${tjdFile}]'s cft No [${cftNo}] content to-->${tmpNoCntFile}"

        #获得配置文件中配置的要获取的属性列:个数 第一列名
        gtColNums=$(echo "${src_cntAttrItePrefix}"|awk -F',' '{print NF}')
        gtCol1Name=$(echo "${src_cntAttrItePrefix}"|cut -d ',' -f 1)

        #根据第一列要取值的属性名筛选出当前编号测风塔数据中第一列属性对应所有层高数据入临时文件
        tmpcol1File="${tmpNoCntDir}/col_1.txt"
        sed -n "/^#[0-9]\+\s\+${gtCol1Name}_[0-9]\+\s\+/p" "${tmpNoCntFile}" > "${tmpcol1File}"

        F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|[${idx}] cftNo[${cftNo}] [${tmpNoCntFile}]'s attr [${gtCol1Name}_0-9*] content to-->${tmpcol1File}"

        #循环对第一列属性的所有层高进行处理:
        #  同一层高所有属性值为一行
        #  不同层高的数据对应不同的结果文件
        while read fstColLine
        do
            k=0

            #取出第一列的值
            ttvolval=$(echo "${fstColLine}"|awk '{print $3}')
            g_tmp_colval[$k]="${ttvolval}"

            #第一列第一个层高的属性列名
            fstColAttr=$(echo "${fstColLine}"|awk '{print $2}')
            #取出属性列名中的层高:格式类似 WS_10
            theight=$(echo "${fstColAttr}"|cut -d '_' -f 2)
            let k++

            #根据同层高和其他列的属生名前缀取其他列的值(除了温湿压)
            for((;k<${gtColNums};k++));do
                tcolidx=$(echo "$k +1"|bc)

                #取配置中的其他列(除了第1列之后的)不带层高的属性名
                tcoltname=$(echo "${src_cntAttrItePrefix}"|cut -d ',' -f ${tcolidx})

                #温压湿三种属性不与第一列属列的层高一样,只有有值即可
                if [[ "${tcoltname}x" = "Tx" || "${tcoltname}x" = "Px" || "${tcoltname}x" = "Hx" ]];then
                    ttvolval=$(sed -n "/^#[0-9]\+\s\+${tcoltname}_[0-9]\+\s\+/{p;q}" "${tmpNoCntFile}"|awk '{print $3}')
                    g_tmp_colval[$k]="${ttvolval}"
                else
                    #除了温压湿之外的属性要求层高必须与第1列的属性层高一样
                    #  然后根据属性和层高一起匹配取值
                    tColAllName="${tcoltname}_${theight}"
                    ttvolval=$(sed -n "/^#[0-9]\+\s\+${tColAllName}\s\+/{p;q}" "${tmpNoCntFile}"|awk '{print $3}')
                    g_tmp_colval[$k]="${ttvolval}"
                fi
            done

            #拼接"特定文件 特定测风塔编号 特殊层高"的:一行要显示的内容
            tline="${varF_date}"
            for((r=0;r<$k;r++));do
                tline="${tline},${g_tmp_colval[$r]}"
            done

            #根据配置的长度生成结果文件中规定长度的层高
            rsthtno=$(F_add0InFront "${g_fname_ht_len}" "${theight}")

            #tmpRstF 构成:前缀_测风塔编号_层高_开始日期-结束日期 后缀
            tmpRstF="${dst_file_prefix}_${rstBno}_${rsthtno}_${varF_ymd}-${varF_ymd}${dst_file_suffix}"

            #echo "[$cftNo]:theight[${theight}] file[${tmpRstF}] tline=[${tline}]"


            #将生成的记录插入到结果文件中去
            F_mkpDir "${tmpRstP}"
            tmpRstPF="${tmpRstP}/${tmpRstF}"
            if [ -f "${tmpRstPF}" ];then
                #文件存在则直接将内容插入文件末尾
                echo "${tline}" >> "${tmpRstPF}"
            else
                #文件不存在则将插入文件头再插入当前内容到文件
                echo "${dst_file_head}" > "${tmpRstPF}"
                echo "${tline}" >> "${tmpRstPF}"
                F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|[${idx}] cftNo[${cftNo}] height[${theight}] content[${dst_file_head}] write to[${tmpRstPF}]"
            fi

            F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|[${idx}] cftNo[${cftNo}] height[${theight}] content[${tline}] write to[${tmpRstPF}]"

            #排查是否已经记录过了
            tflag=0
            for((t=0;t<${rcdIdx};t++));do
                if [ "${rcd_files[$t]}" = "${tmpRstPF}" ];then
                    tflag=1
                    break
                fi
            done

            #如果之前没有记录过则记录一条
            if [ ${tflag} -eq 0 ];then
                #将有写入的结果文件名记录下来,以便后面统一拷贝到目标目录
                rcd_files[${rcdIdx}]="${tmpRstPF}"

                F_writeLog "$DEBUG" "${LINENO}|${FUNCNAME}|[${idx}] cftNo[${cftNo}] height[${theight}] fileName[${tmpRstPF}] add to rcd_files[${rcdIdx}]"

                let rcdIdx++
            fi

        #结束某一个编号测风塔的数据处理
        done <"${tmpcol1File}"

    #结束所有编号测风塔的数据处理
    done <"${tmpCftNoFile}"

    #将结果文件拷贝到目标目录
    F_mkpDir "${dst_dir}"
    for((t=0;t<${rcdIdx};t++));do
        F_safeCopy "${rcd_files[$t]}" "${dst_dir}"
        ret=$?
        F_writeLog $INFO "${LINENO}|${FUNCNAME}|[${idx}] Content generated by file[ ${tjdFile} ],[ cp ${rcd_files[$t]} ${dst_dir} ] return[$ret]"
        v_haveonedo=1
    done
}




#根据配置文件的配置,处理所有某一"组"的配置
function F_doOneGrpCfg()
{
    if [ $# -ne 1 ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|The number of input parameters is not equal to 1!"
        return 1
    fi
    local idx="$1"  #配置数据,数组变量的下标


    #注释下面2行代码是为了让变量变为全局的,减少函数之间函数的传递
    #local src_dir src_file src_nodePrefix src_cntAttrItePrefix
    #local dst_dir dst_file_prefix dst_file_suffix 
    #local dst_file_head dst_time_resolution  

    src_dir="${g_src_dir[$idx]}"  
    if [ ! -d "${src_dir}" ];then
        F_writeLog $ERROR "${LINENO}|${FUNCNAME}|[${idx}] directory [${src_dir}] does not exist!"
        return 1
    fi

    src_file="${g_src_file[$idx]}"
    src_nodePrefix="${g_src_nodePrefix[$idx]}" 
    src_cntAttrItePrefix="${g_src_cntAttrItePrefix[$idx]}"
    dst_dir="${g_dst_dir[$idx]}"
    dst_file_prefix="${g_dst_file_prefix[$idx]}"
    dst_file_suffix="${g_dst_file_suffix[$idx]}"
    dst_file_head="${g_dst_file_head[$idx]}"
    dst_time_resolution="${g_dst_time_resolution[$idx]}"

    #全局当前处临时处理文件夹
    tmpCurGrpDoDir="${tmpDir}/${idx}"
    F_mkpDir "${tmpCurGrpDoDir}"

    #当前处理的源目录下满足条件的文件名
    local tmpCurFiles="${tmpCurGrpDoDir}/tmp_cur_dofiles.txt"  

    local tFileNum
    tFileNum=$(ls -1 "${src_dir}"/${src_file} 2>/dev/null|wc -l)
    if [ ${tFileNum} -lt 1 ];then
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|[${idx}] [${src_dir}/${src_file}] number of files is equal to 0"
        return 0
    fi
    ls -1 "${src_dir}"/${src_file} 2>/dev/null|sort -n >"${tmpCurFiles}"

    local tureFlag tnaa
    while read tnaa
    do
        #判断文件修改时间是否在v_srcModifySecs秒之前,如果不是则查找下一文件
        tureFlag=$(F_judgeFileOlderXSec "${tnaa}" "${v_srcModifySecs}")
        [ "${tureFlag}" != "1" ] && continue

        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}|[${idx}] do file [${tnaa}]"
        v_haveonedo=0

        F_doOneSrcFile "${idx}" "${tnaa}"
        [ "x${v_haveonedo}" = "x1" ] && F_writeLog "$INFO" "\n"

        v_havedo=1

    done <"${tmpCurFiles}"

}


#根据配置文件的配置,处理所有"组"的配置
function F_doAllCfgFile()
{
    #如果没有要处理的组则直接退出
    if [ ${g_grp_nums} -lt 1 ];then
        F_writeLog $INFO "${LINENO}|${FUNCNAME}|g_grp_nums=[${g_grp_nums}],exit directly!"
        return 0
    fi

    local i
    for((i=0;i<${g_grp_nums};i++));do

        F_writeLog $DEBUG "\n"
        F_writeLog $DEBUG "${LINENO}|${FUNCNAME}| do grp index[${i}]"
        F_doOneGrpCfg "${i}"
    done

}

#Test function, abnormal logic
#
function F_printTest()
{
    #local t="0100"
    #F_add0InFront 2 "$t"

    #local tfile="JSDLFD_20110614_1931_CFT.WPD"
    #F_splitFnameToSome "${tfile}"
    #echo "1 varF_minute=[${varF_minute}]"
    #echo "1 varF_ymd=[${varF_ymd}]"
    #echo "1 varF_date=[${varF_date}]"

    #local tstr="2012-06-14_19:30"
    #F_splitTimeStr1 "${tstr}"
    #echo "2 varF_minute=[${varF_minute}]"
    #echo "2 varF_ymd=[${varF_ymd}]"
    #echo "2 varF_date=[${varF_date}]"

    #F_safeCopy "/home/fusky/tmp/1/JSDLFD_20110614_1930_CFT.WPD" "/home/fusky/tmp/test/1" "/home/fusky/tmp/test/2"

    return 0
}


trap "F_myExit"  1 2 3 9 11 13 15

#Main function logic
main()  
{
    local bgScds edScds diffScds

    F_loadDiyFun
    F_shHaveRunThenExit "${thisShName}"
    F_check
    F_init
    F_writeVersion "${versionFile}"

    #F_printTest
    #return 0

    while :
    do
        v_havedo=0
        bgScds=$(date +%s)
        F_check
        F_delSomeExpireFile
        F_doAllCfgFile
        if [ "x${v_havedo}" = "x1" ];then
            edScds=$(date +%s)
            diffScds=$(echo "${edScds} - ${bgScds}"|bc)
            F_writeLog "$INFO" "${LINENO}|${FUNCNAME}|The program runs a total of [ ${diffScds} ] seconds"
            F_writeLog "$INFO" "\n"
        fi
        sleep 1
    done
}

main

exit 0



