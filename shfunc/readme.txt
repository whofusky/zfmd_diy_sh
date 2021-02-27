
/*************************************************
*
*  date:2018/12/27-15:34:02.006827118
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
-5- : function mkpDir() #create and echo directory if there is no $1 directory 
-6- : function updateFile() #if the file $1 is different from the md5 code of $2 or $2 does not exist then cp $1 $2 
-7- : function chgUPwd() #change the password of user $1 with ciphertext $2 encrypted SHA512,and do not modify it repeatedly 
-8- : function mkdirFromXml()  #take all the node values named $2 from the xml file $1 to create the directory,the element value of the xml file must be on one line 
-9- : function groupAdd() #groupadd $1 if there is no $1 
-10- : function useraddOrChgrp() # add user or change user's group; useraddOrChgrp $user $group OR useraddOrChgrp $user $group $addgroup 
-11- : function setEnvOneVal() #set the value of the configuration file;eg:setEnvOneVal ${file} "set" "encoding" "set encoding=utf-8"   '"' 'positition_character' 
-----------------------------------------------

