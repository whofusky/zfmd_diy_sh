
/*************************************************
*
*  date:2022/10/13-16:15:55.053846247
*
*  desc:The list of functions in file 
*       diyFuncBysky.func
*
*************************************************/


-----------------------------------------------
-1- : function chgUandGzfmd() #chown -R $1:$2 $3 if there is a user $1 user group $2,file or directory $3 
-2- : function chgUandGRx() #Recursive $4 from the $3 to determine if there is a non-conformity for each layer's attributes.chown -R $1:$2 
-3- : function chgUandGRbyName() #Recursively modify the owner and group of the directory until the directory name is $4; chown -R $1:$2 $3 
-4- : function setPermission() #chown -R $2 $1 if the file or directory $1 exists and permission are not equal to $2 
-5- : function getlsattrI() #get immutable  (i) file attributes 
-6- : function addattrI() #add  immutable  (i) file attributes on a Linux file system 
-7- : function delattrI() #delete  immutable  (i) file attributes on a Linux file system 
-8- : function updateFile() #if the file $1 is different from the md5 code of $2 or $2 does not exist then cp $1 $2 
-9- : function chgUPwd() #change the password of user $1 with ciphertext $2 encrypted SHA512,and do not modify it repeatedly 
-10- : function mkdirFromXml()  #take all the node values named $2 from the xml file $1 to create the directory,the element value of the xml file must be on one line 
-11- : function groupAdd() #groupadd $1 if there is no $1 
-12- : function useraddOrChgrp() # add user or change user's group; useraddOrChgrp $user $group OR useraddOrChgrp $user $group $addgroup 
-13- : function setEnvOneVal() #set the value of the configuration file;eg:setEnvOneVal ${file} "set" "encoding" "set encoding=utf-8"   '"' 'positition_character' 
-----------------------------------------------


/*************************************************
*
*  date:2022/10/13-16:15:55.071253148
*
*  desc:The list of functions in file 
*       shfunclib.sh
*
*************************************************/


-----------------------------------------------
-1- : function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!n" 
-2- : function F_mkpDir() #call eg: F_mkpDir "tdir1" "tdir2" ... "tdirn" 
-3- : function F_rmFile() #call eg: F_rmFile "file1" "file2" ... "$filen" 
-4- : function F_getFileName() #get the file name in the path string 
-5- : function F_getPathName() #get the path value in the path string(the path does not have / at the end) 
-6- : function F_reduceFileSize() #call eg: F_reduceFileSize "/zfmd/out_test.csv" "4" 
-7- : function F_isDigital() # return 1: digital; 0: not a digital 
-8- : function F_shHaveRunThenExit()  #Exit if a script is already running 
-9- : function F_rmExpiredFile() #call eg: F_rmExpiredFile "path" "days" OR F_rmExpiredFile "path" "days" "files" 
-10- : function F_checkSysCmd() #call eg: F_checkSysCmd "cmd1" "cmd2" ... "cmdn" 
-11- : function F_convertVLineToSpace() #Convert vertical lines to spaces 
-12- : function F_judgeFileOlderXSec() # return 0:false; 1:ture 
-----------------------------------------------

