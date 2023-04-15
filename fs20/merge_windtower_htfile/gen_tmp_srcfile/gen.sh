#!/bin/bash
#
################################################################################
#
#author:fushikai
#date  :2023-04-13_18:06:06
#desc  :用此脚本生成mergeWtHtFile.sh脚本需要的测风塔源文件（模拟真实环境的文件)
#
#Precondition :
#       1. 确认要生成的文件名或文件格式是不是想要的，如果不是需要对此脚本作少量修改
#       2. 需要在此脚本的mode目录放对应的模板文件,然后修改此脚本定义模板文件的地方
#       3. 模板文件格式需要满足mode/JSDLFD_20110614_1930_CFT.WPD文件,因为此脚本开发
#          是以此文件的格式开发
#
# usage like:  
#         ./$0 <YYYMMDDHHMI> <时间频度> <文件个数>
#  如:  
#     ./$0 202304131810 5 10
#     表示生成从2023-04-13_18:10开始每5分钟一个文件,生成10个文件
#
#
################################################################################
#


thisShName="$0"
onlyShName=${thisShName##*/}
onlyShPre=${onlyShName%.*}

function F_help()
{
    echo -e "\n  please input like:"
    echo -e "\n\t${onlyShName} <YYYMMDDHHMI> <时间频度> <文件个数>"
    echo -e "\n\t  参数含义:"
    echo -e "\t\t YYYYMMDD : eg: 202304131810"
    echo -e "\t\t 时间频度 : eg: 5"
    echo -e "\t\t 文件个数 : eg: 10"
    echo -e "\t\t 表示生成从2023-04-13_18:10开始每5分钟一个文件,生成10个文件"
    echo -e "\n"
    return 0
}

if [ $# -lt 3 ];then
    F_help
    exit 0
fi


##################################################
#Define the files and paths required by the script
##################################################
runDir="$(dirname ${thisShName})"

modeFile="${runDir}/mode/JSDLFD_20110614_1930_CFT.WPD"
resultDir="${runDir}/result"

filePrefix="JSDLFD"  #生成文件的前缀:定义默认值，后面再修改
fileSufix="CFT.WPD"  #生成文件的后缀:定义默认值，后面再修改




begineTm="$1" #YYYYMMDDHHMI 开始时间
timeReq="$2"  #时间频度
fileNum="$3" #文件个数 

firLineTime=""  #结果文件第一行的时间形如:2023-04-13_18:54:00
scdLineTime=""  #结果文件第二行的时间形如:2023-04-13_18:54
fileNameTime="" #结果文件名中的时间形如:20230413_1854

tmpTime="" #时间转换的中间时间格式为:"2023-04-13 19:04:00"




function F_getFileName() #get the file name in the path string
{
    [ $# -ne 1 ] && return 0
    [  -z "$1" ] && return 0
    echo "${1##*/}" && return 0
}

#根据模板文件名取得文件前缀和后缀
function F_genFilePrefixSufix()
{
    local tfile=$(F_getFileName "${modeFile}")
    filePrefix=$(echo "${tfile}"|cut -d '_' -f 1)
    fileSufix=$(echo "${tfile}"|awk -F'_' '{print $NF}')
}

function F_convToUtf8()
{
    [ $# -ne 1 ] && return 1
    local tfile="$1"
    [ ! -f "${tfile}" ] && return 2

    local tcharset=$(file --mime-encoding ${tfile} |awk  '{print $2}')
    tcharset="${tcharset%%-*}" 
    if [ "${tcharset}" == "iso" ];then
        local tutffile="${tfile}_utf8"
        iconv -f gbk -t utf8 "${tfile}" -o "${tutffile}"
        if [ $? -eq 0 ];then
            mv "${tutffile}" "${tfile}"
        fi
    fi

    local tnum=$(sed -n '//{p;q}' "${tfile}"|wc -l)
    if [ ${tnum} -gt 0 ];then
        sed -i 's///g' "${tfile}"
    fi
}

function F_isDigital() # return 1: digital; 0: not a digital
{
    [ $# -ne 1 ] && echo "0" && return 0

    if [ $(echo "$1"|sed -n '/\(^[0-9]$\|^[1-9][0-9]\+$\)/p'|wc -l) -gt 0 ];then 
        echo "1" && return 1
    fi

    echo "0" && return 0
}

function F_check()
{
    if [ ! -f "${modeFile}" ];then
        echo -e "\n\tERROR:file [${modeFile}] not exist!"
        exit 1
    fi

    [ ! -d "${resultDir}" ] && mkdir -p "${resultDir}"

    if [[ -z "${begineTm}" || ${#begineTm} -ne 12 ]];then
        F_help
        exit 0
    fi
    if [ $(F_isDigital "$begineTm") = "0" ];then
        F_help
        exit 0
    fi
    if [ $(F_isDigital "$timeReq") = "0" ];then
        F_help
        exit 0
    fi
    if [ $(F_isDigital "$fileNum") = "0" ];then
        F_help
        exit 0
    fi

    return 0
}

# 将tmpTime的时间格式转换成其他格式并赋值给相应变量
function F_convTmpTime()
{
    # tmpTime format："2023-04-13 19:04:00" 
    [ -z "${tmpTime}" ] && return 1

    # format："2023-04-13_19:04:00" 
    firLineTime=$(date -d "${tmpTime}" "+%F_%T")

    # format："2023-04-13_19:04" 
    scdLineTime="${firLineTime%:*}"

    # format："20230413_1904" 
    fileNameTime=$(date -d "${tmpTime}" "+%Y%m%d_%H%M")
}


#将tmpTime的时间加timeReq分钟后赋值给tmpTime
function F_addTime()
{
    # tmpTime format："2023-04-13 19:04:00" 
    [ -z "${tmpTime}" ] && return 1
    tmpTime=$(date -d "${tmpTime} ${timeReq} minutes" "+%F %T")
}



#取得结果文件前缀
#格式化输入时间等
function F_init()
{
    #根据模板文件名取得文件前缀和后缀
    F_genFilePrefixSufix

    #文件格式转换成utf-8
    F_convToUtf8 "${modeFile}"

    # 转换成格式："20230413 1904" 
    local ttm="${begineTm:0:8} ${begineTm:8:4}"

    # 转换成格式："2023-04-13 19:04:00" 
    tmpTime=$(date -d "${ttm}" "+%F %T")

}


# 将0变成要求精度的0.00 ...
function F_genZeroPointPrecision()
{
    [ $# -ne 1 ] && echo "0" && return 0

    local tscale="$1"
    [ $(F_isDigital "${tscale}") = "0" ] && echo "0" && return 0

    local retStr="0."
    local i=0
    for((i=0;i<${tscale};i++))
    do
        retStr="${retStr}0"
    done

    echo "${retStr}"
    return 0
}


#将类似如下计算值为 
#.123变成0.123 
#-.123变成-0.123
# 0变成0.000
function F_getFloatScaleResult()
{
    [[ $# -ne 2 && $# -ne 3 ]] && return 0

    local tscale tData ret divisor tnum

    tscale="$1" ; tData="$2"

    divisor=1
    [ $# -eq 3 ] && divisor="$3"

    ret=$(echo "scale=${tscale};${tData}/${divisor}"|bc)
    tnum=$(echo "${ret}"|sed -n '/^\./p'|wc -l)
    if [ ${tnum} -gt 0 ];then 
        ret="0${ret}"
    else
        tnum=$(echo "${ret}"|sed -n '/^-\./p'|wc -l)
        if [ ${tnum} -gt 0 ];then
            ret=$(echo "${ret}"|sed 's/^-\./-0./')
        fi
    fi

    if [ "${ret}x" = "0x" ];then
        ret=$(F_genZeroPointPrecision "${tscale}")
    fi

    echo "${ret}"

    return 0
}


#根据tmpTime当前值及模板文件 生成一个结果文件
function F_genOneFile()
{
    if [ $# -ne 1 ];then
        echo -e "ERROR:${LINENO}|${FUNCNAME}|Function input arguments are less than 1!\n"
        exit 1
    fi

    local dstfile="$1"

    >"${dstfile}"

    local tnaa tnum tval tval2 multiplier
    while read tnaa; do
        #echo "${tnaa}"

        tnum=$(echo "${tnaa}"|sed -n '/^\s*#[0-9]\+\s\+/p'|wc -l)
        if [ ${tnum} -gt 0 ];then
            tval=$(echo "${tnaa}"|awk '{print $3}')
            multiplier=$(shuf -i 1-10 -n 1 )
            tval2=$(echo "scale=2;${tval} * ${multiplier}"|bc)
            tval2=$(F_getFloatScaleResult "2" "${tval2}" "5")
            tnaa=$(echo "${tnaa}"|sed "s/${tval}\>/${tval2}/")

            #echo "${tnaa},${tval}"

            echo "${tnaa}" >>"${dstfile}"
            continue
        fi

        tnum=$(echo "${tnaa}"|sed -n '/^\s*\/\//p'|wc -l)
        if [ ${tnum} -gt 0 ];then
            tnaa=$(echo "${tnaa}"|sed "s/[0-9]\+.*[0-9]\b/${firLineTime}/")
            echo "${tnaa}" >>"${dstfile}"
            continue
        fi

        tnum=$(echo "${tnaa}"|sed -n '/^\s*<!/p'|wc -l)
        if [ ${tnum} -gt 0 ];then
            tnaa=$(echo "${tnaa}"|sed "s/time='[0-9]\+[^']\+'/time='${scdLineTime}'/")
            echo "${tnaa}" >>"${dstfile}"
            continue
        fi 

        echo "${tnaa}" >>"${dstfile}"

    done <"${modeFile}"
}

#生成所有目标文件
function F_genAllDstFile()
{
    local i tdstF  tdstPF
    for((i=0;i<${fileNum};i++));do
        [ $i -gt 0 ] && F_addTime
        F_convTmpTime

        tdstF="${filePrefix}_${fileNameTime}_${fileSufix}"
        tdstPF="${resultDir}/${tdstF}"
        echo " gen file [${tdstPF}]"
        F_genOneFile "${tdstPF}"

    done

    if [ $i -gt 0 ];then
        echo -e "\n\tAll files generated!\n"
    fi

}


function F_test()
{
    F_check
    F_init
    #F_convTmpTime
    #echo "tmpTime=[${tmpTime}]"
    #echo "firLineTime=[${firLineTime}]"
    #echo "scdLineTime=[${scdLineTime}]"
    #echo "fileNameTime=[${fileNameTime}]"
    #echo "filePrefix=[${filePrefix}]"
    #echo "fileSufix=[${fileSufix}]"

    #echo "--------------------------"
    #F_addTime
    #F_convTmpTime
    #echo "tmpTime=[${tmpTime}]"
    #echo "firLineTime=[${firLineTime}]"
    #echo "scdLineTime=[${scdLineTime}]"
    #echo "fileNameTime=[${fileNameTime}]"
    #echo "filePrefix=[${filePrefix}]"
    #echo "fileSufix=[${fileSufix}]"
    #F_genOneFile "1"

    #F_genAllDstFile


}



main()
{
    local beginSeds=$(date +%s)

    #F_test
    #return 0

    F_check
    F_init
    F_genAllDstFile

    local endSeds=$(date +%s)
    local diffSeds=$(echo "${endSeds} - ${beginSeds}"|bc)

    echo -e "\n\tIt took [\e[1;31m ${diffSeds}\e[0;m ] seconds in total!\n"

    return 0
}

main

exit 0



