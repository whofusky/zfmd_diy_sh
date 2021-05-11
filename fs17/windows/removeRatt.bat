@echo off
title 《反向隔离接收文件处理脚本》
rem mode con cols=80 lines=40
rem color 84

set num=0
set numcnt=0
:start

set runningp=-99

ping -n 1 -w 500 127.0.0.1>nul

rem 查找doAct是否存在
tasklist /v /fo csv |findstr "取消目录文件只读权限">tmpRRA.txt

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
echo %date% %time%“此脚本专用于处理反隔文件，请不要关闭此窗口”

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