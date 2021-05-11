@echo off


:: ========================================
:: date:  2021-05-10  
:: desc:  此批处理脚本用于重启机器
::         或
::        用于把某个程序名的进行结束
:: use :  rebootOrKillP.bat
::         或
::        rebootOrKillP.bat 程序名
:: ========================================

set tpwdpath=%~dp0

:: 判断日志文件，并对超过限制大小的日志文件进行截断处理
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

:: 当没有参数时默认为重启机器
if "%1" == "" (
    echo %date% %time% "shutdown -r -f -t 0" >> %logName%
    shutdown -r -f -t 0
    rem @pause
    exit
) 

:: 有参数时参数为将在结束的程序名
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


