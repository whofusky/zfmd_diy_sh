@echo off
title �������������ļ�����ű���
rem mode con cols=80 lines=40
rem color 84

set num=0
set numcnt=0
:start

set runningp=-99

ping -n 1 -w 500 127.0.0.1>nul

rem ����doAct�Ƿ����
tasklist /v /fo csv |findstr "ȡ��Ŀ¼�ļ�ֻ��Ȩ��">tmpRRA.txt

rem ====================================
for /f "delims=*" %%i in ('type tmpRRA.txt') do (
  echo %%i
)
rem ====================================

for /f "delims=, tokens=2" %%i in ('type tmpRRA.txt') do (
  set /a runningp=%%i
)

if %runningp% == -99 (
set /a numcnt=0 
)^
else (
set /a numcnt=%numcnt%+1
)

if %numcnt% geq 5 (
set /a numcnt=0
taskkill /PID %runningp%
) 

set /a num=%num%+1
rem echo %num%
echo %date% %time%���˽ű�ר���ڴ������ļ����벻Ҫ�رմ˴��ڡ�

rem call doAct.bat
if %numcnt%== 0 (
echo "call doAct run"
start /MIN doAct.bat
ping -n 1 -w 500 127.0.0.1>nul
)
if %num%== 20 (
set /a num=0 
cls
) 

goto start