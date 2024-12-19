@echo off

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
taskkill /F /IM dnscrypt-proxy.exe /T >nul 2>&1

echo Stopping services
net stop winws1 >nul 2>&1
net stop windivert >nul 2>&1
net stop windivert14 >nul 2>&1
sc stop zapret >nul 2>&1
sc stop windivert >nul 2>&1
sc stop windivert14 >nul 2>&1
sc stop dnscrypt-proxy >nul 2>&1
echo Deleting services
sc delete winws1 >nul 2>&1
sc delete windivert >nul 2>&1
sc delete windivert14 >nul 2>&1
sc delete dnscrypt-proxy >nul 2>&1

echo Cleaning Zapret folder
set "folderPath=C:\Windows\Zapret"
set "tempPath=C:\Windows\Temp\Zapret"

if exist "%folderPath%" (
    move "%folderPath%\*.txt" "%tempPath%" >nul 2>&1
    rd /s /q "%folderPath%" >nul 2>&1
    mkdir "%folderPath%" >nul 2>&1
    move "%tempPath%\*.txt" "%folderPath%" >nul 2>&1
    rd /s /q "%tempPath%" >nul 2>&1
)

for /f "tokens=2 delims=," %%i in ('wmic nic where "NetConnectionStatus=2" get NetConnectionID ^| findstr /r /v "^$"') do (
    netsh interface ipv4 set dns name="%%i" source=dhcp
    netsh interface ipv6 set dns name="%%i" source=dhcp
    echo DNS settings reverted for interface: %%i
)

echo Done
