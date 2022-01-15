#!/bin/bash
#
########################################################################
#author       :    fushikai
#date         :    20211201
#dsc          :
#   Call the script sysd_iptb_serv.sh and write the log 
#
########################################################################
#


    
[ ! -d "/zfmd/safe/fw/log" ] && mkdir -p "/zfmd/safe/fw/log"

echo "$(date +%F_%T.%N) /zfmd/safe/fw/basesh/sysd_iptb_serv.sh $@" >>"/zfmd/safe/fw/log/systemdOpIptables.log"

/zfmd/safe/fw/basesh/sysd_iptb_serv.sh $@ >>/zfmd/safe/fw/log/systemdOpIptables.log 2>&1
retStat=$?

echo "$(date +%F_%T.%N) retStat=${retStat}">>/zfmd/safe/fw/log/systemdOpIptables.log 2>&1

exit ${retStat}

