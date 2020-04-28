#!/bin/sh

function setNo()
{
	srNo=$1
	dsNo=$2
	edFile=$3

#echo "---[$srNo]---[$dsNo]---[$edFile]--"
	sed "s/$srNo/$dsNo/g" -i $edFile

}

>rest_merger
cat ftmp57>>rest_merger

for ((i=58;i<=72;i++))
do
	pre=$(($i-1))
	preFile=ftmp${pre}	
	nxtFile=ftmp$i

	cp ${preFile} ${nxtFile}

	setNo "${pre}" "$i" "$nxtFile"

	cat "$nxtFile" >>rest_merger

done
for ((i=58;i<=72;i++))
do
	pre=$(($i-1))
	preFile=ftmp${pre}	
	nxtFile=ftmp$i
	rm $nxtFile
done
