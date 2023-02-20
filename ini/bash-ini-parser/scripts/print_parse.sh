#!/bin/bash

if [ "$#" -ne 1 ]
then
  echo provide 1 parameters
  echo "$0 <ini.file> "
  exit 1
fi

TEST_FILE="${1:-file.ini}"

#export BASH_INI_PARSER_DEBUG=1 

echo -e "\n\t ini file:[${TEST_FILE}]\n"

source $(dirname $0)/../bash-ini-parser

echo parsing $TEST_FILE
cfg_parser "$TEST_FILE"
echo

echo --parse result-- 
echo "------------------------------------------------------------------------------"
    OLDIFS="$IFS"
    IFS=$'\n'
    echo "${ini[*]}"
    IFS="$OLDIFS"
echo "------------------------------------------------------------------------------"
echo --end--

echo -e "\n"
echo "cfg_writer print"
echo "------------------------------------------------------------------------------"
cfg_writer
echo "------------------------------------------------------------------------------"
echo -e "\n"
