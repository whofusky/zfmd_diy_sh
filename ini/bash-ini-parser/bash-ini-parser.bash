#
# based on http://theoldschooldevops.com/2008/02/09/bash-ini-parser/
#

############################# 0 ###############################################
PREFIX_0="cfg_0_section_"

function debug_0 {
   if ! [ "x$BASH_INI_PARSER_DEBUG" == "x" ]
   then
      echo
      echo --start-- $*
      echo "${g_bash_ini_0[*]}"
      echo --end--
      echo
   fi
}

function cfg_0_parser {
   shopt -p extglob &> /dev/null
   CHANGE_EXTGLOB=$?
   if [ $CHANGE_EXTGLOB = 1 ]
   then
      shopt -s extglob
   fi
   g_bash_ini_0="$(<$1)"                 # read the file
   g_bash_ini_0=${g_bash_ini_0//$'\r'/}           # remove linefeed i.e dos2unix

   g_bash_ini_0="${g_bash_ini_0//[/\\[}"
   #fusk20221230commentout debug_0 "escaped ["
   g_bash_ini_0="${g_bash_ini_0//]/\\]}"
   #fusk20221230commentout debug_0 "escaped ]"

   local OLDIFS="$IFS"
   IFS=$'\n' && g_bash_ini_0=( ${g_bash_ini_0} )  # convert to line-array

   g_bash_ini_0=( ${g_bash_ini_0[*]/#*([[:space:]]);*/} )
   g_bash_ini_0=( ${g_bash_ini_0[*]/%+([[:space:]]);*/} )   #fu.sky add@2022-12-30 : removed ending ; comments
   #fusk20221230commentout debug_0 "removed ; comments"
   g_bash_ini_0=( ${g_bash_ini_0[*]/#*([[:space:]])\#*/} )
   g_bash_ini_0=( ${g_bash_ini_0[*]/%+([[:space:]])\#*/} )  #fu.sky add@2022-12-30 : removed ending # comments
   #fusk20221230commentout debug_0 "removed # comments"

   g_bash_ini_0=( ${g_bash_ini_0[*]/#+([[:space:]])/} ) # remove init whitespace
   #fusk20221230commentout debug_0 "removed initial whitespace"
   g_bash_ini_0=( ${g_bash_ini_0[*]/%+([[:space:]])/} ) # remove ending whitespace
   #fusk20221230commentout debug_0 "removed ending whitespace"

   g_bash_ini_0=( ${g_bash_ini_0[*]/%+([[:space:]])\\]/\\]} ) # remove non meaningful whitespace after sections
   #fusk20221230commentout debug_0 "removed whitespace after section name"

   if [ $BASH_VERSINFO == 3 ]
   then
      g_bash_ini_0=( ${g_bash_ini_0[*]/+([[:space:]])=/=} ) # remove whitespace before =
      g_bash_ini_0=( ${g_bash_ini_0[*]/=+([[:space:]])/=} ) # remove whitespace after =
      g_bash_ini_0=( ${g_bash_ini_0[*]/+([[:space:]])=+([[:space:]])/=} ) # remove whitespace around =
   else
      g_bash_ini_0=( ${g_bash_ini_0[*]/*([[:space:]])=*([[:space:]])/=} ) # remove whitespace around =
   fi
   #fusk20221230commentout debug_0 "removed space around ="

   g_bash_ini_0=( ${g_bash_ini_0[*]/#\\[/\}$'\n'"${PREFIX_0}"} ) # set section prefix
   #fusk20221230commentout debug_0 "set section prefix"

   local i line
   for ((i=0; i < "${#g_bash_ini_0[@]}"; i++))
   do
      line="${g_bash_ini_0[i]}"
      if [[ "$line" =~ ${PREFIX_0}.+ ]]
      then
         g_bash_ini_0[$i]=${line// /_}
      elif [[ "$line" =~ =[^\"\']  ]]     #fu.sky add@2022-12-30 i.g key=1|2|3
      then
         #echo "----------------------------:[$line]"
         if [[ $(echo "${line}"|grep "\"\s*$"|wc -l) -eq 0 && $(echo "${line}"|grep "'\s*$"|wc -l) -eq 0 ]];then
             line=${line/=/=\"}
             g_bash_ini_0[$i]=${line/%/\"}
         fi
         #echo "----------------------------:[$line]"
      fi

      #fu.sky add@2023-03-10 i.g key='[1-9]'
      if [ $( echo "${g_bash_ini_0[$i]}"|sed  -n '/=/{/\\\[/p;/\\\]/p}'|wc -l) -gt 0 ];then  
          #echo "--------------fusktest----------------"
          g_bash_ini_0[$i]=$(echo "${g_bash_ini_0[$i]}"|sed  '/=/{s/\\\[/\[/g;s/\\\]/\]/g}')
      fi
   done
   #fusk20221230commentout debug_0 "subsections"

   g_bash_ini_0=( ${g_bash_ini_0[*]/%\\]/ \(} )   # convert text2function (1)
   #fusk20221230commentout debug_0 "convert text2function (1)"

   g_bash_ini_0=( ${g_bash_ini_0[*]/=/=\( } )     # convert item to array
   #fusk20221230commentout debug_0 "convert item to array"
   g_bash_ini_0=( ${g_bash_ini_0[*]/%/ \)} )      # close array parenthesis
   #fusk20221230commentout debug_0 "close array parenthesis"

   g_bash_ini_0=( ${g_bash_ini_0[*]/%\\ \)/ \\} ) # the multiline trick
   #fusk20221230commentout debug_0 "the multiline trick"

   g_bash_ini_0=( ${g_bash_ini_0[*]/%\( \)/\(\) \{} ) # convert text2function (2)
   #fusk20221230commentout debug_0 "convert text2function (2)"

   g_bash_ini_0=( ${g_bash_ini_0[*]/%\} \)/\}} )  # remove extra parenthesis
   #fusk20221230commentout debug_0 "remove extra parenthesis"
   g_bash_ini_0=( ${g_bash_ini_0[*]/%\{/\{$'\n''cfg_0_unset ${FUNCNAME/#'${PREFIX_0}'}'$'\n'} )  # clean previous definition of section 
   #fusk20221230commentout debug_0 "clean previous definition of section"

   g_bash_ini_0[0]=""                    # remove first element
   [[ ${g_bash_ini_0[1]} =~ ^} ]] && g_bash_ini_0[1]="" #fu.sky add@2022-12-30  i.g dos format
   #fusk20221230commentout debug_0 "remove first element"

   g_bash_ini_0[${#g_bash_ini_0[*]} + 1]='}'      # add the last brace
   #fusk20221230commentout debug_0 "add the last brace"


   eval "$(echo "${g_bash_ini_0[*]}")"   # eval the result
   EVAL_STATUS=$?
   if [ $CHANGE_EXTGLOB = 1 ]
   then
      shopt -u extglob
   fi
   IFS="$OLDIFS"
   return $EVAL_STATUS
}


function cfg_0_writer {
   local item fun newvar vars
   local SECTION f var

   SECTION=$1
   local OLDIFS="$IFS"
   IFS=' '$'\n'
   if [ -z "$SECTION" ]
   then
      fun="$(declare -F |egrep "s*${PREFIX_0}" )"
   else
      fun="$(declare -F ${PREFIX_0}${SECTION})"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" 1>&2
         exit 1
      fi
   fi
   fun="${fun//declare -f/}"
   #echo "fusktest--0----------------fun=[$fun]"
   for f in $fun; do
      [ "${f#${PREFIX_0}}" == "${f}" ] && continue
      item="$(declare -f ${f})"
      #echo "fusktest--0----------------f=[$f],item=[${item}]"
      item="${item##*\{}" # remove function definition
      item="${item##*FUNCNAME*${PREFIX_0}\};}" # remove clear section
      item="${item##*FUNCNAME*${PREFIX_0}\}}" # remove clear section
      item="${item/FUNCNAME\/#${PREFIX_0};}" # remove line
      item="${item/%\}}"  # remove function close
      item="${item%)*}" # remove everything after parenthesis
      if [[ "${item}" == $'\n' ]];then
          continue
      fi
      item="${item});" # add close parenthesis
      vars=""
      while [ "$item" != "" ]
      do
         newvar="${item%%=*}" # get item name
         vars="$vars$newvar" # add name to collection
         item="${item#*;}" # remove readed line
      done
      vars=$(echo "$vars" | sort -u) # remove duplication
      eval $f
      echo "[${f#${PREFIX_0}}]" # output section
      for var in $vars; do
         if [[ -z "$var" ]];then
             continue
         fi
         eval 'local length=${#'$var'[*]}' # test if var is an array
         if [ $length == 1 ]
         then
            echo $var=\"${!var}\" #output var
         else
            echo ";$var is an array" # add comment denoting var is an array
            eval 'echo $var=\"${'$var'[*]}\"' # output array var
         fi
      done
   done
   IFS="$OLDIFS"
}

function cfg_0_unset {
   local item fun newvar vars
   local SECTION f var OLDIFS

   SECTION=$1
   OLDIFS="$IFS"
   IFS=' '$'\n'
   if [ -z "$SECTION" ]
   then
      fun="$(declare -F)"
   else
      fun="$(declare -F ${PREFIX_0}${SECTION})"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" 1>&2
         return
      fi
   fi
   fun="${fun//declare -f/}"
   for f in $fun; do
      [ "${f#${PREFIX_0}}" == "${f}" ] && continue
      item="$(declare -f ${f})"

      item="${item##*\{}" # remove function definition
      item="${item##*FUNCNAME*${PREFIX_0}\};}" # remove clear section
      item="${item##*FUNCNAME*${PREFIX_0}\}}" # remove clear section
      item="${item/%\}}"  # remove function close
      item="${item%)*}" # remove everything after parenthesis
      if [[ "${item}" == $'\n' ]];then
          continue
      fi
      item="${item});" # add close parenthesis
      vars=""
      while [ "$item" != "" ]
      do
         newvar="${item%%=*}" # get item name
         vars="$vars $newvar" # add name to collection
         item="${item#*;}" # remove readed line
      done
      for var in $vars; do
         unset $var
      done
   done
   IFS="$OLDIFS"
}


function cfg_0_clear {
   local fun f SECTION OLDIFS
   SECTION=$1
   OLDIFS="$IFS"
   IFS=' '$'\n'
   if [ -z "$SECTION" ]
   then
      fun="$(declare -F)"
   else
      fun="$(declare -F ${PREFIX_0}${SECTION})"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" 1>&2
         exit 1
      fi
   fi
   fun="${fun//declare -f/}"
   for f in $fun; do
      [ "${f#${PREFIX_0}}" == "${f}" ] && continue
      unset -f ${f}
   done

   IFS="$OLDIFS"
}

function cfg_0_update {

   if [ $CHANGE_EXTGLOB = 1 ]
   then
      shopt -s extglob
   fi

   local fun SECTION VAR item OLDIFS
   SECTION=$1
   VAR=$2
   OLDIFS="$IFS"
   IFS=' '$'\n'
   fun="$(declare -F ${PREFIX_0}${SECTION})"
   if [ -z "$fun" ]
   then
      echo "section $SECTION not found" 1>&2
      exit 1
   fi
   fun="${fun//declare -f/}"
   item="$(declare -f ${fun})"
   item=$(echo "${item}"|sed "/^\s*${VAR}\s*=.*/d") # remove var declaration
   #item="${item//+([[:space:]])${VAR}=+([[:graph:]])/}" # remove var declaration
   item=$(echo "${item}"|sed "/^\s*${VAR}\s*=.*/d") # remove var declaration
   item="${item/%\}}"  # remove function close
   item="${item}
    $VAR=(\"${!VAR}\")
   "
   item="${item}
   }" # close function again

   eval "function $item"

   if [ $CHANGE_EXTGLOB = 1 ]
   then
      shopt -u extglob
   fi

   IFS="$OLDIFS"
    #declare -f ${fun}
}


function is_0_section()
{
    [ $# -lt 1 ] && return 1

    local fun="$(declare -F ${PREFIX_0}$1)"
    [ -z "$fun" ] && return 2

    return 0
}


function is_0_key()
{
    [ $# -lt 1 ] && return 1

    local VAR=$1
    local tt=${!VAR-x-----null}
    [ "1${tt}" == "1x-----null" ] && return 3

    return 0
}


#Determine whether the ini file has the corresponding configuration
function is_0_ini_cfg()
{
    local ret
    is_0_section "$1"
    ret=$?
    [ ${ret} -ne 0 ] && return ${ret}

    if [ $# -gt 1 ];then
        is_0_key "$2"
        ret=$?
        [ ${ret} -ne 0 ] && return ${ret}
    fi

    return 0
}


############################# 1 ###############################################


PREFIX_1="cfg_1_section_"

function debug_1 {
   if ! [ "x$BASH_INI_PARSER_DEBUG" == "x" ]
   then
      echo
      echo --start-- $*
      echo "${g_bash_ini_1[*]}"
      echo --end--
      echo
   fi
}

function cfg_1_parser {
   shopt -p extglob &> /dev/null
   CHANGE_EXTGLOB=$?
   if [ $CHANGE_EXTGLOB = 1 ]
   then
      shopt -s extglob
   fi
   g_bash_ini_1="$(<$1)"                 # read the file
   g_bash_ini_1=${g_bash_ini_1//$'\r'/}           # remove linefeed i.e dos2unix

   g_bash_ini_1="${g_bash_ini_1//[/\\[}"
   #fusk20221230commentout debug_1 "escaped ["
   g_bash_ini_1="${g_bash_ini_1//]/\\]}"
   #fusk20221230commentout debug_1 "escaped ]"

   local OLDIFS="$IFS"
   IFS=$'\n' && g_bash_ini_1=( ${g_bash_ini_1} )  # convert to line-array

   g_bash_ini_1=( ${g_bash_ini_1[*]/#*([[:space:]]);*/} )
   g_bash_ini_1=( ${g_bash_ini_1[*]/%+([[:space:]]);*/} )   #fu.sky add@2022-12-30 : removed ending ; comments
   #fusk20221230commentout debug_1 "removed ; comments"
   g_bash_ini_1=( ${g_bash_ini_1[*]/#*([[:space:]])\#*/} )
   g_bash_ini_1=( ${g_bash_ini_1[*]/%+([[:space:]])\#*/} )  #fu.sky add@2022-12-30 : removed ending # comments
   #fusk20221230commentout debug_1 "removed # comments"

   g_bash_ini_1=( ${g_bash_ini_1[*]/#+([[:space:]])/} ) # remove init whitespace
   #fusk20221230commentout debug_1 "removed initial whitespace"
   g_bash_ini_1=( ${g_bash_ini_1[*]/%+([[:space:]])/} ) # remove ending whitespace
   #fusk20221230commentout debug_1 "removed ending whitespace"

   g_bash_ini_1=( ${g_bash_ini_1[*]/%+([[:space:]])\\]/\\]} ) # remove non meaningful whitespace after sections
   #fusk20221230commentout debug_1 "removed whitespace after section name"

   if [ $BASH_VERSINFO == 3 ]
   then
      g_bash_ini_1=( ${g_bash_ini_1[*]/+([[:space:]])=/=} ) # remove whitespace before =
      g_bash_ini_1=( ${g_bash_ini_1[*]/=+([[:space:]])/=} ) # remove whitespace after =
      g_bash_ini_1=( ${g_bash_ini_1[*]/+([[:space:]])=+([[:space:]])/=} ) # remove whitespace around =
   else
      g_bash_ini_1=( ${g_bash_ini_1[*]/*([[:space:]])=*([[:space:]])/=} ) # remove whitespace around =
   fi
   #fusk20221230commentout debug_1 "removed space around ="

   g_bash_ini_1=( ${g_bash_ini_1[*]/#\\[/\}$'\n'"${PREFIX_1}"} ) # set section prefix
   #fusk20221230commentout debug_1 "set section prefix"

   local i line
   for ((i=0; i < "${#g_bash_ini_1[@]}"; i++))
   do
      line="${g_bash_ini_1[i]}"
      if [[ "$line" =~ ${PREFIX_1}.+ ]]
      then
         g_bash_ini_1[$i]=${line// /_}
      elif [[ "$line" =~ =[^\"\']  ]]     #fu.sky add@2022-12-30 i.g key=1|2|3
      then
         if [[ $(echo "${line}"|grep "\"\s*$"|wc -l) -eq 0 && $(echo "${line}"|grep "'\s*$"|wc -l) -eq 0 ]];then
             line=${line/=/=\"}
             g_bash_ini_1[$i]=${line/%/\"}
         fi
        #echo "----------------------------:$line"
      fi

      #fu.sky add@2023-03-10 i.g key='[1-9]'
      if [ $( echo "${g_bash_ini_1[$i]}"|sed  -n '/=/{/\\\[/p;/\\\]/p}'|wc -l) -gt 0 ];then  
          #echo "--------------fusktest----------------"
          g_bash_ini_1[$i]=$(echo "${g_bash_ini_1[$i]}"|sed  '/=/{s/\\\[/\[/g;s/\\\]/\]/g}')
      fi

   done
   #fusk20221230commentout debug_1 "subsections"

   g_bash_ini_1=( ${g_bash_ini_1[*]/%\\]/ \(} )   # convert text2function (1)
   #fusk20221230commentout debug_1 "convert text2function (1)"

   g_bash_ini_1=( ${g_bash_ini_1[*]/=/=\( } )     # convert item to array
   #fusk20221230commentout debug_1 "convert item to array"
   g_bash_ini_1=( ${g_bash_ini_1[*]/%/ \)} )      # close array parenthesis
   #fusk20221230commentout debug_1 "close array parenthesis"

   g_bash_ini_1=( ${g_bash_ini_1[*]/%\\ \)/ \\} ) # the multiline trick
   #fusk20221230commentout debug_1 "the multiline trick"

   g_bash_ini_1=( ${g_bash_ini_1[*]/%\( \)/\(\) \{} ) # convert text2function (2)
   #fusk20221230commentout debug_1 "convert text2function (2)"

   g_bash_ini_1=( ${g_bash_ini_1[*]/%\} \)/\}} )  # remove extra parenthesis
   #fusk20221230commentout debug_1 "remove extra parenthesis"
   g_bash_ini_1=( ${g_bash_ini_1[*]/%\{/\{$'\n''cfg_1_unset ${FUNCNAME/#'${PREFIX_1}'}'$'\n'} )  # clean previous definition of section 
   #fusk20221230commentout debug_1 "clean previous definition of section"

   g_bash_ini_1[0]=""                    # remove first element
   [[ ${g_bash_ini_1[1]} =~ ^} ]] && g_bash_ini_1[1]="" #fu.sky add@2022-12-30  i.g dos format
   #fusk20221230commentout debug_1 "remove first element"

   g_bash_ini_1[${#g_bash_ini_1[*]} + 1]='}'      # add the last brace
   #fusk20221230commentout debug_1 "add the last brace"


   eval "$(echo "${g_bash_ini_1[*]}")"   # eval the result
   EVAL_STATUS=$?
   if [ $CHANGE_EXTGLOB = 1 ]
   then
      shopt -u extglob
   fi
   IFS="$OLDIFS"
   return $EVAL_STATUS
}


function cfg_1_writer {
   local item fun newvar vars
   local SECTION f var

   SECTION=$1
   local OLDIFS="$IFS"
   IFS=' '$'\n'
   if [ -z "$SECTION" ]
   then
      fun="$(declare -F |egrep "s*${PREFIX_1}" )"
   else
      fun="$(declare -F ${PREFIX_1}${SECTION})"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" 1>&2
         exit 1
      fi
   fi
   fun="${fun//declare -f/}"
   #echo "fusktest--0----------------fun=[$fun]"
   for f in $fun; do
      [ "${f#${PREFIX_1}}" == "${f}" ] && continue
      item="$(declare -f ${f})"
      #echo "fusktest--0----------------f=[$f],item=[${item}]"
      item="${item##*\{}" # remove function definition
      item="${item##*FUNCNAME*${PREFIX_1}\};}" # remove clear section
      item="${item##*FUNCNAME*${PREFIX_1}\}}" # remove clear section
      item="${item/FUNCNAME\/#${PREFIX_1};}" # remove line
      item="${item/%\}}"  # remove function close
      item="${item%)*}" # remove everything after parenthesis
      if [[ "${item}" == $'\n' ]];then
          continue
      fi
      item="${item});" # add close parenthesis
      vars=""
      while [ "$item" != "" ]
      do
         newvar="${item%%=*}" # get item name
         vars="$vars$newvar" # add name to collection
         item="${item#*;}" # remove readed line
      done
      vars=$(echo "$vars" | sort -u) # remove duplication
      eval $f
      echo "[${f#${PREFIX_1}}]" # output section
      for var in $vars; do
         if [[ -z "$var" ]];then
             continue
         fi
         eval 'local length=${#'$var'[*]}' # test if var is an array
         if [ $length == 1 ]
         then
            echo $var=\"${!var}\" #output var
         else
            echo ";$var is an array" # add comment denoting var is an array
            eval 'echo $var=\"${'$var'[*]}\"' # output array var
         fi
      done
   done
   IFS="$OLDIFS"
}

function cfg_1_unset {
   local item fun newvar vars
   local SECTION f var OLDIFS

   SECTION=$1
   OLDIFS="$IFS"
   IFS=' '$'\n'
   if [ -z "$SECTION" ]
   then
      fun="$(declare -F)"
   else
      fun="$(declare -F ${PREFIX_1}${SECTION})"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" 1>&2
         return
      fi
   fi
   fun="${fun//declare -f/}"
   for f in $fun; do
      [ "${f#${PREFIX_1}}" == "${f}" ] && continue
      item="$(declare -f ${f})"

      item="${item##*\{}" # remove function definition
      item="${item##*FUNCNAME*${PREFIX_1}\};}" # remove clear section
      item="${item##*FUNCNAME*${PREFIX_1}\}}" # remove clear section
      item="${item/%\}}"  # remove function close
      item="${item%)*}" # remove everything after parenthesis
      if [[ "${item}" == $'\n' ]];then
          continue
      fi
      item="${item});" # add close parenthesis
      vars=""
      while [ "$item" != "" ]
      do
         newvar="${item%%=*}" # get item name
         vars="$vars $newvar" # add name to collection
         item="${item#*;}" # remove readed line
      done
      for var in $vars; do
         unset $var
      done
   done
   IFS="$OLDIFS"
}


function cfg_1_clear {
   local fun f SECTION OLDIFS
   SECTION=$1
   OLDIFS="$IFS"
   IFS=' '$'\n'
   if [ -z "$SECTION" ]
   then
      fun="$(declare -F)"
   else
      fun="$(declare -F ${PREFIX_1}${SECTION})"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" 1>&2
         exit 1
      fi
   fi
   fun="${fun//declare -f/}"
   for f in $fun; do
      [ "${f#${PREFIX_1}}" == "${f}" ] && continue
      unset -f ${f}
   done

   IFS="$OLDIFS"
}

function cfg_1_update {

   if [ $CHANGE_EXTGLOB = 1 ]
   then
      shopt -s extglob
   fi

   local fun SECTION VAR item OLDIFS
   SECTION=$1
   VAR=$2
   OLDIFS="$IFS"
   IFS=' '$'\n'
   fun="$(declare -F ${PREFIX_1}${SECTION})"
   if [ -z "$fun" ]
   then
      echo "section $SECTION not found" 1>&2
      exit 1
   fi
   fun="${fun//declare -f/}"
   item="$(declare -f ${fun})"
   item=$(echo "${item}"|sed "/^\s*${VAR}\s*=.*/d") # remove var declaration
   #item="${item//+([[:space:]])${VAR}=+([[:graph:]])/}" # remove var declaration
   item=$(echo "${item}"|sed "/^\s*${VAR}\s*=.*/d") # remove var declaration
   item="${item/%\}}"  # remove function close
   item="${item}
    $VAR=(\"${!VAR}\")
   "
   item="${item}
   }" # close function again

   eval "function $item"

   if [ $CHANGE_EXTGLOB = 1 ]
   then
      shopt -u extglob
   fi

   IFS="$OLDIFS"
    #declare -f ${fun}
}


function is_1_section()
{
    [ $# -lt 1 ] && return 1

    local fun="$(declare -F ${PREFIX_1}$1)"
    [ -z "$fun" ] && return 2

    return 0
}


function is_1_key()
{
    [ $# -lt 1 ] && return 1

    local VAR=$1
    local tt=${!VAR-x-----null}
    [ "1${tt}" == "1x-----null" ] && return 3

    return 0
}


#Determine whether the ini file has the corresponding configuration
function is_1_ini_cfg()
{
    local ret
    is_1_section "$1"
    ret=$?
    [ ${ret} -ne 0 ] && return ${ret}

    if [ $# -gt 1 ];then
        is_1_key "$2"
        ret=$?
        [ ${ret} -ne 0 ] && return ${ret}
    fi

    return 0
}




# vim: filetype=sh
