
# cpFileToDir����˵��

> cpFileToDir����:     
>        ���ݽű���ͬ��Ŀ¼�������ļ�cfg/cfg.cfg���õ�������Դ�ļ�������    
>        Ŀ��Ŀ¼    
>        �ڽű�ͬ��Ŀ¼ tmp/back�»��¼1��֮�ڿ����ɹ����ļ����Է�ֹ�ظ�����    

## ������

### 1.ȷ��Ҫ�������ļ���������ϵͳ�û�

����Ҫ�������ļ�����root�û�Ҫ���ɵ���,���ļ�����ϵͳ�û�����Ϊroot

### 2. �õ�1��ȷ���Ĳ���ϵͳ�û���¼������

### 3. ��cpFileToDirѹ�������������

### 4. ȷ��cpFileToDir����ϵͳ�ĸ�Ŀ¼

���糣�õ���������Ŀ¼�� `/fglyc/wpfs17/` ��cpFileToDirѹ������ѹ����ļ���cpFileToDir���� `/fglyc/wpfs17/`Ŀ¼��

### 5. �ڲ����Ŀ¼cpFileToDir�´������ļ���������

����:�㽫 cpFileToDir�ļ��з����� `/fglyc/wpfs17/cpFileToDir` ��������ļ� `/fglyc/wpfs17/cpFileToDir/cfg/cfg.cfg`�ļ����б༭,���ļ���Ҫ�����ļ������ò���,���µ��������õ���
�����ϴ��������ɵĶ��ںͳ������ļ���E�ļ��������մ�������:

```

##################################################
#            Ҫ�����ļ�Ŀ¼���ļ�����
#
# g_src_dir[0]=""                 #��Ҫ���ӵĵ�һ��Դ�ļ�Ŀ¼
# g_dst_dir[0]=""                 #�����һ��Դ�ļ�Ŀ¼�з���Ҫ���ļ������ƶ�����Ŀ¼
# g_file_name[0]="*.txt|*.xml"    #��һ��Դ�ļ���Ҫ���ӵ��ļ���֧��ͨƥ��,����ж���ļ�������|�ָ�
# g_basicCondition_sec[0]=30      #���õ�һ��Դ�ļ���Ӧ�ļ�������û�г����޸�ʱ��仯���ƶ�
#                                 #����30�����ʾ g_src_dir[0]Ŀ¼�е��ļ�����30�����޸�ʱ�䶼û�仯���������ƶ���g_dst_dir[0]Ŀ¼ 
#
# ����еڶ���Ŀ¼��Ҫ�����������ı�������������һ�飬��[0]��Ҫ�ĳ�1
# �Դ����ƣ��е�n�ļ�Ŀ¼��Ҫ�����������������ã���[0]�ĳ�n-1
#
#
##################################################
#

#�ϴ���������Ŀ¼
g_dhp_dir="/home/code/Upload_general_V2_YN/build-Upload_JX_102-Desktop-Release"
#e�ı�����Ŀ¼
g_eds_dir="/zfmd/wpfs20/zg"

#�ϴ�Ŀ¼�Ķ����ļ�
g_src_dir[0]="${g_dhp_dir}/${g_curY}/${g_curm}/${g_curd}/DQ"   
g_dst_dir[0]="${g_eds_dir}"
g_file_name[0]="yn_72wind_${g_tomYmd}.rb"
g_basicCondition_sec[0]=7

#�ϴ�Ŀ¼���ֶ������ļ�
g_src_dir[1]="${g_dhp_dir}/${g_curY}/${g_curm}/${g_curd}/hand_DQ"   
g_dst_dir[1]="${g_eds_dir}"
g_file_name[1]="yn_72wind_${g_tomYmd}.rb"
g_basicCondition_sec[1]=7


#�ϴ�Ŀ¼�ĳ������ļ�
g_src_dir[2]="${g_dhp_dir}/${g_curY}/${g_curm}/${g_curd}/CDQ"   
g_dst_dir[2]="${g_eds_dir}"
g_file_name[2]="yn_4Cwind_${g_15mYmd}*.rb"
g_basicCondition_sec[2]=7

```

### 6. ��cpFileToDir�ű�������������

��cpFileToDir�����������������ַ���:

����1: ���ű�cpFileToDir.sh����ϵͳ��crontab��;
����2: ���ű�cpFileToDir.sh����������������,��ǰ����ϵͳ���Ѿ�����������������.

�Ƽ�ʹ�õ�2�ַ���

�ٶ�ϵͳ������������������`/fglyc/wpfs20/startup`��,����������ĵ������ļ�(����root�û��µ������������� rcfgRoot.cfg�ļ�,�����û��µ������������� rcfg.cfg�ļ�)
��������������:

```

[cpFileToDir.sh]                 
logDir=/fglyc/wpfs17/cpFileToDir/ttylog
runPath=/fglyc/wpfs17/cpFileToDir
runPrePara=
runPara=

```

### 7. ���cpFileToDir����־�Ƿ��б������������

���������úú�,��������(һ����1���Ӻ�) cpFileToDir.sh�ű��ͻ��Զ�����,Ȼ��鿴��־�Ƿ�����,�Ƿ����������ļ�����.

