#!/bin/bash
#
#############################################################################
#author       :    fushikai
#date         :    20201030
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#     Obtain the main program of the fs20 project for backup
#
#############################################################################

exeUser="$(whoami)"
idU=$(id -u ${exeUser})

if [ "${idU}" != "0" ];then
    echo -e "\n\t\e[1;31mERROR:\e[0m Please execute as \e[1;31mroot\e[0m user\n"
    exit 0
fi

tHName="$HOSTNAME"
tTime=$(date +%Y%m%d%H%M%S)
tLcBDir="fs20_backup_$(date +%Y%m%d)"

if [ ! -d "${tLcBDir}" ];then
    mkdir "${tLcBDir}"
    #echo -e "\n\tmkdir ${tLcBDir}"
fi

cd "${tLcBDir}"
#echo -e "\n\tcd ${tLcBDir}\n"

#Sub-file or directory backup threshold (in megabytes)
tMaxSizeToCp=50    #Unit is M

#define main program dir
proDir[0]="/zfmd/wpfs20/fdb"      ; findLevel[0]=1
proDir[1]="/zfmd/wpfs20/utf"      ; findLevel[1]=1
proDir[2]="/zfmd/wpfs20/tp"       ; findLevel[2]=1
proDir[3]="/zfmd/wpfs20/datapp"   ; findLevel[3]=1
proDir[4]="/zfmd/wpfs20/monitor"  ; findLevel[4]=1
proDir[5]="/zfmd/wpfs20/dph"      ; findLevel[5]=1
proDir[6]="/zfmd/wpfs20/startup"  ; findLevel[6]=1
proDir[7]="/zfmd/wpfs20/scada"    ; findLevel[7]=1


#define pubcfg dir
cfgDir[0]="/etc"                  ; findCfgLevel[0]=1

#define publib dir
pubLibDir[0]="/zfmd/wpfs20/lib"   ; findLibLevel[0]=1

function getLastDirName()
{
    if [ $# -lt 1 ];then
        return 1
    fi
    local tPath="$1"
    echo "${tPath##*/}"
    return 0
}

function F_cloneDir()  #use: $0  oldDir  newDir
{
    if [ $# -ne 2 ];then
        echo -e "\n\tERROR:${FUNCNAME} input para not eq 2!\n"
        return 1
    fi
    if [ ! -d "$1" ];then
        #echo "[$1] not exist"
        return 2
    fi

    local oldDir="$1"
    local newDir="$2"

    #echo "oldDir=[${oldDir}],newDir=[${newDir}]"
    
    local oldU=$(stat -c %U "${oldDir}")
    local oldG=$(stat -c %G "${oldDir}")
    local oldy=$(stat -c %y "${oldDir}")

    if [ -d "${newDir}" ];then
        local newU=$(stat -c %U "${newDir}")
        local newG=$(stat -c %G "${newDir}")
        local newy=$(stat -c %y "${newDir}")
        [[ "${newU}" != "${oldU}" || "${newG}" != "${oldG}" ]] && chown ${oldU}:${oldG} "${newDir}"
        [[ "${newy}" != "${oldy}" ]] && touch -d "${oldy}" "${newDir}"

    else

        #echo "mkdir -p \"${newDir}\""
        mkdir -p "${newDir}"
        chown ${oldU}:${oldG} "${newDir}"
        touch -d "${oldy}" "${newDir}"
    fi

    return 0
}


function F_cpOneSub()
{
    if [ $# -lt 3 ];then
        echo -e "\n\tERROR:${FUNCNAME} input para number less 3\n"
        return 1
    fi
    local tODir="$1"
    local tNDir="$2"
    local tLevel="$3"

    if [ -z "${tLevel}" ];then
        echo -e "\n\tERROR:${FUNCNAME} input para tLevel is null\n"
        return 1
    fi

    #echo -e "\ttODir=[${tODir}],tNDir=[${tNDir}],tLevel=[${tLevel}] .... 1"

    [ ${tLevel} -le 0 ] && return 0
    [ ! -e "${tODir}" ] && return 0

    if [ ! -d "${tODir}" ];then
        cp -a "${tfname}" "${tNDir}"
        return 0
    fi


    #[ ! -d "${tODir}" ] && return 0


    local tNum=$(ls -d1 "${tODir}"/* 2>/dev/null|wc -l)
    [ ${tNum} -eq 0 ] && return 0


    F_cloneDir "${tODir}" "${tNDir}"



    local tsize
    local tfname
    local tSubDir
    local ttLevel
    du -sm "${tODir}"/* |sort -n  -k1,1 -r|while read tsize tfname
    do

        if [[ ${tsize} -gt ${tMaxSizeToCp} && -d "${tfname}" ]];then
            let ttLevel=tLevel-1
            echo -e "\ttsize=[${tsize}]>${tMaxSizeToCp} M, so----\e[1;31minto dir \e[0m------dir=[${tfname}] \e[1;31mlevel[${ttLevel}]\e[0m"
            tSubDir=$(getLastDirName "${tfname}")
            F_cpOneSub "${tfname}" "${tNDir}/${tSubDir}" "${ttLevel}"
            F_cloneDir "${tfname}" "${tNDir}/${tSubDir}"
        elif [[ ${tsize} -gt ${tMaxSizeToCp} ]];then
            echo -e "\ttsize=[${tsize}]>${tMaxSizeToCp} M, so----\e[1;31mignor file \e[0m------tfname=[${tfname}]"
            continue
        else
            #echo -e "\ttsize=[${tsize}]<=${tMaxSizeToCp} M, so----copy [${tfname}] to [${tNDir}]"
            cp -a "${tfname}" "${tNDir}"
        fi
    done

    F_cloneDir "${tODir}" "${tNDir}"

    return 0
}



function F_back()
{

    if [ $# -lt 3 ];then
        echo -e "\n\tERROR:${FUNCNAME} input para number less 3\n"
        return 1
    fi
    local tDir="$1"
    local tDelLogFlag="$2"
    local tLevel="$3"

    if [ ! -d "${tDir}" ];then
        #echo -e "\n\t dir [${tDir}] not exist!\n"
        return 0
    fi

    local tLcDir=$(getLastDirName "${tDir}")

    local tBgSc=$(date +%s)
    echo -e "\n $(date +%Y-%m-%d_%H:%M:%S.%N):   backup [ ${tDir} ] To [ ./${tLcDir} ] \e[1;31mlevel[${tLevel}]\e[0m ..."

    #cp -a "${tDir}" "./${tLcDir}"
    F_cpOneSub "${tDir}" "./${tLcDir}" "${tLevel}"

    if [ ! -d "./${tLcDir}" ];then
        return 0
    fi

    if [ "${tDelLogFlag}" = "1" ];then
        find "./${tLcDir}" -iname "*log" -type d -print0|xargs -0 rm -rf
        find "./${tLcDir}" -name "core.*" -type f -print0|xargs -0 rm -rf
    fi
    local tarName="${tHName}_${tLcDir}_${tTime}.tar.gz"

    echo -e "    tar [ ${tarName} ].."

    tar -zcvf "${tarName}" "./${tLcDir}" >/dev/null
    echo -e "    tar [ ${tarName} ] end"

    if [ -d "${tLcDir}" ];then
        rm -rf "./${tLcDir}"
    fi

    local tEdSc=$(date +%s)
    local tdiff=$(echo "${tEdSc} - ${tBgSc}"|bc)

    echo -e " $(date +%Y-%m-%d_%H:%M:%S.%N):   backup [ ${tDir} ] To [ ./${tLcDir} ]  end, elapse \e[1;41m ${tdiff} \e[0m seconds"

    return 0
}

function main()
{
    #back progra
    local i
    local proNum=${#proDir[*]}
    for (( i=0;i<${proNum};i++))
    do
        F_back "${proDir[$i]}" "1" "${findLevel[$i]}"
    done

    #back lib
    local libNum=${#pubLibDir[*]}
    for (( i=0;i<${libNum};i++))
    do
        F_back "${pubLibDir[$i]}" "0" "${findCfgLevel[$i]}"
    done

    #back public cfg
    local cfgNum=${#cfgDir[*]}
    for (( i=0;i<${cfgNum};i++))
    do
        F_back "${cfgDir[$i]}" "0" "${findLibLevel[$i]}"
    done

    return 0
}

echo -e "\n  TIPS: Files or directories that\e[1;41m exceed ${tMaxSizeToCp} M \e[0mduring backup will be ignored\n"

tBgSc=$(date +%s)
main
tEdSc=$(date +%s)
tdiff=$(echo "${tEdSc} - ${tBgSc}"|bc)

echo -e "\n\t $0 exe \e[1;31mcomplete\e[0m!"
echo -e "\t \e[1;41m ${tdiff} seconds \e[0m to execute $0, bakup dir=[ ${tLcBDir} ]\n"

exit 0
