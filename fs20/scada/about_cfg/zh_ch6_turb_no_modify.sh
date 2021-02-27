#!/bin/bash

#
#   庄河风电场根据通道6的风机编号从调度编号改为模型编号
#
#


baseDir=$(dirname $0)

edFile="${baseDir}/chn6.xml"
if [ ! -f ${edFile} ];then
    echo -e "\tError:file[${edFile}] not exist!!"
    exit 1
fi

turbNoArry=('1  35'
'2  41'
'3  47'
'4  53'
'5  56'
'6  20'
'7  21'
'8  22'
'9  23'
'10 24'
'11 10'
'12 9'
'13 8'
'14 7'
'15 6'
'16 5'
'17 4'
'18 12'
'19 11'
'20 3'
'21 2'
'22 1'
'23 19'
'24 18'
'25 17'
'26 16'
'27 15'
'28 14'
'29 13'
'30 28'
'31 27'
'34 29'
'35 26'
'36 25'
'32 59'
'33 68'
'37 64'
'38 63'
'39 62'
'40 61'
'41 60'
'42 66'
'43 58'
'44 57'
'45 65'
'46 71'
'47 70'
'48 69'
'49 67'
'50 30'
'51 36'
'52 42'
'53 48'
'54 50'
'55 31'
'56 32'
'57 38'
'58 37'
'59 43'
'60 44'
'61 49'
'62 72'
'63 33'
'64 39'
'65 45'
'66 51'
'67 54'
'68 34'
'69 40'
'70 46'
'71 52'
'72 55'
)

tnum=$(sed -n '/ectype="ENCODETYPE_TURBINE"/=' ${edFile}|wc -l)
if [ ${tnum} -lt 1 ];then
    echo -e "\n\t Error:ENCODETYPE_TURBINE line num ls [${tnum}]\n"
    exit 2
fi
beLineNo=$(sed -n '/ectype="ENCODETYPE_TURBINE"/=' ${edFile}|head -1)
enLineNo=$(sed -n '/ectype="ENCODETYPE_TURBINE"/=' ${edFile}|tail -1)


nuTurb=${#turbNoArry[*]}
echo "----${nuTurb}----"
echo "===beLineNo=[${beLineNo}]====enLineNo=[${enLineNo}]---"

#####first change ecsn=oldNo to ecsn=ttNo (ttNo="oldNonewNo")
for (( i=0;i<${nuTurb};i++))
do

    #echo "----turbNoArry[$i]=${turbNoArry[$i]}---"

    tmpArry=(${turbNoArry[$i]})
    oldNo=$((${tmpArry[0]} - 1 ))
    newNo=$((${tmpArry[1]} - 1 ))
    ttNo="${oldNo}${newNo}"

    #echo "====oldNo=${oldNo}"
    #echo "====newNo=${newNo}"
    #echo "====ttNo=${ttNo}"

    sed "${beLineNo},${enLineNo}s/ecsn=\"${oldNo}\"/ecsn=\"${ttNo}\"/g" -i ${edFile}

done


#####second change ecsn=ttNo(ttNo="oldNonewNo") to ecsn=newNo 
for (( i=0;i<${nuTurb};i++))
do

    #echo "----turbNoArry[$i]=${turbNoArry[$i]}---"

    tmpArry=(${turbNoArry[$i]})
    oldNo=$((${tmpArry[0]} - 1 ))
    newNo=$((${tmpArry[1]} - 1 ))
    ttNo="${oldNo}${newNo}"

    #echo "====oldNo=${oldNo}"
    #echo "====newNo=${newNo}"
    #echo "====ttNo=${ttNo}"

    sed "${beLineNo},${enLineNo}s/ecsn=\"${ttNo}\"/ecsn=\"${newNo}\"/g" -i ${edFile}

done

echo -e "\n\tscript [$0] execution completed !!\n"
exit 0



