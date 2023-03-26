#
# based on http://theoldschooldevops.com/2008/02/09/bash-ini-parser/
#

#Multiple ini files can be processed at the same time, and the 
#  same ini file is distinguished by the same index number idx
#

#Determine whether the index is a number
#return state: 1 wrong; 0 right
# F_right_index <idx>
function F_right_index()
{
    [ $# -ne 1 ] && return 1

    if [ $(echo "$1"|sed -n '/\(^[0-9]$\|^[1-9][0-9]\+$\)/p'|wc -l) -gt 0 ];then 
        return 0
    fi

    #[ "x${1}" = "x0" ] && return 0
    #[ "x${1}" = "x1" ] && return 0

    return 1
}

#Output the contents of g_bash_ini_${idx}
# F_ini_debug <idx> [arg]
function F_ini_debug {

    [ "x${BASH_INI_PARSER_DEBUG}" == "x" ] && return 0

    local ret
    F_right_index "$1" ; ret=$?
    [ ${ret} -ne 0 ] && return 0

    local tVar="g_bash_ini_${1}[*]"
    shift

    echo
    echo --start-- $*
    echo "${!tVar}"
    echo --end--
    echo

}




#F_ini_cfg_parser <idx> <ini_file>
function F_ini_cfg_parser {

    if [ $# -ne 2 ];then
        echo ""
        echo "ERROR|${FUNCNAME}|The number of input parameters is not equal to 2"
        echo ""
        exit 1
    fi

    local ret idx
    idx="$1"
    F_right_index "${idx}" ; ret=$?
    if [ ${ret} -ne 0 ];then 
        echo ""
        echo "ERROR|${FUNCNAME}|The first input parameter of the function (the index number of the ini file) \"${idx}\" is not a number"
        echo ""
        exit 2
    fi
    shift

    if [ ! -f "$1" ];then
        echo ""
        echo "ERROR|${FUNCNAME}|file [ $1 ] does not exist!"
        echo ""
        exit 1
    fi


    ##取变量PREFIX_x的值
    #local varPre="PREFIX_${idx}"
    #local tPreFix="${!varPre}"
    local tPreFix="cfg_${idx}_section_"

    shopt -p extglob &> /dev/null
    CHANGE_EXTGLOB=$?
    [ $CHANGE_EXTGLOB = 1 ] && shopt -s extglob

    local tmp_ini

    #tmp_ini="$(<$1)"                 # read the file
    #tmp_ini=${tmp_ini//$'\r'/}         # remove linefeed i.e dos2unix

    # read the file and 
    # 1. remove linefeed i.e dos2unix 
    # 2. 去掉;或#的行注释  去掉;或#的行尾注释
    # 3. 去掉空行
    # 4. 去掉行首和行尾的空格
    #           s/\r$//g;
    #           s/^\s*[;#]\+.*//g; s/\s\+[;#]\+[^"'\'']*$//g;
    #           /^\s*$/d;
    #           s/^\s\+//g; s/\s\+$//g;
    tmp_ini="$(sed 's/\r$//g;s/^\s*[;#]\+.*//g; s/\s\+[;#]\+[^"'\'']*$//g;/^\s*$/d;s/^\s\+//g; s/\s\+$//g' "$1")"

    #如果ini配置文件存在没有section的key(没有时只能发生在文件开头)时则自动
    #添加AUTOADD_ROOT的section
    local tnum="$(echo "${tmp_ini}"|sed -n '1{/^\[/p;q}'|wc -l)"
    if [ ${tnum} -eq 0 ];then
        tmp_ini="[AUTOADD_ROOT]
${tmp_ini}"
    fi

    #echo "fusktest:tmp_ini->[${tmp_ini}]"

    local OLDIFS="$IFS"
    IFS=$'\n' && tmp_ini=( "${tmp_ini}" )  # convert to line-array

    #
    # 第一个sed:
    # 1.将域名的[或]左右空格去掉; [转换成\[ 将域名的]转换成\]; 将域名的空格转换成_
    # 2. 去掉=号左右的空格
    # 3. 等号右边没有引号的加引号
    # 4. 将\[变成}\ncfg_${idx}_section_
    #    将\]变成 () {\n F_ini_inner_unset ${idx} {FUNCNAME/#cfg_x_section_}
    # 5  在末尾加上}
    # 
    # 第二个sed:
    # 1 去掉第一行的}
    #
    tmp_ini=( $(echo "${tmp_ini[*]}"|sed ' 
           /^\s*\[/{s+^\s*\[\s*+\\[+g; s+\s*\]\s*$+\\]+g;s/\s\+/_/g}; 
           s/\s*=\s*/=/g;
           /^[^\\]/{s/=\([^"'\'']\)\(.*\)/="\1\2"/g;s/\\\[/\[/g;s/\\\]/\]/g};
           /^\\\[/{s/^\\\[/\}\n'${tPreFix}'/g;s/\\\]/ \(\) \{\nF_ini_inner_unset '${idx}' \$\{FUNCNAME\/#'${tPreFix}'\}/g  };
          $ a\}
          '|sed '1d') )

    #echo "tmp_ini=[${tmp_ini[*]}]"

    if [ "x${BASH_INI_PARSER_DEBUG}" != "x" ];then
        #定义全局变量名:g_bash_ini_x
        local varGIni="g_bash_ini_${idx}"

        #赋值给g_bash_ini_x
        #g_bash_ini_0=( "${tmp_ini[*]}" )
        eval "${varGIni}=( \"\${tmp_ini[*]}\" )"
    fi

    #F_ini_debug "${idx}" "result"

    eval "$(echo "${tmp_ini[*]}")"   # eval the result
    EVAL_STATUS=$?

    [ $CHANGE_EXTGLOB = 1 ] && shopt -u extglob
    IFS="$OLDIFS"

    return $EVAL_STATUS
}


# F_ini_cfg_writer <idx> [section]
function F_ini_cfg_writer {
    if [ $# -lt 1 ];then
        echo ""
        echo "ERROR|${FUNCNAME}|The number of input parameters is less than 1"
        echo ""
        exit 1
    fi

    local ret idx
    idx="$1"
    F_right_index "${idx}" ; ret=$?
    if [ ${ret} -ne 0 ];then 
        echo ""
        echo "ERROR|${FUNCNAME}|The first input parameter of the function (the index number of the ini file) \"${idx}\" is not a number"
        echo ""
        exit 2
    fi
    shift

    ##取变量PREFIX_x的值
    #local varPre="PREFIX_${idx}"
    #local tPreFix="${!varPre}"
    local tPreFix="cfg_${idx}_section_"

    local item fun newvar vars
    local SECTION f var

    [ ! -z "$1" ] && SECTION="$1"
    local OLDIFS="$IFS"
    IFS=' '$'\n'
    if [ -z "$SECTION" ]
    then
      fun="$(declare -F |egrep "s*${tPreFix}" )"
    else
      fun="$(declare -F ${tPreFix}${SECTION})"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" 1>&2
         exit 1
      fi
    fi

    fun="${fun//declare -f/}"
    #echo "fusktest--0----------------fun=[$fun]"
    for f in $fun; do
      [ "${f#${tPreFix}}" == "${f}" ] && continue
      item="$(declare -f ${f})"
      #echo "fusktest--0----------------f=[$f],item=[${item}]"
      item="${item##*\{}" # remove function definition
      item="${item##*FUNCNAME*${tPreFix}\};}" # remove clear section
      item="${item##*FUNCNAME*${tPreFix}\}}" # remove clear section
      item="${item/FUNCNAME\/#${tPreFix};}" # remove line
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
      echo "[${f#${tPreFix}}]" # output section
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


# 内部使用,没有做过多检验,外部使用请用F_ini_cfg_unset
# F_ini_inner_unset <idx> [section]
function F_ini_inner_unset {

    local idx="$1"
    shift

    ##取变量PREFIX_x的值
    #local varPre="PREFIX_${idx}"
    #local tPreFix="${!varPre}"
    local tPreFix="cfg_${idx}_section_"

    local item fun newvar vars
    local SECTION f var OLDIFS

    [ ! -z "$1" ] && SECTION="$1"
    OLDIFS="$IFS"
    IFS=' '$'\n'
    if [ -z "$SECTION" ]
    then
      fun="$(declare -F)"
    else
      fun="$(declare -F ${tPreFix}${SECTION})"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" 1>&2
         return
      fi
    fi
    fun="${fun//declare -f/}"
    for f in $fun; do
      [ "${f#${tPreFix}}" == "${f}" ] && continue
      item="$(declare -f ${f})"

      item="${item##*\{}" # remove function definition
      item="${item##*FUNCNAME*${tPreFix}\};}" # remove clear section
      item="${item##*FUNCNAME*${tPreFix}\}}" # remove clear section
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



# F_ini_cfg_unset <idx> [section]
function F_ini_cfg_unset {

    if [ $# -lt 1 ];then
        echo ""
        echo "ERROR|${FUNCNAME}|The number of input parameters is less than 1"
        echo ""
        exit 1
    fi

    local ret idx
    idx="$1"
    F_right_index "${idx}" ; ret=$?
    if [ ${ret} -ne 0 ];then 
        echo ""
        echo "ERROR|${FUNCNAME}|The first input parameter of the function (the index number of the ini file) \"${idx}\" is not a number"
        echo ""
        exit 2
    fi
    shift

    ##取变量PREFIX_x的值
    #local varPre="PREFIX_${idx}"
    #local tPreFix="${!varPre}"
    local tPreFix="cfg_${idx}_section_"

    local item fun newvar vars
    local SECTION f var OLDIFS

    [ ! -z "$1" ] && SECTION="$1"
    OLDIFS="$IFS"
    IFS=' '$'\n'
    if [ -z "$SECTION" ]
    then
      fun="$(declare -F)"
    else
      fun="$(declare -F ${tPreFix}${SECTION})"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" 1>&2
         return
      fi
    fi
    fun="${fun//declare -f/}"
    for f in $fun; do
      [ "${f#${tPreFix}}" == "${f}" ] && continue
      item="$(declare -f ${f})"

      item="${item##*\{}" # remove function definition
      item="${item##*FUNCNAME*${tPreFix}\};}" # remove clear section
      item="${item##*FUNCNAME*${tPreFix}\}}" # remove clear section
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



# F_ini_cfg_clear <idx> [section]
function F_ini_cfg_clear {
    if [ $# -lt 1 ];then
        echo ""
        echo "ERROR|${FUNCNAME}|The number of input parameters is less than 1"
        echo ""
        exit 1
    fi

    local ret idx
    idx="$1"
    F_right_index "${idx}" ; ret=$?
    if [ ${ret} -ne 0 ];then 
        echo ""
        echo "ERROR|${FUNCNAME}|The first input parameter of the function (the index number of the ini file) \"${idx}\" is not a number"
        echo ""
        exit 2
    fi
    shift

    ##取变量PREFIX_x的值
    #local varPre="PREFIX_${idx}"
    #local tPreFix="${!varPre}"
    local tPreFix="cfg_${idx}_section_"

   local fun f SECTION OLDIFS
   [ ! -z "$1" ] && SECTION="$1"
   OLDIFS="$IFS"
   IFS=' '$'\n'
   if [ -z "$SECTION" ]
   then
      fun="$(declare -F)"
   else
      fun="$(declare -F ${tPreFix}${SECTION})"
      if [ -z "$fun" ]
      then
         echo "section $SECTION not found" 1>&2
         exit 1
      fi
   fi
   fun="${fun//declare -f/}"
   for f in $fun; do
      [ "${f#${tPreFix}}" == "${f}" ] && continue
      unset -f ${f}
   done

   IFS="$OLDIFS"
}




# F_ini_cfg_update <idx> <section> <key>
function F_ini_cfg_update {

    if [ $# -ne 3 ];then
        echo ""
        echo "ERROR|${FUNCNAME}|The number of input parameters is not equal to 3"
        echo ""
        exit 1
    fi

    local ret idx
    idx="$1"
    F_right_index "${idx}" ; ret=$?
    if [ ${ret} -ne 0 ];then 
        echo ""
        echo "ERROR|${FUNCNAME}|The first input parameter of the function (the index number of the ini file) \"${idx}\" is not a number"
        echo ""
        exit 2
    fi
    shift

    ##取变量PREFIX_x的值
    #local varPre="PREFIX_${idx}"
    #local tPreFix="${!varPre}"
    local tPreFix="cfg_${idx}_section_"

    if [ $CHANGE_EXTGLOB = 1 ]
    then
      shopt -s extglob
    fi

    local fun SECTION VAR item OLDIFS
    SECTION="$1"
    VAR="$2"
    OLDIFS="$IFS"
    IFS=' '$'\n'
    fun="$(declare -F ${tPreFix}${SECTION})"
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



# F_ini_is_section <idx> <section>
function F_ini_is_section()
{
    if [ $# -ne 2 ];then
        echo ""
        echo "ERROR|${FUNCNAME}|The number of input parameters is not equal to 2"
        echo ""
        exit 1
    fi

    local ret idx
    idx="$1"
    F_right_index "${idx}" ; ret=$?
    if [ ${ret} -ne 0 ];then 
        echo ""
        echo "ERROR|${FUNCNAME}|The first input parameter of the function (the index number of the ini file) \"${idx}\" is not a number"
        echo ""
        exit 2
    fi
    shift

    ##取变量PREFIX_x的值
    #local varPre="PREFIX_${idx}"
    #local tPreFix="${!varPre}"
    local tPreFix="cfg_${idx}_section_"

    local fun="$(declare -F ${tPreFix}$1)"
    [ -z "$fun" ] && return 2

    return 0
}



# F_ini_enable_section <idx> <section>
function F_ini_enable_section()
{
    if [ $# -ne 2 ];then
        echo ""
        echo "ERROR|${FUNCNAME}|The number of input parameters is not equal to 2"
        echo ""
        exit 1
    fi

    local ret idx
    idx="$1"
    F_right_index "${idx}" ; ret=$?
    if [ ${ret} -ne 0 ];then 
        echo ""
        echo "ERROR|${FUNCNAME}|The first input parameter of the function (the index number of the ini file) \"${idx}\" is not a number"
        echo ""
        exit 2
    fi
    shift

    ##取变量PREFIX_x的值
    #local varPre="PREFIX_${idx}"
    local tPreFix="cfg_${idx}_section_"
    local tfun="${tPreFix}${1}"

    local fun="$(declare -F ${tfun})"
    [ -z "$fun" ] && return 2

    ${tfun}

    return 0
}




# F_ini_is_key <key>
function F_ini_is_key()
{
    local VAR="$1"
    local tt=${!VAR-x-----null}
    [ "1${tt}" == "1x-----null" ] && return 3

    return 0
}



#Determine whether the ini file has the corresponding configuration
# F_ini_is_cfg ${index} <section> [key]
function F_ini_is_cfg()
{
    if [ $# -lt 2 ];then
        echo ""
        echo "ERROR|${FUNCNAME}|The number of input parameters is not equal to 2"
        echo ""
        exit 1
    fi

    local ret idx
    idx="$1"
    F_right_index "${idx}" ; ret=$?
    if [ ${ret} -ne 0 ];then 
        echo ""
        echo "ERROR|${FUNCNAME}|The first input parameter of the function (the index number of the ini file) \"${idx}\" is not a number"
        echo ""
        exit 2
    fi
    shift

    local ret

    ##取变量PREFIX_x的值
    #local varPre="PREFIX_${idx}"
    #local tPreFix="${!varPre}"
    local tPreFix="cfg_${idx}_section_"

    local fun="$(declare -F ${tPreFix}$1)"
    [ -z "$fun" ] && return 2

    if [ $# -gt 1 ];then
        F_ini_is_key "$2"
        ret=$?
        [ ${ret} -ne 0 ] && return ${ret}
    fi

    return 0
}


# vim: filetype=sh
