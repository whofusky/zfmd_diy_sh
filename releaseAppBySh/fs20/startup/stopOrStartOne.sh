#!/bin/sh
#############################################################################
#author       :    fushikai
#date         :    20181210
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    operate the self-starting configuration file(remove monitoring
#       or resume monitoring of the configured program)
#
#############################################################################

baseDir=$(dirname $0)

curUid=$(id -u $(whoami))

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

	permfileRW ${pfile}
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

	permfileRW ${pfile}
	retstat=$?
	if [ ${retstat} -ne 0 ];then
		echo "0"
		return ${retstat}
	fi
	
	tnum=$(grep  -E "^#+\[${pname}\]" ${pfile}|wc -l)
	echo ${tnum}
	return 0
}

function addCom()
{
	if [ $# -ne 2 ];then
		return 1
	fi

	pname=$1
	pfile=$2

	permfileRW ${pfile}
	retstat=$?
	if [ ${retstat} -ne 0 ];then
		return ${retstat}
	fi

	addline=4
	formatFile "${pfile}"
	tflag=$(ispFlag "${pname}" "${pfile}")
	retstat=$?
	#echo "----tflag=[${tflag}]----pname[${pname}],pfile[${pfile}],retstat=[${retstat}]--"
	if [ ${tflag} -gt 0 ];then
		tnum=$(grep -n "^\[${pname}\]" ${pfile}|awk -F"[:-]" '{print $1}'|head -1)
		endnum=$((${tnum}+${addline}))
		echo ""
		echo "------edit [${pfile}]-------bfore:"
		sed -n "${tnum},${endnum}p" ${pfile}
		sed "${tnum},${endnum}s/^/#/g" -i ${pfile}
		echo ""
		echo "------edit [${pfile}]-------end:"
		sed -n "${tnum},${endnum}p" ${pfile}
		echo ""
	fi

	return 0
}

function deleteCom()
{
	if [ $# -ne 2 ];then
		return 1
	fi

	pname=$1
	pfile=$2

	permfileRW ${pfile}
	retstat=$?
	if [ ${retstat} -ne 0 ];then
		return ${retstat}
	fi

	addline=4
	formatFile "${pfile}"
	tflag=$(iscomPFlag "${pname}" "${pfile}")
	if [ ${tflag} -gt 0 ];then
		tnum=$(grep -E -n "^#+\[${pname}\]" ${pfile}|awk -F"[:-]" '{print $1}'|head -1)
		endnum=$((${tnum}+${addline}))
		echo ""
		echo "------edit [${pfile}]-------bfore:"
		sed -n "${tnum},${endnum}p" ${pfile}
		sed "${tnum},${endnum}s/^#\+//g" -i ${pfile}
		echo ""
		echo "------edit [${pfile}]-------end:"
		sed -n "${tnum},${endnum}p" ${pfile}
		echo ""
	fi

	return 0
}

function prtFuzzyQueryP()
{
    if [ $# -ne 4 ];then
        echo "Error:input parameters not eq 4!"
        return 0
    fi

    searWord=$1
    searFile=$2

    pMatchFlag=$3
    tcheck=$(echo "${pMatchFlag}"|sed -n "/^[0-9]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && pMatchFlag=0
    
    matchFlag=$4
    tcheck=$(echo "${matchFlag}"|sed -n "/^[0-9]$/p"|wc -l)
    [ ${tcheck} -eq 0 ] && matchFlag=0

    if [ ! -f "${searFile}" ];then
        echo "Error: file[${searFile}] not exsist!"
        return 0
    fi

    #Calculated num
    if [ ${matchFlag} -eq 1 ];then
        num=$(egrep -i "^\s*\[\s*${searWord}\s*\]" ${searFile} 2>/dev/null|wc -l)
    elif [ ${matchFlag} -eq 2 ];then
        num=$(egrep -i "^\s*#+\s*\[\s*${searWord}\s*\]" ${searFile} 2>/dev/null|wc -l)
    else
        num=$(egrep -i "^\s*#*\s*\[.*${searWord}.*\]" ${searFile} 2>/dev/null|wc -l)
    fi
    
    #print
    if [ ${num} -gt 0 -a ${pMatchFlag} -eq 1 ];then
        if [ ${matchFlag} -eq 1 ];then
            egrep -i "^\s*\[\s*${searWord}\s*\]" ${searFile}
        elif [ ${matchFlag} -eq 2 ];then
            egrep -i "^\s*#+\s*\[\s*${searWord}\s*\]" ${searFile}
        else
            egrep -i "^\s*#*\s*\[.*${searWord}.*\]" ${searFile}
        fi
    fi
    
    return $num
}


prompct1="       
       请输入如下选择项前的数字进行选择需要的操作
                [1].对已经配置的某个程序进行【停止】监视
                [2].对已经配置的某个程序且已经停止监视的程序【恢复】监视
                [4].退出，什么都不做
      你的选择是: "
#echo "---${prompct1}"
while ((1))
do

    read -n 1 -p "${prompct1}" opType

    if [[ ${opType} -ne 1 && ${opType} -ne 2 && ${opType} -ne 4 ]];then
	echo ""
	echo " -----------ERROR---------------------:输入错误，请重新输入:"
        continue
    fi

    break

done

[ ${opType} -eq 4 ] && echo "" && exit 0

edzfmdcfg=${baseDir}/rcfg.cfg
edrootcfg=${baseDir}/rcfgRoot.cfg

opname=""
[ ${opType} -eq 1 ] && opname="【停止监视】"
[ ${opType} -eq 2 ] && opname="【恢复监视】"
prompct2="       
       请输入要${opname}的程序名,或输入数字4退出本次操作: "

function pcfgErrMsg()
{
    if [ $# -lt 1 ];then
        echo "ERROR:input parameters less then 1"
        return 1
    fi

    doFlag=$1
    shift
    
    tmpStr=""
    [ ${doFlag} -eq 0 ] && tmpStr="【没有找到】，"
    [ ${doFlag} -eq 1 ] && tmpStr="【已经停止监视】，"
    [ ${doFlag} -eq 2 ] && tmpStr="【已经在监视中】，"

    echo ""
    echo -n " -------ERROR--------:"
    
    echo -n "你输入的程序"
    if [ $# -gt 0 ];then
        echo -n "在配置文件"
        for cfgName in $@;do
            echo -n "[${cfgName}]"
        done
        echo -n "中"
    fi
    echo -n "${tmpStr}
                 请重新输入(如果要终止输入并退出输入数字[4])
    "
    echo ""
    return 0
}


#echo "---${prompct2}"
while ((1))
do

    read -p "${prompct2}" tpname

    if [[ -z ${tpname} ]];then
	echo ""
	echo " -----------ERROR---------------------:输入错误，请重新输入:"
        continue
    fi

    [ "${tpname}" = "4" ] && echo "" && echo "直接退出成功!" && echo "" && exit 0

	tzflag=-1
	trflag=-1
	tzflagCm=-1
	trflagCm=-1

    tzflag=$(ispFlag "${tpname}" "${edzfmdcfg}")
    tzflagCm=$(iscomPFlag "${tpname}" "${edzfmdcfg}")
    #if [ ${curUid} -eq 0 ];then
        trflag=$(ispFlag "${tpname}" "${edrootcfg}")
		trflagCm=$(iscomPFlag "${tpname}" "${edrootcfg}")
    #fi

    prtFuzzyQueryP "${tpname}" "${edzfmdcfg}" "0" "0"
    tznum0=$?
    prtFuzzyQueryP "${tpname}" "${edzfmdcfg}" "0" "1"
    tznum1=$?
    prtFuzzyQueryP "${tpname}" "${edzfmdcfg}" "0" "2"
    tznum2=$?

    prtFuzzyQueryP "${tpname}" "${edrootcfg}" "0" "0"
    trnum0=$?
    prtFuzzyQueryP "${tpname}" "${edrootcfg}" "0" "1"
    trnum1=$?
    prtFuzzyQueryP "${tpname}" "${edrootcfg}" "0" "2"
    trnum2=$?

    #add cm
	if [ ${opType} -eq 1 ];then
        #root user
        if [ ${curUid} -eq 0 ];then
            if [[ ${tzflag} -eq 0 && ${trflag} -eq 0 && ${trflagCm} -eq 0 && ${tzflagCm} -eq 0 ]];then
                pcfgErrMsg 0 "${edzfmdcfg}" "${edrootcfg}"
                [ ${tznum0} -gt 0 -o ${trnum0} -gt 0 ] && echo "---------但是---------"
                if [ ${tznum0} -gt 0 ];then
                    echo "通过模糊查询在[${edzfmdcfg}]配置文件中找到如下程序名供参考:"
                    prtFuzzyQueryP "${tpname}" "${edzfmdcfg}" "1" "0"
                fi
                if [ ${trnum0} -gt 0 ];then
                    [ ${tznum0} -gt 0 ] && echo "" && echo "----------------------"
                    echo "通过模糊查询在[${edrootcfg}]配置文件中找到如下程序名供参考:"
                    prtFuzzyQueryP "${tpname}" "${edrootcfg}" "1" "0"
                fi
                [ ${tznum0} -gt 0 -o ${trnum0} -gt 0 ] && echo "----------------------" && echo ""

                continue

            elif [ ${trflagCm} -gt 0 ];then
                pcfgErrMsg 1 "${edrootcfg}"
                continue
            elif [ ${tzflagCm} -gt 0 ];then
                pcfgErrMsg 1 "${edzfmdcfg}"
                continue
            fi
        else
            if [[ ${tzflag} -eq 0 && ${tzflagCm} -eq 0 ]];then

                pcfgErrMsg 0 "${edzfmdcfg}"

                [ ${tznum0} -gt 0 -o ${trnum0} -gt 0 ] && echo "---------但是---------"

                if [ ${tznum0} -gt 0 ];then
                    echo "通过模糊查询在[${edzfmdcfg}]配置文件中找到如下程序名供参考:"
                    prtFuzzyQueryP "${tpname}" "${edzfmdcfg}" "1" "0"
                elif [ ${trnum0} -gt 0 ];then
                    if [ ${trnum1} -gt 0 ];then
                        echo "程序名[${tpname}]配置在了[${edrootcfg}]文件中，需要【切换root用户】进行操作"
                        prtFuzzyQueryP "${tpname}" "${edrootcfg}" "1" "1"
                    elif [ ${trnum2} -gt 0 ];then
                        echo "程序名[${tpname}]配置在了[${edrootcfg}]文件中,且已经是【停止监视】状态，"
                        prtFuzzyQueryP "${tpname}" "${edrootcfg}" "1" "2"
                        echo ""
                        echo "如需要对其进行其他操作，需要【切换root用户】进行操作"
                    else
                        echo "通过模糊查询在[${edrootcfg}]配置文件中找到如下程序名供参考:"
                        prtFuzzyQueryP "${tpname}" "${edrootcfg}" "1" "0"
                        echo ""
                        echo "如需要对其进行操作，需要【切换root用户】进行操作"
                    fi
                fi

                [ ${tznum0} -gt 0 -o ${trnum0} -gt 0 ] && echo "----------------------" && echo ""

                continue
            elif [ ${tzflagCm} -gt 0 ];then
                pcfgErrMsg 1 "${edzfmdcfg}"
                continue
            fi
        fi
	else
    #delete cm
        #root user
        if [ ${curUid} -eq 0 ];then
            if [[ ${tzflag} -eq 0 && ${trflag} -eq 0 && ${trflagCm} -eq 0 && ${tzflagCm} -eq 0 ]];then
                pcfgErrMsg 0 "${edzfmdcfg}" "${edrootcfg}"
                [ ${tznum0} -gt 0 -o ${trnum0} -gt 0 ] && echo "---------但是---------"
                if [ ${tznum0} -gt 0 ];then
                    echo "通过模糊查询在[${edzfmdcfg}]配置文件中找到如下程序名供参考:"
                    prtFuzzyQueryP "${tpname}" "${edzfmdcfg}" "1" "0"
                fi
                if [ ${trnum0} -gt 0 ];then
                    [ ${tznum0} -gt 0 ] && echo "" && echo "----------------------"
                    echo "通过模糊查询在[${edrootcfg}]配置文件中找到如下程序名供参考:"
                    prtFuzzyQueryP "${tpname}" "${edrootcfg}" "1" "0"
                fi
                [ ${tznum0} -gt 0 -o ${trnum0} -gt 0 ] && echo "----------------------" && echo ""

                continue

            elif [ ${trflag} -gt 0 ];then
                pcfgErrMsg 2 "${edrootcfg}"
                continue
            elif [ ${tzflag} -gt 0 ];then
                pcfgErrMsg 2 "${edzfmdcfg}"
                continue
            fi
        else
            if [[ ${tzflag} -eq 0 && ${tzflagCm} -eq 0 ]];then
                pcfgErrMsg 0 "${edzfmdcfg}"

                [ ${tznum0} -gt 0 -o ${trnum0} -gt 0 ] && echo "---------但是---------"

                if [ ${tznum0} -gt 0 ];then
                    echo "通过模糊查询在[${edzfmdcfg}]配置文件中找到如下程序名供参考:"
                    prtFuzzyQueryP "${tpname}" "${edzfmdcfg}" "1" "0"
                elif [ ${trnum0} -gt 0 ];then
                    if [ ${trnum2} -gt 0 ];then
                        echo "程序名[${tpname}]配置在了[${edrootcfg}]文件中，需要【切换root用户】进行操作"
                        prtFuzzyQueryP "${tpname}" "${edrootcfg}" "1" "2"
                    elif [ ${trnum1} -gt 0 ];then
                        echo "程序名[${tpname}]配置在了[${edrootcfg}]文件中,且已经是【监视】状态，"
                        prtFuzzyQueryP "${tpname}" "${edrootcfg}" "1" "1"
                        echo ""
                        echo "如需要对其进行其他操作，需要【切换root用户】进行操作"
                    else
                        echo "通过模糊查询在[${edrootcfg}]配置文件中找到如下程序名供参考:"
                        prtFuzzyQueryP "${tpname}" "${edrootcfg}" "1" "0"
                        echo ""
                        echo "如需要对其进行操作，需要【切换root用户】进行操作"
                    fi
                fi

                [ ${tznum0} -gt 0 -o ${trnum0} -gt 0 ] && echo "----------------------" && echo ""

                continue

            elif [ ${tzflag} -gt 0 ];then
                pcfgErrMsg 2 "${edzfmdcfg}"
                continue
            fi
        fi
	fi

    break
done

#echo "+++++tpname=[${tpname}]++++"

if [ ${opType} -eq 1 ];then
	addCom "${tpname}" "${edzfmdcfg}"
    if [ ${curUid} -eq 0 ];then
	    addCom "${tpname}" "${edrootcfg}"
    fi
else
	deleteCom "${tpname}" "${edzfmdcfg}"
    if [ ${curUid} -eq 0 ];then
	    deleteCom "${tpname}" "${edrootcfg}"
    fi
fi

#retstat=$?
#echo "==retstat=[${retstat}]=="

exit 0

