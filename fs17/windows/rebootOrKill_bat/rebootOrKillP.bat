@echo off


:: ========================================
:: date:  2021-05-10  
:: desc:  ��������ű�������������
::         ��
::        ���ڰ�ĳ���������Ľ��н���
:: use :  rebootOrKillP.bat
::         ��
::        rebootOrKillP.bat ������
:: ========================================

set tpwdpath=%~dp0

:: �ж���־�ļ������Գ������ƴ�С����־�ļ����нضϴ���
set logName=%tpwdpath%rebootOrKillP_log.txt
set tmpFile=%tpwdpath%rebootOrKillP_tmp.txt
set logSize=0
if  exist %logName% (
    for %%i in ("%logName%") do (
        set logSize=%%~zi
    )

    rem echo "hahah"
)

rem echo %date% %time% tpwdpath [%tpwdpath%] >> %logName%

if %logSize% geq 10240 (
    more +10 < %logName% > %tmpFile%
    @move /Y %tmpFile% %logName%
    echo %date% %time% log file size [%logSize%] >> %logName%
)

:: ��û�в���ʱĬ��Ϊ��������
if "%1" == "" (
    echo %date% %time% "shutdown -r -f -t 0" >> %logName%
    shutdown -r -f -t 0
    rem @pause
    exit
) 

:: �в���ʱ����Ϊ���ڽ����ĳ�����
set pName=%1
set findFlag=0
echo %date% %time% input programe name is:[%pName%] >> %logName%

tasklist /v /fo csv |findstr  %pName% > %tmpFile%
for /f "delims=, tokens=1,2" %%i in ('type %tmpFile%') do (
    if %%i == %pName% (
        rem echo %%i %%j
        echo %date% %time% kill [%pName%] PID:[%%j] >> %logName%
        set findFlag=1
        taskkill /F /PID %%j
    ) 
)

if %findFlag% equ 0 (
    echo %date% %time% programe name:[%pName%] the PID not found >> %logName%
    rem echo findFlag=%findFlag%
)


rem @pause
exit


