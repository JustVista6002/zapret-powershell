@echo off
title Uninstallation zapret-powershell

echo Z)zzzzzz                           t)   
echo       Z)                         t)tTTT 
echo     Z) a)AAAA p)PPPP  r)RRR e)EEEEEt)   
echo    Z)   a)AAA p)   PPr)   RRe)EEEE t)   
echo  Z)    a)   A p)   PPr)     e)     t)   
echo Z)zzzzzza)AAAAp)PPPP r)      e)EEEEt)T  
echo               p)                        
echo               p)           
echo Script - github.com/sevcator/zapret-powershell
echo Zapret - github.com/bol-van/zapret
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo You must run this script with administrative privileges to countinue.
    exit /b
)

cd "C:\Windows\System32"
echo Killing processes
taskkill /F /IM winws.exe /T >nul 2>&1

echo Stopping services
net stop winws1 >nul 2>&1
net stop windivert >nul 2>&1
net stop windivert14 >nul 2>&1
sc stop zapret >nul 2>&1
sc stop windivert >nul 2>&1
sc stop windivert14 >nul 2>&1

echo Deleting services
sc delete winws1 >nul 2>&1
sc delete windivert >nul 2>&1
sc delete windivert14 >nul 2>&1

echo Cleaning Zapret folder
set "folderPath=C:\Windows\Zapret"
if exist "%folderPath%" rd /s /q "%folderPath%"

echo Done
