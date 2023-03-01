
# sftpPutFromDir����˵��

> sftpPutFromDir����:     
>        ���ݽű���ͬ��Ŀ¼���������ļ�cfg/cfg.cfg���õ�������Դ�ļ���sftp�ϴ���     
>        sftp������,�ϴ��ɹ���ԴĿ¼���ļ�ɾ��     
>        �ڽű�ͬ��Ŀ¼ tmp/back�»ᱸ��10��֮���ϴ��ɹ����ļ�     

## ������

### 1.ȷ��Ҫ�������ļ���������ϵͳ�û�

����Ҫ�������ļ�����root�û�Ҫ���ɵ���,���ļ�����ϵͳ�û�����Ϊroot

### 2. �õ�1��ȷ���Ĳ���ϵͳ�û���¼������

### 3. ��sftpPutFromDirѹ�������������

### 4. ȷ��sftpPutFromDir����ϵͳ�ĸ�Ŀ¼

���糣�õ���������Ŀ¼�� `/fglyc/wpfs17/` ��sftpPutFromDirѹ������ѹ����ļ���sftpPutFromDir���� `/fglyc/wpfs17/`Ŀ¼��

### 5. �ڲ����Ŀ¼sftpPutFromDir�´������ļ���������

����:�㽫 sftpPutFromDir�ļ��з����� `/fglyc/wpfs17/sftpPutFromDir` ��������ļ� `/fglyc/wpfs17/sftpPutFromDir/cfg/cfg.cfg`�ļ����б༭,���ļ���Ҫ�����ļ������ò���,��sftp�������ò���,���µ��������õ���
�ϴ��������ɵĶ��ںͳ������ļ���sftp�ϴ���192.168.0.14������������:

```

##################################################
#            Ҫ�����ļ�Ŀ¼���ļ�����
#
# g_src_dir[0]=""                 #��Ҫ���ӵĵ�һ��Դ�ļ�Ŀ¼
# g_file_name[0]="*.txt|*.xml"    #��һ��Դ�ļ���Ҫ���ӵ��ļ���֧��ͨƥ��,����ж���ļ�������|�ָ�
# g_basicCondition_sec[0]=30      #���õ�һ��Դ�ļ���Ӧ�ļ�������û�г����޸�ʱ��仯���ϴ�
#                                 #����30�����ʾ g_src_dir[0]Ŀ¼�е��ļ�����30�����޸�ʱ�䶼û�仯��������sftp�ϴ�
#
# ����еڶ���Ŀ¼��Ҫ�����������ı�������������һ�飬��[0]��Ҫ�ĳ�1
# �Դ����ƣ��е�n�ļ�Ŀ¼��Ҫ�����������������ã���[0]�ĳ�n-1
#
#
##################################################
#

#�ϴ������ļ��ͳ������ļ��м���������
g_src_dir[0]="/zfmd/wpfs20/zg"   
g_file_name[0]="yn_72wind_*.rb|yn_4Cwind_*.rb"
g_basicCondition_sec[0]=9




##################################################
#            Ҫ�ϴ���sftp����������
#
# g_ser_ip[0]=""             #sftp������ip
# g_ser_username[0]=""       #sftp�������û���
# g_ser_password[0]=""       #sftp����������
# g_ser_port[0]=""           #sftp�������˿�
# g_ser_dir[0]=""            #sftp���������ϴ�Ŀ¼
#
#
# ����еڶ���stp��������Ҫ�ϴ��������ı�������������һ�飬��[0]��Ҫ�ĳ�1
# �Դ����ƣ��е�n��stp�������������������������ã���[0]�ĳ�n-1
#
#
##################################################


g_ser_ip[0]="192.168.0.14"                     
g_ser_username[0]="zfmd"   
g_ser_password[0]="zfmd"  
g_ser_port[0]="22"     
g_ser_dir[0]="/zfmd/wpfs20/tt"                



```

### 6. ȷ��ϵͳ���Ƿ�װ�� nc �� lftp ����

��ϵͳ�������һ���ն�ִ����������:

```
   which lftp
```

```
    which  nc
```

�������������Ϣ���ʾϵͳ������lftp��nc

```
    /usr/bin/lftp
```

```
    /usr/bin/nc
```

���ϵͳ��û��nc��lftp��������Ҫ��ϵͳ����Ա������Ӧ�İ�װ��,��root�û��¶�����а�װ


### 7. ��sftpPutFromDir�ű�������������

��sftpPutFromDir�����������������ַ���:

����1: ���ű�sftpPutFromDir.sh����ϵͳ��crontab��;
����2: ���ű�sftpPutFromDir.sh����������������,��ǰ����ϵͳ���Ѿ�����������������.

�Ƽ�ʹ�õ�2�ַ���

�ٶ�ϵͳ������������������`/fglyc/wpfs20/startup`��,����������ĵ������ļ�(����root�û��µ������������� rcfgRoot.cfg�ļ�,�����û��µ������������� rcfg.cfg�ļ�)
��������������:

```

[sftpPutFromDir.sh]                 
logDir=/zfmd/wpfs20/sftpPutFromDir/ttylog
runPath=/zfmd/wpfs20/sftpPutFromDir
runPrePara=
runPara=

```

### 8. ���sftpPutFromDir����־�Ƿ��б������������

���������úú�,��������(һ����1���Ӻ�) sftpPutFromDir.sh�ű��ͻ��Զ�����,Ȼ��鿴��־�Ƿ�����,�Ƿ������ϴ��ļ�����.

