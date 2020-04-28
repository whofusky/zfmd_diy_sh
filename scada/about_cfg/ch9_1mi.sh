#!/bin/bash

tDir=tt
tFName=1miF01.xml
doFile=do.xml

cp ${tFName} ${doFile}

for ((i=2;i<=72;i++))
do
#	echo "---$i"	
	if [ $i -lt 10 ];then
		thou="0$i"
	else
		thou=$i
	fi
#	echo "++++${thou}"

	tecsn=$(($i-1))
	tecsnpre=$(($i-2))
	fnum=${thou}

	tdstF=${tDir}/1miF${fnum}.xml
	if [ ${tecsn} -lt 10 ];then
		thoupre="0${tecsn}"
	else
		thoupre=${tecsn}
	fi

	if [ $i -eq 2 ];then
		tdstFpre=${tFName}
	else
		tdstFpre=${tDir}/1miF${thoupre}.xml
	fi
	#echo "-- ${tdstFpre}++${tdstF}++"
	cp ${tdstFpre} ${tdstF}
	sed -e "s/F${thoupre}/F${thou}/g; s/ecsn=\"${tecsnpre}\"/ecsn=\"${tecsn}\"/g" -i ${tdstF}

	if [ ${thou} -gt 33 ];then
		sed 's/grpNo="0"/grpNo="1"/g' -i  ${tdstF}
	fi

	awk -F"[<>]" 'BEGIN { addN=0;addval=80;} { if($2=="pntAddr") { addN=$3;addN=addN+addval;print $1"<"$2">"addN"<"$4">"$5$6;}else{print $0} }' ${tdstF} >t1.xml && cp t1.xml ${tdstF}
	
	cat ${tdstF} >> ${doFile}
done

awk -F"[< =]" 'BEGIN { phyType=1677;} {if($3=="phyType"){phyType=phyType+1;printf "%s<%s %s=\"%d\" ",$1,$2,$3,phyType; for (i=5;i<=NF;i=i+2) {a=i;b=i+1;printf "%s=%s ",$a,$b}; printf "\n";}else{print $0} }' ${doFile}>t1.xml && cp t1.xml ${doFile}

