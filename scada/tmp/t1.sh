#!/bin/sh

basedir=$(dirname $0)

#echo "-----[${basedir}]--"


hvalue=(hvalue=\"10\" hvalue=\"30\" hvalue=\"50\" hvalue=\"70\" hvalue=\"90\")
italue=(ivalue=\"1\" ivalue=\"5\")
grpNo=(grpNo=\"0\" grpNo=\"1\" grpNo=\"2\" grpNo=\"3\" grpNo=\"4\" grpNo=\"5\" grpNo=\"6\" grpNo=\"7\" grpNo=\"8\" grpNo=\"9\" grpNo=\"10\")

echo "----${hvalue[2]}----"
echo "----${hvalue[3]}----"

k=0
for (( i=0;i<5;i++))
do
	for (( j=0;j<2;j++))
	do
		sed -n "/${hvalue[${i}]}.*${italue[${j}]}/=" channel_2.xml|while read tnaa
		do
			ednum=$((${tnaa}-4))
			sed "${ednum}s/grpNo=\".\"/${grpNo[${k}]}/g" -i channel_2.xml
		done
		
		k=$((${k}+1))
	done

	echo "---[${i}]----[${hvalue[${i}]}]---"
done
