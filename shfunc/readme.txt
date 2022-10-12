
/*************************************************
*
*  date:2022/10/12-09:40:11.703667665
*
*  desc:The list of functions in file 
*       diyFuncBysky.func
*
*************************************************/


-----------------------------------------------
-1- : function getFnameOnPath() #get the file name in the path string 
-2- : function getPathOnFname() #get the path value in the path string(the path does not have / at the end) 
-3- : function chgUandGzfmd() #chown -R $1:$2 $3 if there is a user $1 user group $2,file or directory $3 
-4- : function chgUandGRx() #Recursive $4 from the $3 to determine if there is a non-conformity for each layer's attributes.chown -R $1:$2 
-5- : function chgUandGRbyName() #Recursively modify the owner and group of the directory until the directory name is $4; chown -R $1:$2 $3 
-6- : function setPermission() #chown -R $2 $1 if the file or directory $1 exists and permission are not equal to $2 
-7- : function mkpDir() #create and echo directory if there is no $1 directory 
-8- : function getlsattrI() #get immutable  (i) file attributes 
-9- : function addattrI() #add  immutable  (i) file attributes on a Linux file system 
-10- : function delattrI() #delete  immutable  (i) file attributes on a Linux file system 
-11- : function updateFile() #if the file $1 is different from the md5 code of $2 or $2 does not exist then cp $1 $2 
-12- : function chgUPwd() #change the password of user $1 with ciphertext $2 encrypted SHA512,and do not modify it repeatedly 
-13- : function mkdirFromXml()  #take all the node values named $2 from the xml file $1 to create the directory,the element value of the xml file must be on one line 
-14- : function groupAdd() #groupadd $1 if there is no $1 
-15- : function useraddOrChgrp() # add user or change user's group; useraddOrChgrp $user $group OR useraddOrChgrp $user $group $addgroup 
-16- : function setEnvOneVal() #set the value of the configuration file;eg:setEnvOneVal ${file} "set" "encoding" "set encoding=utf-8"   '"' 'positition_character' 
-----------------------------------------------


/*************************************************
*
*  date:2022/10/12-09:40:11.719900383
*
*  desc:The list of functions in file 
*       shfunclib.sh
*
*************************************************/


-----------------------------------------------
-1- : function F_writeLog() #call eg: F_writeLog "$ERROR" "${LINENO}|${FUNCNAME}|some message!n" 
-2- : function F_reduceFileSize() #call eg: F_reduceFileSize "/zfmd/out_test.csv" "4" 
-----------------------------------------------

