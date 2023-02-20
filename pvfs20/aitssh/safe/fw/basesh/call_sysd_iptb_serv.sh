#!/bin/bash
#
########################################################################
#author       :    fushikai
#date         :    20221209
#dsc          :
#   Call the script sysd_iptb_serv.sh and write the log 
#
########################################################################
#


    
[ ! -d "/home/fusky/mygit/zfmd_diy_sh/pvfs20/safe/fw/./log" ] && mkdir -p "/home/fusky/mygit/zfmd_diy_sh/pvfs20/safe/fw/./log"

echo "$(date +%F_%T.%N) /home/fusky/mygit/zfmd_diy_sh/pvfs20/safe/fw/./basesh/sysd_iptb_serv.sh $@" >>"/home/fusky/mygit/zfmd_diy_sh/pvfs20/safe/fw/./log/systemdOpIptables.log"

/home/fusky/mygit/zfmd_diy_sh/pvfs20/safe/fw/./basesh/sysd_iptb_serv.sh $@ >>/home/fusky/mygit/zfmd_diy_sh/pvfs20/safe/fw/./log/systemdOpIptables.log 2>&1
retStat=$?

echo "$(date +%F_%T.%N) retStat=${retStat}">>/home/fusky/mygit/zfmd_diy_sh/pvfs20/safe/fw/./log/systemdOpIptables.log 2>&1

exit ${retStat}

