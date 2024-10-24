@echo off
title Uninstallation zapret-powershell

echo "  ______                         _   "
echo " |___  /                        | |  "
echo "    / /  __ _  _ __   _ __  ___ | |_ "
echo "   / /  / _` || '_ \ | '__|/ _ \| __|"
echo "  / /__| (_| || |_) || |  |  __/| |_ "
echo " /_____|\__,_|| .__/ |_|   \___| \__|"
echo "              | |                    "
echo "              |_|                    "
echo "Script - github.com/sevcator/zapret-powershell"
echo "Zapret - github.com/bol-van/zapret"
echo.
cd "C:\Windows\System32"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo "You must run this script with administrative privileges to countinue."
    exit /b
)

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