#
# sevcator.github.io
#
Clear-Host

# Modifable vars
$folderPath = "C:\Windows\Zapret"
$ARGS = "--wf-tcp=80,443 --wf-udp=80,443,50000-50099 "
$ARGS += "--filter-tcp=80,443 --hostlist-auto=`"$folderPath\autohostlist.txt`" --hostlist-auto-fail-threshold=2 --hostlist-auto-fail-time=60 --hostlist-auto-retrans-threshold=2 --hostlist-exclude=`"$folderPath\exclude.txt`" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=`"$folderPath\tls_clienthello_www_google_com.bin`" --dpi-desync-fake-quic=`"$folderPath\quic_initial_www_google_com.bin`" --new "
$ARGS += "--filter-udp=50000-50099 --ipset=`"$folderPath\ipset-discord.txt`" --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-any-protocol --dpi-desync-fake-tls=`"$folderPath\tls_clienthello_www_google_com.bin`" --dpi-desync-fake-quic=`"$folderPath\quic_initial_www_google_com.bin`" --new "
$ARGS += "--filter-udp=80,443 --hostlist-auto=`"$folderPath\autohostlist.txt`" --hostlist-auto-fail-threshold=2 --hostlist-auto-fail-time=60 --hostlist-auto-retrans-threshold=2 --hostlist-exclude=`"$folderPath\exclude.txt`" --dpi-desync=fake,split2 --dpi-desync-repeats=11 --dpi-desync-fake-tls=`"$folderPath\tls_clienthello_www_google_com.bin`" --dpi-desync-fake-quic=`"$folderPath\quic_initial_www_google_com.bin`""

Write-Host "  ______                         _   " -ForegroundColor Cyan
Write-Host " |___  /                        | |  " -ForegroundColor Cyan
Write-Host "    / /  __ _  _ __   _ __  ___ | |_ " -ForegroundColor Cyan
Write-Host "   / /  / _` || '_ \ | '__|/ _ \| __|" -ForegroundColor Cyan
Write-Host "  / /__| (_| || |_) || |  |  __/| |_ " -ForegroundColor Cyan
Write-Host " /_____|\__,_|| .__/ |_|   \___| \__|" -ForegroundColor Cyan
Write-Host "              | |                    " -ForegroundColor Cyan
Write-Host "              |_|                    + DNSCrypt" -ForegroundColor Cyan
Write-Host "** github.com/sevcator/zapret-powershell"
Write-Host "** github.com/bol-van/zapret"
Write-Host "** github.com/bol-van/zapret-win-bundle"
Write-Host "** github.com/DNSCrypt/dnscrypt-proxy"
Write-Host ""

function Check-Admin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Check-Admin)) {
    Add-Type -AssemblyName System.Windows.Forms 
    [System.Windows.Forms.MessageBox]::Show("zapret-sevcator | Run as administrator rights!")
    return
}

$initialDirectory = Get-Location

$version = [System.Environment]::OSVersion.Version

$windows10Version = New-Object System.Version(10, 0)

if ($version -gt $windows10Version) {
    Write-Output "Windows version: $version"
} else {
    Write-Host "Your version of Windows is old!" -ForegroundColor White
    return
}

function Check-ProcessorArchitecture {
    $processor = Get-WmiObject -Class Win32_Processor
    return $processor.AddressWidth -eq 64
}

if (Check-ProcessorArchitecture) {
    Write-Host "CPU Architecture is 64-bit"
} else {
    Write-Host "CPU Architecture is not 64-bit"
    return
}

if (Test-Path "$folderPath\uninstall.cmd") {
    & "$folderPath\uninstall.cmd"
} else {
    Write-Output "Hm... You don't using my zapret before"
}

Write-Host "Terminating processes"

$processesToKill = @("GoodbyeDPI.exe", "winws.exe", "zapret.exe", "dnscrypt-proxy.exe")

foreach ($process in $processesToKill) {
    try {
        Stop-Process -Name $process -Force -ErrorAction Stop
        Write-Host "${process}: Killed"
    } catch {
        if ($_.Exception.Message -like "*not running*") {
            Write-Host "${process}: Process not found" -ForegroundColor White
        } else {
            Write-Host ("{0}: {1}" -f $process, $_.Exception.Message) -ForegroundColor White
        }
    }
}

Write-Host "Checking services"
$servicesToStop = @("zapret", "winws1", "goodbyedpi", "windivert", "windivert14", "dnscrypt-proxy")
foreach ($service in $servicesToStop) {
    $serviceStatus = Get-Service -Name $service -ErrorAction SilentlyContinue

    if ($serviceStatus) {
        Write-Host "${service}: Stopping"
        # Stop the service and handle potential errors
        try {
            Stop-Service -Name $service -Force -ErrorAction Stop
            Write-Host "${service}: Stopped successfully"
        } catch {
            Write-Host ("{0}: {1}" -f $service, $_.Exception.Message) -ForegroundColor Red
        }
        
        try {
            sc.exe delete $service -ErrorAction Stop | Out-Null
            Write-Host "${service}: Deleted"
        } catch {
            Write-Host ("{0}: {1}" -f $service, $_.Exception.Message) -ForegroundColor Yellow
	    Write-Host "If you have problems, try restart your machine!" -ForegroundColor Yellow
        }
    } else {
        Write-Host "${service}: Not found" -ForegroundColor White
    }
}

if (Test-Path $folderPath) {
    $items = Get-ChildItem -Path $folderPath -Recurse
    $filesToRemove = $items | Where-Object { $_.PSIsContainer -eq $false -and $_.Extension -ne ".txt" }
    foreach ($file in $filesToRemove) {
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
        } catch {
            Write-Warning "Failed to remove $($file.FullName): $_"
        }
    }
} else {
    New-Item -Path $folderPath -ItemType Directory | Out-Null
}

if (-not (Test-Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory | Out-Null
}

$exclusionPath = "$folderPath\winws.exe"

if (-not (Test-Path $exclusionPath)) {
    New-Item -Path $exclusionPath -ItemType File | Out-Null
    Write-Host "${exclusionPath}: Created"
} else {
    Write-Host "${exclusionPath}: Already exists" -ForegroundColor Yellow
}

try {
    Add-MpPreference -ExclusionPath $exclusionPath
    Write-Host "${exclusionPath}: Added to exclusions in Windows Defender"
    Start-Sleep -Seconds 5
} catch {
    Write-Host ("${exclusionPath}: Error to add exclusion - {0}" -f $_.Exception.Message) -ForegroundColor Red
}

$GitResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest"
$DCPdownloadUrl = $GitResponse.assets | Where-Object { $_.name -match "win64.*zip" -and $_.name -notmatch ".minisig" } | Select-Object -ExpandProperty browser_download_url

$files = @(
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/WinDivert.dll"; Name = "WinDivert.dll"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/WinDivert64.sys"; Name = "WinDivert64.sys"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/cygwin1.dll"; Name = "cygwin1.dll"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/winws.exe"; Name = "winws.exe"},
    @{Url = "https://raw.githubusercontent.com/bol-van/zapret-win-bundle/refs/heads/master/zapret-winws/ipset-discord.txt"; Name = "ipset-discord.txt"},
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/autohostlist.txt"; Name = "autohostlist.txt"},
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/exclude.txt"; Name = "exclude.txt"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/files/fake/tls_clienthello_www_google_com.bin"; Name = "tls_clienthello_www_google_com.bin"}
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/files/fake/quic_initial_www_google_com.bin"; Name = "quic_initial_www_google_com.bin"}
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/uninstall.cmd"; Name = "uninstall.cmd"}
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/allowed-ips.txt"; Name = "allowed-ips.txt"}
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/allowed-names.txt"; Name = "allowed-names.txt"}
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/blocked-ips.txt"; Name = "blocked-ips.txt"}
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/blocked-names.txt"; Name = "blocked-names.txt"}
    @{Url = "$DCPdownloadUrl"; Name = "dnscrypt-proxy.zip"}
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/dnscrypt-proxy.toml"; Name = "dnscrypt-proxy.toml"}
)

foreach ($file in $files) {
    try {
        Invoke-WebRequest -Uri $file.Url -OutFile "$folderPath\$($file.Name)" -ErrorAction Stop | Out-Null
        Write-Host "$($file.Name): Downloaded"
    } catch {
        Write-Host ("{0}: {1}" -f $($file.Name), $_.Exception.Message) -ForegroundColor Red
    }
}

Set-Location $folderPath | Out-Null

$zipPath = "$folderPath\dnscrypt-proxy.zip"
$dnsCryptProxyPath = "$folderPath\dnscrypt-proxy.exe"

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $folderPath)

$extractedPath = "$folderPath\win64\dnscrypt-proxy.exe"
if (Test-Path $extractedPath) {
    Move-Item -Path $extractedPath -Destination $dnsCryptProxyPath -Force
    Write-Host "dnscrypt-proxy.exe extracted successfully to $dnsCryptProxyPath"
    Remove-Item -Path $zipPath -Force
    Remove-Item -Path "$folderPath\win64" -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Failed to extract dnscrypt-proxy.exe."
}

try {
    sc.exe create winws1 binPath= "`"$folderPath\winws.exe $ARGS`"" DisplayName= "zapret DPI bypass" start= auto | Out-Null
    sc.exe start winws1 | Out-Null
    Write-Host "Service winws1 created and started!"
} catch {
    Write-Host ("Failed to create or start service: {0}" -f $_.Exception.Message) -ForegroundColor Red
}

try {
    sc.exe create dnscrypt-proxy binPath= "$folderPath\dnscrypt-proxy.exe $folderPath\dnscrypt-proxy.toml" DisplayName= "DNSCrypt Proxy" start= auto | Out-Null
    sc.exe start dnscrypt-proxy | Out-Null
    Write-Host "Service dnscrypt-proxy created and started!"
} catch {
    Write-Host ("Failed to create or start service: {0}" -f $_.Exception.Message) -ForegroundColor Red
}

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($adapter in $adapters) {
    Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses 127.0.0.1
}
Write-Host "Primary DNS 127.0.0.1 is installed on all Internet adapters"

Write-Host ""
Write-Host "Done! Now enjoy."
Write-Host "To remove Zapret, run script located in $folderPath\uninstall.cmd as administrator!" -ForegroundColor Yellow
Write-Host ""
Write-Host "!!! If Discord stucks on 'Checking for updates...' terminate process and open again" -ForegroundColor Gray
Write-Host "!!! On some providers this DPI Bypass may not working! Uninstall and use VPN or something else (try other zapret)" -ForegroundColor Gray
Write-Host ""
Write-Host "Follow me ** sevcator.github.io & sevcator.t.me"
Write-Host ""
Set-Location $initialDirectory
