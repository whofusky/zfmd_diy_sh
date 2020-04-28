#!/bin/sh


#############################################################################
#author       :    fushikai
#date         :    20180820
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    set up fu.sky's personal habits
#    
#
#############################################################################

bashrcName=~/.bashrc
#bashrcName=tmp/.bashrc
aliasN1="alias ls='ls -F'"
aliasN2="alias l='ls -l'"
aliasN3="alias lrt='ls -lrt'"
PS1Add="export PS1='[\u@\h \w]\$'"
timeStyle="export TIME_STYLE='+%Y/%m/%d %H:%M:%S'"

if [[ -f $bashrcName ]];then
	echo "edit file=[$bashrcName]"

	aliasNum=$(egrep "^alias" $bashrcName|wc -l)
	aliasNumC=$(egrep "^#alias" $bashrcName|wc -l)
	exportNum=$(egrep "^export" $bashrcName|wc -l)
	exportNumC=$(egrep "^#export" $bashrcName|wc -l)

	echo "====alias-->begine"
	if [[ $aliasNum -gt 0 ]];then
		if [[ $(egrep "^$aliasN1" $bashrcName|wc -l) -lt 1 ]];then
			if [[ $(egrep -w "^alias ls" $bashrcName|wc -l) -lt 1 ]];then
				sed "$(sed -n "/^alias/=" $bashrcName|sed -n '$p')a$aliasN1" -i $bashrcName	
				echo "add row=[$aliasN1]"
			else
				sed "$(sed -n "/^\<alias ls\>/=" $bashrcName|sed 1q)c$aliasN1" -i $bashrcName	
				echo "change row=[$aliasN1]"
			fi
		fi
	elif [[ $aliasNumC -gt 0 ]];then
		if [[ $(egrep "^$aliasN1" $bashrcName|wc -l) -lt 1 ]];then
			sed "$(sed -n "/^#alias/=" $bashrcName|sed -n '$p')a$aliasN1" -i $bashrcName	
			echo "add row=[$aliasN1]"
		fi
	else
		if [[ $(egrep "^$aliasN1" $bashrcName|wc -l) -lt 1 ]];then
			sed "$(sed -n "/?*/=" $bashrcName|sed -n '$p')a$aliasN1" -i $bashrcName	
			echo "add row=[$aliasN1]"
		fi
	fi

	if [[ $(egrep "^$aliasN2" $bashrcName|wc -l) -lt 1 ]];then
		if [[ $(egrep -w "^alias l" $bashrcName|wc -l) -lt 1 ]];then
			sed "$(sed -n "/^alias/=" $bashrcName|sed -n '$p')a$aliasN2" -i $bashrcName	
			echo "add row=[$aliasN2]"
		else
			sed "$(sed -n "/^\<alias l\>/=" $bashrcName|sed 1q)c$aliasN2" -i $bashrcName	
			echo "change row=[$aliasN2]"
		fi
	fi
	if [[ $(egrep "^$aliasN3" $bashrcName|wc -l) -lt 1 ]];then
		if [[ $(egrep -w "^alias lrt"  $bashrcName|wc -l) -lt 1 ]];then
			sed "$(sed -n "/^alias/=" $bashrcName|sed -n '$p')a$aliasN3" -i $bashrcName	
			echo "add row=[$aliasN3]"
		else
			sed "$(sed -n "/^\<alias lrt\>/=" $bashrcName|sed 1q)c$aliasN3" -i $bashrcName	
			echo "change row=[$aliasN3]"
		fi
	fi
	echo "====alias-->end"
	echo ""

	echo "====export-->begine"
	if [[ $exportNum -gt 0 ]];then
		if [[ $(egrep -w "^export PS1" $bashrcName|wc -l) -lt 1 ]];then
			sed "$(sed -n "/^export/=" $bashrcName|sed -n '$p')a$PS1Add" -i $bashrcName	
			echo "add row=[$PS1Add]"
		else
			sed "$(sed -n "/^export PS1/=" $bashrcName|sed 1q)c$PS1Add" -i $bashrcName	
			echo "change row=[$PS1Add]"
		fi
	elif [[ $exportNumC -gt 0 ]];then
		if [[ $(egrep -w "^export PS1" $bashrcName|wc -l) -lt 1 ]];then
			sed "$(sed -n "/^#export/=" $bashrcName|sed -n '$p')a$PS1Add" -i $bashrcName	
			echo "add row=[$PS1Add]"
		fi
	else
		if [[ $(egrep -w "^export PS1" $bashrcName|wc -l) -lt 1 ]];then
			sed "$(sed -n "/?*/=" $bashrcName|sed -n '$p')a$PS1Add" -i $bashrcName	
			echo "add row=[$PS1Add]"
		fi
	fi

	if [[ $(egrep "^export TIME_STYLE" $bashrcName|wc -l) -lt 1 ]];then
		sed "$(sed -n "/^export/=" $bashrcName|sed -n '$p')a$timeStyle" -i $bashrcName	
		echo "add row=[$timeStyle]"
	else
		sed "$(sed -n "/^export TIME_STYLE/=" $bashrcName|sed 1q)c$timeStyle" -i $bashrcName	
		echo "change row=[$timeStyle]"
	fi
	echo "====export-->end"
	echo ""
fi

edVimrcF=~/.vimrc
#edVimrcF=tmp/.vimrc
ecd1="set encoding=utf-8"
ecd2="set fileencodings=ucs-bom,utf-8,cp936,latin1"
ecd3="set fileencoding=gb2312"
ecd4="set termencoding=utf-8"
if [[ ! -f $edVimrcF ]];then
	echo "">$edVimrcF
fi

which vim >/dev/null 2>&1
if [[ $? -eq 0 && -f $edVimrcF ]];then
	echo "edit file=[$edVimrcF]"
	
	if [[ $(egrep -w "^$ecd1" $edVimrcF|wc -l) -lt 1 ]];then
		if [[ $(egrep -w "^set encoding" $edVimrcF|wc -l) -lt 1 ]];then
			sed "$(sed -n "/?*/=" $edVimrcF|sed -n '$p')a$ecd1" -i $edVimrcF 
			echo "add row=[$ecd1]"
		else
			sed "$(sed -n "/^\<set encoding\>/=" $edVimrcF|sed 1q)c$ecd1" -i $edVimrcF
			echo "change row=[$ecd1]"
		fi
	fi
	if [[ $(egrep -w "^$ecd2" $edVimrcF|wc -l) -lt 1 ]];then
		if [[ $(egrep -w "^set fileencodings" $edVimrcF|wc -l) -lt 1 ]];then
			sed "$(sed -n "/?*/=" $edVimrcF|sed -n '$p')a$ecd2" -i $edVimrcF 
			echo "add row=[$ecd2]"
		else
			sed "$(sed -n "/^\<set fileencodings\>/=" $edVimrcF|sed 1q)c$ecd2" -i $edVimrcF
			echo "change row=[$ecd2]"
		fi
	fi
	if [[ $(egrep -w "^$ecd3" $edVimrcF|wc -l) -lt 1 ]];then
		if [[ $(egrep -w "^set fileencoding" $edVimrcF|wc -l) -lt 1 ]];then
			sed "$(sed -n "/?*/=" $edVimrcF|sed -n '$p')a$ecd3" -i $edVimrcF 
			echo "add row=[$ecd3]"
		else
			sed "$(sed -n "/^\<set fileencoding\>/=" $edVimrcF|sed 1q)c$ecd3" -i $edVimrcF
			echo "change row=[$ecd3]"
		fi
	fi
	if [[ $(egrep -w "^$ecd4" $edVimrcF|wc -l) -lt 1 ]];then
		if [[ $(egrep -w "^set termencoding" $edVimrcF|wc -l) -lt 1 ]];then
			sed "$(sed -n "/?*/=" $edVimrcF|sed -n '$p')a$ecd4" -i $edVimrcF 
			echo "add row=[$ecd4]"
		else
			sed "$(sed -n "/^\<set termencoding\>/=" $edVimrcF|sed 1q)c$ecd4" -i $edVimrcF
			echo "change row=[$ecd4]"
		fi
	fi
fi
echo ""


