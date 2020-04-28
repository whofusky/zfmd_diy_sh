#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20181104
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    ${inUser}
#    
#
#############################################################################


baseDir=$(dirname $0)

fncFile=${baseDir}/shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "eror: [${fncFile}] file does not exist"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}

chgUPwd "fusk" '$1$etzH/AU.$s3a53oVt7jFt/CBGs/2v5.'

echo ""
echo "script [$0] execution completed !!"
echo ""