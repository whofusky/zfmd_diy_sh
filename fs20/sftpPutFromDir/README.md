
# sftpPutFromDir部署说明

> sftpPutFromDir功能:     
>        根据脚本的同级目录下有配置文件cfg/cfg.cfg配置的条件将源文件用sftp上传到     
>        sftp服务器,上传成功则将源目录的文件删除     
>        在脚本同级目录 tmp/back下会备份10天之内上传成功的文件     

## 部署步骤

### 1.确定要拷贝的文件所属操作系统用户

比如要拷贝的文件是在root用户要生成的则,此文件操作系统用户属主为root

### 2. 用第1步确定的操作系统用户登录服务器

### 3. 将sftpPutFromDir压缩包导入服务器

### 4. 确定sftpPutFromDir放于系统哪个目录

比如常用的软件部署目录是 `/fglyc/wpfs17/` 则将sftpPutFromDir压缩包解压后的文件夹sftpPutFromDir放于 `/fglyc/wpfs17/`目录下

### 5. 在部署的目录sftpPutFromDir下打开配置文件进行配置

例如:你将 sftpPutFromDir文件夹放于了 `/fglyc/wpfs17/sftpPutFromDir` 则打开配置文件 `/fglyc/wpfs17/sftpPutFromDir/cfg/cfg.cfg`文件进行编辑,此文件主要配置文件夹配置部分,和sftp服务配置部署,如下的样例配置的是
上传软件生成的短期和超短期文件用sftp上传到192.168.0.14服务器的例子:

```

##################################################
#            要处理文件目录及文件设置
#
# g_src_dir[0]=""                 #需要监视的第一个源文件目录
# g_file_name[0]="*.txt|*.xml"    #第一个源文件需要监视的文件（支持通匹符,如果有多个文件类型用|分隔
# g_basicCondition_sec[0]=30      #设置第一个源文件对应文件多少秒没有出现修改时间变化就上传
#                                 #例如30，则表示 g_src_dir[0]目录中的文件出现30秒内修改时间都没变化则对其进行sftp上传
#
# 如果有第二个目录需要监视则把上面的变量都新增设置一遍，但[0]需要改成1
# 以此类推，有第n文件目录需要设置则新增上面设置，把[0]改成n-1
#
#
##################################################
#

#上传短期文件和超短期文件夹及名称配置
g_src_dir[0]="/zfmd/wpfs20/zg"   
g_file_name[0]="yn_72wind_*.rb|yn_4Cwind_*.rb"
g_basicCondition_sec[0]=9




##################################################
#            要上传的sftp服务器设置
#
# g_ser_ip[0]=""             #sftp服务器ip
# g_ser_username[0]=""       #sftp服务器用户名
# g_ser_password[0]=""       #sftp服务器密码
# g_ser_port[0]=""           #sftp服务器端口
# g_ser_dir[0]=""            #sftp服务器的上传目录
#
#
# 如果有第二个stp服务器需要上传则把上面的变量都新增设置一遍，但[0]需要改成1
# 以此类推，有第n个stp服务器的设置则新增上面设置，把[0]改成n-1
#
#
##################################################


g_ser_ip[0]="192.168.0.14"                     
g_ser_username[0]="zfmd"   
g_ser_password[0]="zfmd"  
g_ser_port[0]="22"     
g_ser_dir[0]="/zfmd/wpfs20/tt"                



```

### 6. 确认系统中是否安装有 nc 和 lftp 软件

在系统的桌面打开一个终端执行如下命令:

```
   which lftp
```

```
    which  nc
```

如果返回如下信息则表示系统中已有lftp和nc

```
    /usr/bin/lftp
```

```
    /usr/bin/nc
```

如果系统中没有nc和lftp工具则需要向系统管理员索引相应的安装包,在root用户下对其进行安装


### 7. 将sftpPutFromDir脚本加入自启动中

将sftpPutFromDir加入自启动中有两种方法:

方法1: 将脚本sftpPutFromDir.sh加入系统的crontab中;
方法2: 将脚本sftpPutFromDir.sh加入自启动软件中,但前提是系统中已经部署了自启动软件.

推荐使用第2种方法

假定系统的自启动软件部署在`/fglyc/wpfs20/startup`下,则打开自启动的的配置文件(配置root用户下的软件自启动打开 rcfgRoot.cfg文件,其他用户下的软件自启动打开 rcfg.cfg文件)
添加如下配置项:

```

[sftpPutFromDir.sh]                 
logDir=/zfmd/wpfs20/sftpPutFromDir/ttylog
runPath=/zfmd/wpfs20/sftpPutFromDir
runPrePara=
runPara=

```

### 8. 检查sftpPutFromDir的日志是否有报错及其他情况

自启动配置好后,过几分钟(一般是1分钟后) sftpPutFromDir.sh脚本就会自动启动,然后查看日志是否正常,是否正常上传文件即可.


