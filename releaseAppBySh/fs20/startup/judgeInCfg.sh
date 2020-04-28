#!/bin/sh
#############################################################################
#author       :    fushikai
#date         :    20181210
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Determine whether a program name xxxx(input) exists the configuration file
#    
#
#############################################################################

baseDir=$(dirname $0)

function permfileRW()
{
	if [ $# -ne 1 ];then
		return 1
	fi

	fileName=$1
	if [ ! -f "${fileName}" ];then
		return 2
	fi
	if [ ! -r  "${fileName}" ];then
		return 3
	fi
	if [ ! -w  "${fileName}" ];then
		return 4
	fi

	return 0
}

function permfileR()
{
	if [ $# -ne 1 ];then
		return 1
	fi

	fileName=$1
	if [ ! -f "${fileName}" ];then
		return 2
	fi
	if [ ! -r  "${fileName}" ];then
		return 3
	fi

	return 0
}

function formatFile()
{
	if [ $# -ne 1 ];then
		return 1
	fi

	fileName=$1
	permfileRW ${fileName}
	retstat=$?
	if [ ${retstat} -ne 0 ];then
		return ${retstat}
	fi

	begineNum=$(sed -n "/\<debugFlag\>[ \t]*=/=" ${fileName}|head -1)
	endNum=$(sed -n "$=" ${fileName})

	if [ -z "${begineNum}" ];then
		return  5
	fi

	# (# )
        tnum=$(sed -n "${begineNum},${endNum}s/#[ \t]\+/#/g"p ${fileName}|wc -l)
        if [ ${tnum} -gt 0 ];then
                sed "${begineNum},${endNum}s/#[ \t]\+/#/g"  -i ${fileName}
        fi
        
	# (^ )
	tnum=$(sed -n "${begineNum},${endNum}s/^[ \t]\+//g"p ${fileName}|wc -l)
        if [ ${tnum} -gt 0 ];then
                sed "${begineNum},${endNum}s/^[ \t]\+//g" -i ${fileName}
        fi
        
        # (^[ )
	tnum=$(sed -n "${begineNum},${endNum}s/^\[[ \t]\+/\[/g"p ${fileName}|wc -l)
        if [ ${tnum} -gt 0 ];then
                sed "${begineNum},${endNum}s/^\[[ \t]\+/\[/g" -i ${fileName}
        fi
        
        # ( ])
        tnum=$(sed -n "${begineNum},${endNum}s/[ \t]\+\]/\]/g"p ${fileName}|wc -l)
        if [ ${tnum} -gt 0 ];then
                sed "${begineNum},${endNum}s/[ \t]\+\]/\]/g" -i ${fileName}
        fi
        
	# (^#[ )
        tnum=$(sed -n "${begineNum},${endNum}s/^#\+\[[ \t]\+/#\[/g"p ${fileName}|wc -l)
        if [ ${tnum} -gt 0 ];then
                sed "${begineNum},${endNum}s/^#\+\[[ \t]\+/#\[/g"  -i ${fileName}
        fi


	return 0

}

function ispFlag()
{
	if [ $# -ne 2 ];then
		echo "0"
		return 1
	fi
	pname=$1
	pfile=$2

	permfileR ${pfile}
	retstat=$?
	if [ ${retstat} -ne 0 ];then
		echo "0"
		return ${retstat}
	fi
	
	tnum=$(grep  "^\[${pname}\]" ${pfile}|wc -l)
	#echo "+++++tnum=[${tnum}],pname[${pname}],pfile[${pfile}]++++"
	echo ${tnum}
	return 0
}

function iscomPFlag()
{
	if [ $# -ne 2 ];then
		echo "0"
		return 1
	fi
	pname=$1
	pfile=$2

	permfileR ${pfile}
	retstat=$?
	if [ ${retstat} -ne 0 ];then
		echo "0"
		return ${retstat}
	fi
	
	tnum=$(grep  -E "^#+\[${pname}\]" ${pfile}|wc -l)
	echo ${tnum}
	return 0
}

function prtFuzzyQueryP()
{
    if [ $# -ne 3 ];then
        echo "Error:input parameters not eq 3!"
        return 0
    fi

    searWord=$1
    searFile=$2

    pMatchFlag=$3
    tcheck=$(echo "${pMatchFlag}"|sed -n "/^[0-9]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && pMatchFlag=0
    
    if [ ! -f "${searFile}" ];then
        echo "Error: file[${searFile}] not exsist!"
        return 0
    fi
    num=$(egrep -i "^\s*#*\s*\[.*${searWord}.*\]" ${searFile} 2>/dev/null|wc -l)
    if [ ${num} -gt 0 -a ${pMatchFlag} -eq 1 ];then
        egrep -i "^\s*#*\s*\[.*${searWord}.*\]" ${searFile}
    fi
    
    return $num
}

if [ $# -ne 1 -a $# -ne 0 ];then
	echo ""
	echo "	input error,the following two methods choose one:"
	echo "		    1.: $0   "
	echo "		    2.: $0   myProgramName"
	echo ""
	exit 1
fi

edzfmdcfg=${baseDir}/rcfg.cfg
edrootcfg=${baseDir}/rcfgRoot.cfg

if [ $# -eq 0 ];then
    prompct1="       
           请输入如下选择项前的数字进行选择需要的操作
                    [1].查询配置文件中所有已经配置的程序名
                    [2].查询某个配置程序的详细配置
                    [3].查询某个配置程序的详细配置。(先输出配置中所有的已配程序供你参考)
                    [4].退出，什么都不做
          你的选择是: "
    #echo "---${prompct1}"


    while ((1))
    do

        read -n 1 -p "${prompct1}" opType

        if [[ ${opType} -ne 1 && ${opType} -ne 2 && ${opType} -ne 3 && ${opType} -ne 4 ]];then
        echo ""
        echo " -----------ERROR---------------------:输入错误，请重新输入:"
            continue
        fi

        break

    done

    [ ${opType} -eq 4 ] && echo "" && exit 0


    if [ ${opType} -eq 1 -o ${opType} -eq 3 ];then
        echo ""
        echo "===================================================================>"
        echo "---文件[${edzfmdcfg}]中的程序名配置如下："
        sed -n "$(sed  -n "/\<debugFlag\>\s*=/=" ${edzfmdcfg}|sed -n '$p'),$ p" ${edzfmdcfg}|sed -n "/^\s*#*\s*\[.*\]/p"
        echo "*******************************"
        echo "*整个配置文件监视总开关配置如下:"
        echo "*******************************"
        sed -n "/^\s*debugFlag\s*=/p" ${edzfmdcfg}
        echo ""    
        echo "***文件[${edrootcfg}]中的程序名配置如下："
        sed -n "$(sed  -n "/\<debugFlag\>\s*=/=" ${edrootcfg}|sed -n '$p'),$ p" ${edrootcfg}|sed -n "/^\s*#*\s*\[.*\]/p"
        echo "*******************************"
        echo "*整个配置文件监视总开关配置如下:"
        echo "*******************************"
        sed -n "/^\s*debugFlag\s*=/p" ${edrootcfg}
        echo ""    
        echo "<==================================================================="
        [ ${opType} -eq 1 ] && exit 0
    fi

    
    prompct2="       
           提示:程序名中不需要带\"[\"或\"]\"
           请输入你要查询的程序名: "
    read -p "${prompct2}" tpname
else
    tpname=$1
fi


formatFile "${edzfmdcfg}"
formatFile "${edrootcfg}"

tzflag=$(ispFlag "${tpname}" "${edzfmdcfg}")
trflag=$(ispFlag "${tpname}" "${edrootcfg}")

comtzflag=$(iscomPFlag "${tpname}" "${edzfmdcfg}")
comtrflag=$(iscomPFlag "${tpname}" "${edrootcfg}")
if [[ ${tzflag} -eq 0 && ${trflag} -eq 0 && ${comtzflag} -eq 0 && ${comtrflag} -eq 0 ]];then
    prtFuzzyQueryP "${tpname}" "${edzfmdcfg}" "0"
    tznum=$?
    prtFuzzyQueryP "${tpname}" "${edrootcfg}" "0"
    trnum=$?
    
    echo ""
    echo "	你要查的的程序名[${tpname}]不存在本程序的任何配置文件中!!!"
    [ ${tznum} -gt 0 -o ${trnum} -gt 0 ] && echo "---------但是---------"
    if [ ${tznum} -gt 0 ];then
        echo "通过模糊查询在[${edzfmdcfg}]配置文件中找到如下程序名供参考:"
        prtFuzzyQueryP "${tpname}" "${edzfmdcfg}" "1"
    fi
    if [ ${trnum} -gt 0 ];then
        [ ${tznum} -gt 0 ] && echo "" && echo "----------------------"
        echo "通过模糊查询在[${edrootcfg}]配置文件中找到如下程序名供参考:"
        prtFuzzyQueryP "${tpname}" "${edrootcfg}" "1"
    fi
    [ ${tznum} -gt 0 -o ${trnum} -gt 0 ] && echo "----------------------" && echo ""
    echo ""
	exit 0
fi

addline=4
minusline=5
dstFile=${edzfmdcfg}

if [ ${tzflag} -gt 0 -o ${trflag} -gt 0 -o ${comtzflag} -gt 0 -o ${comtrflag} -gt 0 ];then
    echo ""
    echo ""
    echo "===================================================================>"
fi

function puttmp()
{
    if [ $# -ne 4 ];then
        echo "error:input parameters not eq 4"
        return 1
    fi
    tnum=$1
    endnum=$2
    edfile=$3
    validStr=$4
	echo ""
	echo "从配置文件[${edfile}]看此程序正处于${validStr}监视状态，配置内容如下:"
	#echo "--------------------------------------------------->>"
	sed -n "${tnum},${endnum}p" ${edfile}
	#echo "<<--------------------------------------------------"
	echo ""
    return 0
}

if [ ${tzflag} -gt 0 ];then
	tnum=$(grep -n "^\[${tpname}\]" ${edzfmdcfg}|awk -F"[:-]" '{print $1}'|head -1)
	endnum=$((${tnum}+${addline}))
    puttmp ${tnum} ${endnum} ${edzfmdcfg} "【有效】"
	dstFile=${edzfmdcfg}
fi

if [ ${trflag} -gt 0 ];then
	tnum=$(grep -n "^\[${tpname}\]" ${edrootcfg}|awk -F"[:-]" '{print $1}'|head -1)
	endnum=$((${tnum}+${addline}))
    puttmp ${tnum} ${endnum} ${edrootcfg} "【有效】"
	dstFile=${edrootcfg}
fi

if [ ${comtrflag} -gt 0 ];then
	tnum=$(grep -E -n "^#+\[${tpname}\]"  ${edrootcfg}|awk -F"[:-]" '{print $1}'|head -1)
	endnum=$((${tnum}+${addline}))
    puttmp ${tnum} ${endnum} ${edrootcfg} "【无效】"
	dstFile=${edrootcfg}
fi

if [ ${comtzflag} -gt 0 ];then
	tnum=$(grep -E -n "^#+\[${tpname}\]"  ${edzfmdcfg}|awk -F"[:-]" '{print $1}'|head -1)
	endnum=$((${tnum}+${addline}))
    puttmp ${tnum} ${endnum} ${edzfmdcfg} "【无效】"
	dstFile=${edzfmdcfg}
fi

tnum=$(sed -n "/^[ \t]*debugFlag[ \t]*=/=" ${dstFile}|wc -l)
if [ ${tnum} -gt 0 ];then
	tnum=$(sed -n "/^[ \t]*debugFlag[ \t]*=/=" ${dstFile}|head -1)
	beginnum=$((${tnum}-${minusline}))
    echo "*********************************************************"
	echo "*【只有程序配置和总开关都有效时，此程序才处于正常监视状态】"
	echo "*配置文件[${dstFile}]中所有程序的【监视总开关】配置如下:"
    echo "*********************************************************"
	sed -n "${beginnum},${tnum}p" ${dstFile}
	echo ""

fi
if [ ${tzflag} -gt 0 -o ${trflag} -gt 0 -o ${comtzflag} -gt 0 -o ${comtrflag} -gt 0 ];then
    echo ""
    echo ""
    echo ""
fi

exit 0

