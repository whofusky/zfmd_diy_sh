#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20180914
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    fs2.0 project creation directory
#    
#
#############################################################################

if [[ $# -lt 1 ]];then
    echo "please input like: $0 <[mete]/[scada]/[pre1]/[pre2]/[gzz]>"
    exit 1
fi

baseDir=$(dirname $0)

fncFile=${baseDir}/../../shfunc/diyFuncBysky.func
if [[ ! -f ${fncFile} ]];then
    echo ""
    echo "eror: [${fncFile}] file does not exist"
    echo ""
    exit 3
fi

#Load shell function file
. ${fncFile}

###DIR
zfsPDir=/zfmd
zfmdTmp=${zfsPDir}/tmp
zfmdffox=${zfsPDir}/firefox
zfmdtmcat=${zfsPDir}/tomcat/tomcat8
zfmdjdk=${zfsPDir}/jdk
zfmdora=${zfsPDir}/oracle
zskp2000=${zfsPDir}/syskeeper2000
zfs20Dir=${zfsPDir}/wpfs20

zfmdLib=${zfs20Dir}/lib
zfmdStar=${zfs20Dir}/startup
zfmdBack=${zfs20Dir}/backup
zfmdMoni=${zfs20Dir}/monitor
zfmdTSyn=${zfs20Dir}/timesync
zfmdVbus=${zfs20Dir}/vbus
zfmdInstall=${zfs20Dir}/install
zfmdoradata=${zfs20Dir}/oradata
zfmdwebapp=${zfs20Dir}/webapp
zfmdri3=${zfs20Dir}/ri3data
zfmdri2=${zfs20Dir}/ri2data
zfmdmete=${zfs20Dir}/mete
zacada=${zfs20Dir}/scada
zdaf=${zfs20Dir}/daf
zfdb=${zfs20Dir}/fdb
zutf=${zfs20Dir}/utf
ztp=${zfs20Dir}/tp
zdph=${zfs20Dir}/dph
zdatapp=${zfs20Dir}/datapp
zauftp=${zfs20Dir}/autoftp



###user_name or group_name
zUserN=zfmd
zGrpN=manager
oraUserN=oracle
oraGrpN=oinstall

#mete server
if [[ "$1" = "mete" ]];then
    echo "mete server"
    echo ""
    
    mkpDir "${zskp2000}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zskp2000}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zskp2000}/ttylog"
        
    mkpDir "${zfmdri3}/fgbackup"    
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdri3}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdri3}/fgbackup"
    
    mkpDir "${zfmdri3}/fgfs"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdri3}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdri3}/fgfs"
    
    mkpDir "${zfmdri3}/fgfs2"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdri3}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdri3}/fgfs2"
    
    mkpDir "${zfmdmete}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdmete}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdmete}/ttylog"
    
elif [[ "$1" = "scada" ]];then
    echo "scada server"
    echo ""
    
    mkpDir "${zacada}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zacada}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zacada}/ttylog"
    
    mkpDir "${zdaf}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zdaf}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zdaf}/ttylog"
    
    mkpDir "${zfmdTSyn}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdTSyn}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdTSyn}/ttylog"
    
    mkpDir "${zfmdVbus}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdVbus}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdVbus}/ttylog"

elif [[ "$1" = "pre1"  || "$1" = "pre2" ]];then
    echo "primary predictive server"
    echo ""
    
    mkpDir "${zskp2000}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zskp2000}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zskp2000}/ttylog"
    
    mkpDir "${zfmdri2}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdri2}"
    
    mkpDir "${zfmdTSyn}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdTSyn}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdTSyn}/ttylog"
    
    mkpDir "${zfdb}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfdb}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfdb}/ttylog"
    
    mkpDir "${zutf}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zutf}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zutf}/ttylog"
    
    mkpDir "${ztp}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${ztp}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${ztp}/ttylog"
    
    mkpDir "${zdph}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zdph}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zdph}/ttylog"
    
    mkpDir "${zdatapp}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zdatapp}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zdatapp}/ttylog"
    
    mkpDir "${zfmdVbus}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdVbus}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdVbus}/ttylog"
    
    mkpDir "${zauftp}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zauftp}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zauftp}/ttylog"
    
    mkpDir "${zfmdffox}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdffox}"
    
    mkpDir "${zfmdtmcat}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdtmcat}"
    
    mkpDir "${zfmdjdk}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdjdk}"
    
    mkpDir "${zfmdoradata}"
    
    mkpDir "${zfmdora}"
    
    mkpDir "${zfmdwebapp}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdwebapp}"
    
elif [[ "$1" = "gzz" ]];then
    echo "gzz server"
    echo ""
    
    mkpDir "${zfmdVbus}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdVbus}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdVbus}/ttylog"
    
    mkpDir "${zfmdTSyn}/ttylog"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdTSyn}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdTSyn}/ttylog"
else
    echo "unrecognixable input parameters"
    echo ""
    exit 2
fi
    
    
if [[ "$1" = "mete" || "$1" = "scada" || "$1" = "pre1" || "$1" = "pre2" || "$1" = "gzz" ]];then

    mkpDir "${zfmdTmp}"
    
    mkpDir "${zfmdLib}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdLib}"
    
    mkpDir "${zfmdStar}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdStar}"
    
    mkpDir "${zfmdBack}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdBack}"
    
    mkpDir "${zfmdMoni}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdMoni}/ttylog"
    
    mkpDir "${zfmdInstall}"
        chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdInstall}"
    
    chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfsPDir}"
    chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfs20Dir}"
    chgUandGzfmd "${oraUserN}" "${oraGrpN}" "${zfmdora}"
    chgUandGzfmd "${oraUserN}" "${oraGrpN}" "${zfmdoradata}"
    chgUandGzfmd "${zUserN}" "${zGrpN}" "${zfmdTmp}"
    chgUandGzfmd "${oraUserN}" "${oraGrpN}" "${zfmdTmp}"
    
    setPermission "${zfmdTmp}" "777"
    setPermission "${zfmdora}" "775"
    
fi

echo ""
echo "script [$0] execution completed !!"
echo ""
