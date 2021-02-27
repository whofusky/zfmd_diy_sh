#!/bin/bash
#
#   输出scada配置文件中每个通道的开始点地址和结束点地址，
#                      每个通道中的最小物理量和结束物理量
#   （按实际配置的值遍历查找得到上面的值）
#
#
baseDir=$(dirname $0)

#echo "---[${baseDir}]---"

function maxValPrint()
{

    #echo "--$#---"

    if [ $# -ne 3 ];then
        echo "ERROR,input prarameters not eq 3!"
        return 1
    fi

    bNum=$1
    eNum=$2
    efile=$3

    chname=$(sed -n "${bNum}p" ${efile}|awk -F'[<> ]' '{for(i=1;i<=NF;i++){if($i ~ /chnNum=./){print $i;break;} }}')
    cfgmaxtype=$(sed -n "${bNum}p" ${efile}|awk -F'[<> ]' '{for(i=1;i<=NF;i++){if($i ~ /maxPhyType=./){print $i;break;} }}')
    
    echo ""
    echo "-------------------------[${chname}]--------------------------------------"
    echo "cfgmaxtype=[${cfgmaxtype}]"
    sed -n "${bNum},${eNum}p" ${efile}|egrep "^\s*<contPntAdd\>"
    echo ""

    sed -n "${bNum},${eNum}p" ${efile}|awk -F'[<> "=]' 'BEGIN{bgaddr=-1;bgtype=-1;maxaddr=0;maxtype=0} {
        for(i=1;i<=NF;i++)
        {
            if ( $i=="pntAddr" )
            {
                #print $(i+1);
                if(maxaddr<$(i+1))
                {
                    maxaddr=$(i+1)
                }
                if( bgaddr==-1 )
                {
                    bgaddr=$(i+1)
                }
                if(bgaddr>$(i+1))
                {
                    bgaddr=$(i+1);
                }
                break;
            }
            if( $i=="phyType" )
            {
                #print $(i+2);
                if( maxtype<$(i+2) )
                {
                    maxtype=$(i+2)
                }
                if( bgtype==-1 )
                {
                    bgtype=$(i+2)
                }
                if(bgtype>$(i+2))
                {
                    bgtype=$(i+2);
                }
                break;
            }
        }
    }
    END{
        printf "----bgaddr=[%s],maxaddr=[%s]\n",bgaddr,maxaddr
        printf "----bgtype=[%s],maxtype=[%s]\n", bgtype,maxtype
    }'

    echo "------------------------------------------------------------------------------"
    echo ""

    return 0
    
}

bNum=16
eNum=1357
efile=${baseDir}/unitMemInit.xml

#maxValPrint ${bNum} ${eNum} ${efile}

idx=0
egrep -n "^\s*(<\<channel\>.|</channel>)\s*" ${efile} >tmp.txt

while read tnaa
do
    num1=$(echo "${tnaa}"|egrep "^.*\s*<\<channel\>.\s*"|wc -l)
    num2=$(echo "${tnaa}"|egrep "^.*\s*</channel>\s*"|wc -l)
    linenum=$(echo "${tnaa}"|awk -F':' '{print $1}')
    if [ ${num1} -gt 0 ];then
        bbNum[${idx}]=${linenum}    
    elif [ ${num2} -gt 0 ];then
        eeNum[${idx}]=${linenum}    
        #echo "${bbNum[${idx}]},${eeNum[${idx}]}"
        maxValPrint ${bbNum[${idx}]} "${eeNum[${idx}]}" ${efile}
        let idx++
    fi

    #echo "idx=[${idx}]"
    #echo "[${tnaa}],num1=[${num1}],num2=[${num2}],linenum=[${linenum}]"
done<tmp.txt

echo "idx=[${idx}]"
doNum1=${#bbNum[*]}
doNum2=${#eeNum[*]}
echo "doNum1=[${doNum1}],doNum2=[${doNum2}]"

