#!/bin/bash

#############################################################################
#author       :    fushikai
#date         :    20181213
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    Generate a simple description of the custom function
#    
#
#############################################################################

baseDir=$(dirname $0)

fncFile=${baseDir}/diyFuncBysky.func
descFile=${baseDir}/readme.txt
>${descFile}

echo "">>${descFile}
echo "/*************************************************">>${descFile}
echo "*">>${descFile}
echo "*  date:`date +%Y/%m/%d-%H:%M:%S.%N`">>${descFile}
echo "*">>${descFile}
echo "*  desc:The list of functions in file ">>${descFile}
echo "*       diyFuncBysky.func">>${descFile}
echo "*">>${descFile}
echo "*************************************************/">>${descFile}

echo "">>${descFile}
echo "">>${descFile}

echo "-----------------------------------------------">>${descFile}

linenum=1
sed -n "/[ \t]*\<function\>[ \t]\+.*\([ \t]*\)[ \t]*/p" ${fncFile}|while read tnaa
do
	echo "-${linenum}- : ${tnaa} ">>${descFile}
	linenum=$((${linenum}+1))
done

echo "-----------------------------------------------">>${descFile}

echo "">>${descFile}


