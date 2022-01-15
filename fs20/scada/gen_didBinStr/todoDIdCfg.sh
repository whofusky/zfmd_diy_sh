#!/bin/bash
#author:fushikai
#date: 2021-12-31_10:11:04
#DSC:生成测风塔和风机的did信息

sdInNum=1
if [ $# -ne ${sdInNum} ];then
    echo -e "\n\t\e[1;31mERROR\e[0m:$0 input parameters not eq \e[1;31m ${sdInNum}\e[0m !\n"
    exit 1
fi


outFile="$1"
basedir="$(dirname $0)"
cfgFile="${basedir}/cfg.cfg"
if [ ! -f "${cfgFile}" ];then
    echo -e "\n\tERROR: file [${cfgFile}] not exist!\n"
    exit 1
fi

. ${cfgFile}

frmTpsMdFile="${basedir}/xml_model/farm_tps.model" #整场tps 模板文件
amtwndMdFile="${basedir}/xml_model/amt_wnd.model"  #测风塔 模板文件
tsstbnMdFile="${basedir}/xml_model/tss_tbn.model"  #风机 模板文件
utfMdFile="${basedir}/xml_model/utf.model"         #超短 模板文件
iasagcMdFile="${basedir}/xml_model/ias_agc.model"  #整场 IAS 和 AGC 模板文件



tCfttmp1="${basedir}/tcft$$_1.txt"
tCfttmp2="${basedir}/tcft$$_2.txt"

function F_rmExistFile() #Delete file if file exists
{
    local tInParNum=1
    local thisFName="${FUNCNAME}"
    if [ ${tInParNum} -gt  $# ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${thisFName} input parameter num less than  [${tInParNum}]!\n"
        return 1
    fi

    local tFile="$1"
    while [ $# -gt 0 ]
    do
        tFile="$1"
        if [ -e "${tFile}" ];then
            #echo "rm -rf \"${tFile}\""
            rm -rf "${tFile}"
        fi
        shift
    done
    return 0
}




trap "F_rmExistFile ${tCfttmp1} ${tCfttmp2};exit" 0 1 2 3 9 11 13 15


function F_genTssRstStr()
{
    if [ -z "${tss_rst_args}" ];then
        echo -e "\n\tERROR:tss_rst_args is  null"
        exit 1
    fi
    tFjSingle=""
    local tmpStr=""
    local varPre="tss_rst_val_"
    local targs
    for targs in ${tss_rst_args[*]}
    do
        tmpStr=$(eval echo '$'"${varPre}${targs}")
        if [ -z "${tmpStr}" ];then
            echo -e "\n\tERROR: var name \"${varPre}${targs}\" not exist in file[${tsstbnMdFile}]\n"
            exit 2
        fi
        #echo -e "${varPre}${targs}=[${tmpStr}]"
        tFjSingle="${tFjSingle}
        ${tmpStr}"
    done

    #echo "${tFjSingle}"

    #exit 2
    return 0
}


function F_genTssAvgStr()
{
    if [ -z "${tss_avg_args}" ];then
        echo -e "\n\tERROR:tss_avg_args is  null"
        exit 1
    fi
    tFjSingleAVG="
    <!--0分钟 数据-->
    "
    local tmpStr=""
    local varPre="tss_avg_val_"
    local targs
    for targs in ${tss_avg_args[*]}
    do
        tmpStr=$(eval echo '$'"${varPre}${targs}")
        if [ -z "${tmpStr}" ];then
            echo -e "\n\tERROR: var name \"${varPre}${targs}\" not exist in file[${tsstbnMdFile}]\n"
            exit 2
        fi
        #echo -e "${varPre}${targs}=[${tmpStr}]"
        tFjSingleAVG="${tFjSingleAVG}
        ${tmpStr}"
    done

    #echo "${tFjSingleAVG}"

    #exit 2
    return 0
}

function F_chkAndLoad()
{   
    if [[ "x${have_amt_wnd}" != "x1" && "x${have_tss_tbn}" != "x1" &&  "x${have_frm_tps}" != "x1" &&  "x${have_ias_agc}" != "x1" &&  "x${have_utf}" != "x1" ]];then
        echo -e "\n\tERROR: have_** flag in file [${cfgFile}] value is error!\n"
        exit 2
    fi

    #是否有测风塔的数据1: 有; 其他值没有
    if [ "x${have_amt_wnd}" = "x1" ];then
        if [ ! -f "${amtwndMdFile}" ];then
            echo -e "\n\tERROR: file [${amtwndMdFile}] not exist!\n"
            exit 2
        fi
        . ${amtwndMdFile}
        #0m层高非1分钟共有的实时数据
        tCf0mNo1TmRsData=$(echo "${tCf0mNo1TmRsData}"|sed "s/cft_name_place/${tCfName}/g")

        #特殊层高非1分钟特有的实时数据
        tCfSpmSpN1TmRsData=$(echo "${tCfSpmSpN1TmRsData}"|sed "s/cft_name_place/${tCfName}/g")
        if [ ! -z "${wsyHvalue}" ];then
            tCfSpmSpN1TmRsData=$(echo "${tCfSpmSpN1TmRsData}"|sed -e "s/hvalue=\"[^\"]*\"/hvalue=\"${wsyHvalue}\"/g" -e "s/\b10m\b/${wsyHvalue}m/g")
        fi

        #0m层高共有的1分钟数据
        tCf0mData=$(echo "${tCf0mData}"|sed "s/cft_name_place/${tCfName}/g")


        #0m层高共有的x分钟平均数据
        tCf0mAvgData=$(echo "${tCf0mAvgData}"|sed "s/cft_name_place/${tCfName}/g")

        #0m层高共有的非1分钟统计数据(除平均值之外的值)
        tCf0mNo1MiSticData=$(echo "${tCf0mNo1MiSticData}"|sed "s/cft_name_place/${tCfName}/g")

        #电池电压x分钟值
        tCfDyMinAvg=$(echo "${tCfDyMinAvg}"|sed "s/cft_name_place/${tCfName}/g")

        #温湿压非统计数据
        tCfWSYData=$(echo "${tCfWSYData}"|sed "s/cft_name_place/${tCfName}/g")
        if [ ! -z "${wsyHvalue}" ];then
            tCfWSYData=$(echo "${tCfWSYData}"|sed -e "s/hvalue=\"[^\"]*\"/hvalue=\"${wsyHvalue}\"/g" -e "s/\b10m\b/${wsyHvalue}m/g")
        fi
        #温湿压平均数据
        tCfWSYAvgData=$(echo "${tCfWSYAvgData}"|sed "s/cft_name_place/${tCfName}/g")
        if [ ! -z "${wsyHvalue}" ];then
            tCfWSYAvgData=$(echo "${tCfWSYAvgData}"|sed -e "s/hvalue=\"[^\"]*\"/hvalue=\"${wsyHvalue}\"/g" -e "s/\b10m\b/${wsyHvalue}m/g")
        fi
        #温湿压非1分钟统计数据
        tCfWSYNo1MiSticData=$(echo "${tCfWSYNo1MiSticData}"|sed "s/cft_name_place/${tCfName}/g")
        if [ ! -z "${wsyHvalue}" ];then
            tCfWSYNo1MiSticData=$(echo "${tCfWSYNo1MiSticData}"|sed -e "s/hvalue=\"[^\"]*\"/hvalue=\"${wsyHvalue}\"/g" -e "s/\b10m\b/${wsyHvalue}m/g")
        fi

    fi

    #是否有风机的数据1: 有; 其他值没有
    if [ "x${have_tss_tbn}" = "x1" ];then
        if [ ! -f "${tsstbnMdFile}" ];then
            echo -e "\n\tERROR: file [${tsstbnMdFile}] not exist!\n"
            exit 2
        fi
        . ${tsstbnMdFile}
        F_genTssRstStr
        F_genTssAvgStr
    fi

    #是否有整场tps的数据1: 有; 其他值没有
    if [ "x${have_frm_tps}" = "x1" ];then
        if [ ! -f "${frmTpsMdFile}" ];then
            echo -e "\n\tERROR: file [${frmTpsMdFile}] not exist!\n"
            exit 2
        fi
        . ${frmTpsMdFile}
    fi

    #是否有整场IAS和AGC的数据1: 有; 其他值没有
    if [ "x${have_ias_agc}" = "x1" ];then
        if [ ! -f "${iasagcMdFile}" ];then
            echo -e "\n\tERROR: file [${iasagcMdFile}] not exist!\n"
            exit 2
        fi
        . ${iasagcMdFile}
    fi

    #是否有超短的数据1: 有; 其他值没有
    if [ "x${have_utf}" = "x1" ];then
        if [ ! -f "${utfMdFile}" ];then
            echo -e "\n\tERROR: file [${utfMdFile}] not exist!\n"
            exit 2
        fi
        . ${utfMdFile}
    fi

    >${outFile}

    return 0
}


#测风塔把0m数据变成x米数据的函数
function F_CftToXmCom()
{

    local sdInNum=2
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi
    local toNO="$1"
    local writeFile="$2"

    echo "${tCf0mData}"|sed -e "s/\b0m\b/${toNO}m/g" -e "s/hvalue=\"0\"/hvalue=\"${toNO}\"/g" >>${writeFile}

    return 0
}

#测风塔生成直采的数据DID
function F_CftGenDirDid()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"

    [ ! -z "${tCfWSYData}" ] && echo "${tCfWSYData}" >> ${writeFile}

    local thgVal
    for thgVal in ${cftHigTypeS[*]}
    do
        F_CftToXmCom "${thgVal}" ${writeFile} 
    done

    #echo "${tCf0mData}"|sed -e "s/\b0m\b/${toNO}m/g" -e "s/hvalue=\"0\"/hvalue=\"${toNO}\"/g" >>${writeFile}

    return 0
}

#测风塔生成x分钟的统计did
function F_CftToXMin()
{

    local sdInNum=2
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi
    #local toNO="$1"
    local toMinu="$1"
    local writeFile="$2"

    local thgVal

    [ ! -z "${tCfDyMinAvg}" ] && echo "${tCfDyMinAvg}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" >>${writeFile}


    if [ "${toMinu}" == "1" ];then
        for thgVal in ${cftHigTypeS[*]}
        do
            echo "${tCf0mAvgData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g"  -e "s/\b0m\b/${thgVal}m/g" -e "s/hvalue=\"0\"/hvalue=\"${thgVal}\"/g">>${writeFile}
            if [ ${thgVal} -eq 10 ];then
                echo "${tCfWSYAvgData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" >>${writeFile}
            fi
        done

    else
        for thgVal in ${cftHigTypeS[*]}
        do
            echo "${tCf0mAvgData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g"  -e "s/\b0m\b/${thgVal}m/g" -e "s/hvalue=\"0\"/hvalue=\"${thgVal}\"/g">>${writeFile}
            echo "${tCf0mNo1MiSticData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g"  -e "s/\b0m\b/${thgVal}m/g" -e "s/hvalue=\"0\"/hvalue=\"${thgVal}\"/g">>${writeFile}
            
            if [ ${thgVal} -eq 10 ];then
                echo "${tCfWSYAvgData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" >>${writeFile}
                echo "${tCfWSYNo1MiSticData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" >>${writeFile}
            fi
        done
    fi


    return 0
}

#测风塔生成1 5 15 分钟的统计 数据DID
function F_CftGenStaticDid()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"
    local tMinTy

    for tMinTy in ${cftMinTypeS[*]}
    do
        F_CftToXMin "${tMinTy}" "${writeFile}"
    done

    return 0
}


function F_FjToX()
{

    local sdInNum=2
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi
    local toNO="$1"

    if [ ${toNO} -lt 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} fei ji no less than 1  toNO=[${toNO}]!\n"
        exit 1
    fi

    local toCodeNo=$(echo "${toNO} - 1"|bc)

    local writeFile="$2"

    echo "${tFjSingle}"|sed -e "s/风机0/风机${toNO}/g" -e "s/ecsn=\"0\"/ecsn=\"${toCodeNo}\"/g" >>${writeFile}


    return 0
}


function F_FjToXAVG()
{

    local sdInNum=3
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi
    local toNO="$1"

    if [ ${toNO} -lt 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} fei ji no less than 1  toNO=[${toNO}]!\n"
        exit 1
    fi

    local toCodeNo=$(echo "${toNO} - 1"|bc)

    local writeFile="$2"
    local toMinu="$3"

    echo "${tFjSingleAVG}"|sed -e "s/风机0/风机${toNO}/g" -e "s/0分钟/${toMinu}分钟/g" -e "s/ecsn=\"0\"/ecsn=\"${toCodeNo}\"/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" >>${writeFile}
    #echo "${tFjSingleAVG}"|sed -e "s/风机0/风机${toNO}/g" -e "s/0分钟/${toMinu}分钟/g" -e "s/ecsn=\"0\"/ecsn=\"${toNO}\"/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" 


    return 0
}



# tps数据DID
function F_TpsDid()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"

    [ ! -z "${tTpsTp1Min}" ] && echo "${tTpsTp1Min}" >> ${writeFile}
    [ ! -z "${tTpsVp1Min}" ] && echo "${tTpsVp1Min}" >> ${writeFile}
    [ ! -z "${tTpsBp1Min}" ] && echo "${tTpsBp1Min}" >> ${writeFile}
    [ ! -z "${tTpsPp1Min}" ] && echo "${tTpsPp1Min}" >> ${writeFile}
    [ ! -z "${tTpsCp1Min}" ] && echo "${tTpsCp1Min}" >> ${writeFile}
    [ ! -z "${tTpsWs1Min}" ] && echo "${tTpsWs1Min}" >> ${writeFile}


    return 0
}

#数据DID文件头
function F_DidFileHead()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"

    local tHead='<?xml version="1.0" encoding="gb2312" standalone="no" ?>
<root idNum="1383">

'
    echo "${tHead}" >> ${writeFile}

    return 0
}

#数据DID文件尾
function F_DidFileTail()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"

    local tTail='
</root>

'
    echo "${tTail}" >> ${writeFile}

    return 0
}



# 生成测风塔的did数据
function F_DidGenCftAll()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"

    >"${tCfttmp1}"
    
    #生成 测风塔 的数据
    F_CftGenDirDid "${tCfttmp1}"
    F_CftGenStaticDid "${tCfttmp1}"
    cat "${tCfttmp1}" >>${writeFile}

    #生成 测风塔2 的数据
    local tmpCfName
    local i
    local tEcsn
    if [ ! -z "${cftOther}" ];then
        for i in ${cftOther[*]}
        do
            tmpCfName=$(echo "${tCfName}"|sed "s/1/${i}/g")
            tEcsn=$(echo "${i} - 1"|bc)
            echo "tmpCfName=[${tmpCfName}],tEcsn=[${tEcsn}]"
            cp "${tCfttmp1}" "${tCfttmp2}"
            sed -i -e "s/${tCfName}/${tmpCfName}/g" -e "s/ecsn=\"0\"/ecsn=\"${tEcsn}\"/g" "${tCfttmp2}"
            cat "${tCfttmp2}" >>${writeFile}
        done
    fi

    #if [ ! -z "${tCfName2}" ];then
    #    cp "${tCfttmp1}" "${tCfttmp2}"
    #    sed -i -e "s/${tCfName}/${tCfName2}/g" -e "s/ecsn=\"0\"/ecsn=\"1\"/g" "${tCfttmp2}"
    #    cat "${tCfttmp2}" >>${writeFile}
    #fi


    return 0
}


# 生成测风塔的非1分钟实时值did数据
function F_DidGenOthRsCftAll()
{

    if [ -z "${tCf0mNo1TmRsData}" ];then
        return 0
    fi


    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"
    
    >"${tCfttmp1}"

    local tm
    local ht

    #生成 测风塔 的数据
    for tm in ${cfgMulMinRsTypeS[*]}
    do
        for ht in ${cftHigTypeS[*]}
        do
            echo "${tCf0mNo1TmRsData}"|sed -e "s/0分钟/${tm}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${tm}\"/g"  -e "s/\b0m\b/${ht}m/g" -e "s/hvalue=\"0\"/hvalue=\"${ht}\"/g">>${tCfttmp1}
        done
    done

    #特殊层高的
    for tm in ${cfgMulMinRsTypeS[*]}
    do
        echo "${tCfSpmSpN1TmRsData}"|sed -e "s/0分钟/${tm}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${tm}\"/g"  >>${tCfttmp1}
    done

    cat "${tCfttmp1}" >>${writeFile} 

    #生成 测风塔2 的数据
    local tmpCfName
    local i
    local tEcsn
    if [ ! -z "${cftOther}" ];then
        for i in ${cftOther[*]}
        do
            tmpCfName=$(echo "${tCfName}"|sed "s/1/${i}/g")
            tEcsn=$(echo "${i} - 1"|bc)
            echo "tmpCfName=[${tmpCfName}],tEcsn=[${tEcsn}]"

            cp "${tCfttmp1}" "${tCfttmp2}"
            sed -i -e "s/${tCfName}/${tmpCfName}/g" -e "s/ecsn=\"0\"/ecsn=\"${tEcsn}\"/g" "${tCfttmp2}"
            cat "${tCfttmp2}" >>${writeFile}
        done
    fi

    #if [ ! -z "${tCfName2}" ];then
    #    cp "${tCfttmp1}" "${tCfttmp2}"
    #    sed -i -e "s/${tCfName}/${tCfName2}/g" -e "s/ecsn=\"0\"/ecsn=\"1\"/g" "${tCfttmp2}"
    #    cat "${tCfttmp2}" >>${writeFile}
    #fi



    return 0
}



# 生成风机的did数据
function F_DidGenFjAll()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"
    
    local t
    local tMinTye
    
    #瞬时值
    for ((t=${fjBebeinNo};t<=${fjBeEndNo};t++))
    do
        F_FjToX "$t" "${writeFile}"
    done

    #各分钟的数据
    for tMinTye in ${fjMinTypeS[*]}
    do
        #${tMinTye}分钟
        for ((t=${fjBebeinNo};t<=${fjBeEndNo};t++))
        do
            #echo " $t ${writeFile} ${tMinTye}"
            F_FjToXAVG "$t" "${writeFile}" "${tMinTye}"
        done
    done

    return 0
}




function F_prtfindKeyVal()
{
    local inNum=2
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    
    local tKey="$1"
    local tmpStr="$2"
    
    #echo -e "${tmpStr}"|awk -F'[= "]'  '{for(i=1;i<=NF;i++){if($i ~/'${tKey}'/ ){print $(i+2);break;} }}'
    #tDidName=$(sed -n "${tDidLinNo} p" ${tcfgFile}|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/(name|didName)/){print $(i+1);break;}}}')
    #echo -e "${tmpStr}"|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/\<'${tKey}'\>/){print $(i+1);break;}}}'
    echo -e "${tmpStr}"|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/ +'${tKey}'\s*=/){print $(i+1);break;}}}'

    return 0
}


function F_setFixLinKeyVal()
{
    local inNum=4
    local thisFName="${FUNCNAME}"
    if [ $# -lt ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num less than ${inNum}!\n"
        return 1
    fi
    
    local tLine="$1"
    local tKey="$2"
    local tVal="$3"
    local tEdFile="$4"
    if [ $# -gt 4 ];then
        local proCont="$5"
    fi

    if [ ! -e "${tEdFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in function ${thisFName} edit file [${tEdFile}] not exist!\n"
        return 2
    fi

    local tmpStr=$(sed -n "${tLine} {p;q}" ${tEdFile})
    local tOldVal=$(F_prtfindKeyVal "${tKey}" "${tmpStr}")

    if [ "${tOldVal}" == "${tVal}" ];then
        #echo "[${tOldVal}] eq [${tVal}]"
        return 0
    fi

    #tmpStr=$(echo "${tmpStr}"|sed -e 's///g' -e 's/^\s\+//g')
    #echo -e "line[${LINENO}]:file:[${tEdFile}] \e[1;31m${proCont}\e[0m line:[${tLine}] content:[${tmpStr}] ,modify [\e[1;31m${tKey}\e[0m]'s value [\e[1;31m${tOldVal}\e[0m] to [\e[1;31m${tVal}\e[0m]  "

    sed -i "${tLine} s/\b${tKey}\b\s*=\s*\"[^\"]*\"/${tKey}=\"${tVal}\"/g" ${tEdFile}
    

    return 0
}

function F_doSomeFormat()
{
    tLinNum=$(sed -n '/^\s*<\s*\bdataId\b/p' ${outFile}|wc -l)
    tBgTm=$(date +%s)
    echo -e "\n\t====================remove spaces in didName in file [${outFile}]=============================begin"
    i=0
    j=0
    k=0
    t=0
    loopTm[0]=${tBgTm}
    loopTm[1]=${tBgTm}
    sed -n '/^\s*<\s*dataId\b/=' ${outFile}|while read tnaa
    do
        let i++
        #if [ $(echo "$i % 100"|bc) -eq 0 ];then
        #    k=$(echo "$j % 2"|bc)
        #    let j++
        #    t=$(echo "$j % 2"|bc)
        #    loopTm[${t}]=$(date +%s)
        #    tLpDfTm=$(echo "${loopTm[${t}]} - ${loopTm[${k}]}"|bc)
        #    echo "----do lines:[${i}/${tLinNum}]---elapsed[${tLpDfTm}]seconds"
        #fi
        printf "\r----do lines:[%d/%d]" ${i} ${tLinNum}
        tmpStrstr=$(sed -n "${tnaa} {p;q}" ${outFile})
        didName=$(F_prtfindKeyVal "name" "${tmpStrstr}")
        didName=$(echo "${didName}"|sed 's/\s\+//g')
        F_setFixLinKeyVal "${tnaa}" "name" "${didName}" "${outFile}" "delete name s blank char"
    done
        echo -e "\n----do lines:[${tLinNum}]---"
        tEdTm=$(date +%s)
        tRTm=$(echo "${tEdTm} - ${tBgTm}"|bc) 
        echo -e "\n\tremove spaces elapsed time [\e[1;31m${tRTm}\e[0m] seconds"
    echo -e "\t====================remove spaces in didName in file [${outFile}]=============================end\n"


    #tLinNum=$(sed -n '/^\s*<\s*\bdataId\b/p' ${outFile}|wc -l)
    #echo "----tLinNum=${tLinNum}----"

    sed -i "/^\s*<\s*root\b/{s/idNum\s*=\s*\"[^\"]*\"/idNum=\"${tLinNum}\"/g}" "${outFile}" 

    return 0
}

function main()
{

    F_chkAndLoad

    #数据DID文件头
    F_DidFileHead "${outFile}"

    #是否有测风塔的数据1: 有; 其他值没有
    if [ "x${have_amt_wnd}" = "x1" ];then
        # 生成测风塔的did数据
        F_DidGenCftAll "${outFile}"
    fi

    #是否有风机的数据1: 有; 其他值没有
    if [ "x${have_tss_tbn}" = "x1" ];then
        # 生成风机的did数据
        F_DidGenFjAll "${outFile}"
    fi

    #是否有超短的数据1: 有; 其他值没有
    if [ "x${have_utf}" = "x1" ];then
        [ ! -z "${tUPSAbout}" ] && echo "${tUPSAbout}" >> ${outFile}
    fi

    #是否有整场IAS和AGC的数据1: 有; 其他值没有
    if [ "x${have_ias_agc}" = "x1" ];then
        [ ! -z "${tFarmAbout}" ] && echo "${tFarmAbout}" >> ${outFile}
    fi

    #是否有整场tps的数据1: 有; 其他值没有
    if [ "x${have_frm_tps}" = "x1" ];then
        # tps数据DID
        F_TpsDid "${outFile}"
    fi

    #是否有测风塔的数据1: 有; 其他值没有
    if [ "x${have_amt_wnd}" = "x1" ];then
        # 非1分钟实时值数据DID
        F_DidGenOthRsCftAll "${outFile}"
    fi

    #数据DID文件尾
    F_DidFileTail "${outFile}" 

    F_doSomeFormat

    return 0
}

main

exit 0

