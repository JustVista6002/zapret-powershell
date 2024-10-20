#
# t.me/sevcator
#
Clear-Host

Write-Host "ZZZZZZZ"
Write-Host "      Z"
Write-Host "     Z "
Write-Host "    Z  "
Write-Host "   Z   "
Write-Host "  Z    "
Write-Host " Z     "
Write-Host "Z      "
Write-Host "ZZZZZZZAPRET"
Write-Host "github.com/sevcator/zapret-powershell"
Write-Host "github.com/bol-van/zapret"
Write-Host ""
Write-Host "--- START INSTALLATION ---"

function Check-Admin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Check-Admin)) {
    Write-Host "Run script as administrator." -ForegroundColor Red
    exit
}

Write-Host "Killing GoodbyeDPI and Zapret"

$processesToKill = @("GoodbyeDPI.exe", "winws.exe", "zapret.exe")

foreach ($process in $processesToKill) {
    try {
        Stop-Process -Name $process -Force -ErrorAction Stop
        Write-Host "$process killed successfully."
    } catch {
        if ($_.Exception.Message -like "*not running*") {
            Write-Host "$process is not running." -ForegroundColor Yellow
        } else {
            Write-Host ("Failed to kill {0}: {1}" -f $process, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

$servicesToStop = @("zapret", "winws1", "goodbyedpi", "windivert", "windivert14")
foreach ($service in $servicesToStop) {
    Write-Host "Checking service: $service"

    $serviceStatus = Get-Service -Name $service -ErrorAction SilentlyContinue

    if ($serviceStatus) {
        Write-Host "Stopping $service"
        # Stop the service and handle potential errors
        try {
            Stop-Service -Name $service -Force -ErrorAction Stop
            Write-Host "$service stopped successfully."
        } catch {
            Write-Host ("Failed to stop {0}: {1}" -f $service, $_.Exception.Message) -ForegroundColor Red
        }
        
        try {
            sc.exe delete $service -ErrorAction Stop | Out-Null
            Write-Host "$service deleted successfully."
        } catch {
            Write-Host ("Failed to delete {0}: {1}" -f $service, $_.Exception.Message) -ForegroundColor Red
        }
    } else {
        Write-Host "$service does not exist or is not running." -ForegroundColor Yellow
    }
}

$folderPath = "C:\Windows\Zapret"
if (Test-Path $folderPath) {
    Get-ChildItem -Path $folderPath | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
}

if (-not (Test-Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory | Out-Null
}

$exclusionPath = "$folderPath\winws.exe"

try {
    Add-MpPreference -ExclusionPath $exclusionPath
	Write-Host "$exclusionPath added to exclusions in Windows Defender."
	
	Write-Host "Waiting 5 seconds"
    Start-Sleep -Seconds 5
} catch {
    Write-Host ("Error to add exclusion: {0}" -f $_.Exception.Message) -ForegroundColor Red
}


$files = @(
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/binaries/win64/zapret-winws/WinDivert.dll"; Name = "WinDivert.dll"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/binaries/win64/zapret-winws/WinDivert64.sys"; Name = "WinDivert64.sys"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/binaries/win64/zapret-winws/cygwin1.dll"; Name = "cygwin1.dll"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/binaries/win64/zapret-winws/winws.exe"; Name = "winws.exe"},
    @{Url = "https://raw.githubusercontent.com/bol-van/zapret/refs/heads/master/binaries/win64/zapret-winws/ipset-discord.txt"; Name = "ipset-discord.txt"},
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/autohostlist.txt"; Name = "autohostlist.txt"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/binaries/win64/zapret-winws/tls_clienthello_www_google_com.bin"; Name = "tls_clienthello_www_google_com.bin"}
)

foreach ($file in $files) {
    try {
        Invoke-WebRequest -Uri $file.Url -OutFile "$folderPath\$($file.Name)" -ErrorAction Stop | Out-Null
        Write-Host "$($file.Name) downloaded successfully."
    } catch {
        Write-Host ("Failed to download {0}: {1}" -f $($file.Name), $_.Exception.Message) -ForegroundColor Red
    }
}

Set-Location $folderPath | Out-Null

$ARGS = "--wf-tcp=80,443 --wf-udp=443,50000-51111 --filter-udp=50000-51111 --ipset=""$folderPath\ipset-discord.txt"" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol --dpi-desync-cutoff=n2 --new --filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=11 --new --filter-tcp=80 --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --hostlist-auto=""$folderPath\autohostlist.txt"" --new --filter-tcp=443 --dpi-desync=fake,split2 --dpi-desync-repeats=11 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=""$folderPath\tls_clienthello_www_google_com.bin"" --new --dpi-desync=fake,disorder2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --hostlist-auto=""$folderPath\autohostlist.txt"" --hostlist-auto-fail-threshold=2 --hostlist-auto-fail-time=5 --hostlist-auto-retrans-threshold=2 --ctrack-timeouts=15:300:15:15"

Write-Host "Creating service Zapret"
try {
    sc.exe create winws1 binPath= "$folderPath\winws.exe $ARGS" DisplayName= "zapret DPI bypass" start= auto | Out-Null
    sc.exe start winws1 | Out-Null
    Write-Host "Service Zapret created and started successfully."
} catch {
    Write-Host ("Failed to create or start service Zapret: {0}" -f $_.Exception.Message) -ForegroundColor Red
}

Write-Host "--- END OF INSTALLATION ---"
Write-Host ""
Write-Host "Done!"
Write-Host "Please, follow my Telegram channel - t.me/sevcator"
