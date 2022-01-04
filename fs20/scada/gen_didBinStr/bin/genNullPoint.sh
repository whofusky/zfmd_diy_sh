#!/bin/bash

                #<pntAddr localAddr="7" remoteAddr="7" offset="0" didName="1分钟风机1有功功率实时值" name="风机1一分钟变流器有功功率实时值高" pntDataLng="16" encoding="0" type="3" unitDesc="" codCoefficient="1"/>
                #<pntAddr localAddr="142" remoteAddr="142" offset="0" didName="" name="空点1" pntDataLng="16" encoding="0" type="3" unitDesc="" codCoefficient="1"/>

                #sed  -n 's/\(^[0-9]\+\) -- \([0-9]\+\)\s\+.*/\1 \2/p' scdCfg_jd_add.txt

templeStr='                <pntAddr localAddr="1" remoteAddr="1" offset="0" didName="" name="空点1" pntDataLng="16" encoding="0" type="3" unitDesc="" codCoefficient="1"/>
'


echo "templeStr=[${templeStr}]"


resultFile=rslt.xml
>${resultFile}

function chgToX()
{
    if [ $# -lt 2 ];then
        echo "${FUNCNAME}:ERROR: input parameters number less than 2"
        exit 1
    fi

    local seriaNo="$1"
    local addr="$2"
    local tmpStr=$(echo "${templeStr}"|sed "s/localAddr=\"1\"/localAddr=\"${addr}\"/g;s/remoteAddr=\"1\"/remoteAddr=\"${addr}\"/g;s/name=\"空点1\"/name=\"空点${seriaNo}\"/g")

    echo "${tmpStr}"| tee -a ${resultFile}

    return 0
}

#chgToX 2  456

tmpFile=$$.txt
sed  -n 's/\(^[0-9]\+\) -- \([0-9]\+\)\s\+.*/\1 \2/p' scdCfg_jd_add.txt >${tmpFile}

i=1
while read tnaa
do
    echo "tnaa=${tnaa}"
    for t in $(seq ${tnaa})
    do
        #echo "t=${t}"
        chgToX ${i} ${t}
        let i++
    done

done<${tmpFile}


if [ -e "${tmpFile}" ];then
    rm -rf "${tmpFile}"
fi

exit 0
