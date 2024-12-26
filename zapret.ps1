#
# 3=====D Idi nax PKH, He Tporau Hash Internet
#
Clear-Host
$folderPath = "C:\Windows\Zapret"
$hostlist = "--hostlist-exclude=`"$folderPath\exclude.txt`" --hostlist-auto=`"$folderPath\autohostlist.txt`""
$ARGS = "--wf-tcp=80,443 --wf-udp=80,443,50000-50099 "
$ARGS += "--filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=`"$folderPath\tls.bin`" $hostlist --new "
$ARGS += "--filter-tcp=443 --hostlist=`"$folderPath\google.txt`" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=`"$folderPath\tls.bin`" --new "
$ARGS += "--filter-tcp=80 --hostlist=`"$folderPath\google.txt`" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=`"$folderPath\tls.bin`" --new "
$ARGS += "--filter-tcp=443 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig --dpi-desync-fake-tls=`"$folderPath\tls.bin`" $hostlist --new "
$ARGS += "--filter-udp=443 --hostlist=`"$folderPath\google.txt`" --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=`"$folderPath\quic.bin`" --new "
$ARGS += "--filter-udp=80 --hostlist=`"$folderPath\google.txt`" --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=`"$folderPath\quic.bin`" --new "
$ARGS += "--filter-udp=80 --dpi-desync=fake --dpi-desync-repeats=11 $hostlist --new "
$ARGS += "--filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=11 $hostlist --new "
$ARGS += "--filter-udp=50000-50099 --ipset=`"$folderPath\ipset-discord.txt`" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol --dpi-desync-cutoff=n4"
Write-Host "  ______                         _   "
Write-Host " |___  /                        | |  "
Write-Host "    / /  __ _  _ __   _ __  ___ | |_ "
Write-Host "   / /  / _` || '_ \ | '__|/ _ \| __|"
Write-Host "  / /__| (_| || |_) || |  |  __/| |_ "
Write-Host " /_____|\__,_|| .__/ |_|   \___| \__|"
Write-Host "              | |                    "
Write-Host "              |_|                    "
Write-Host "Easy installation of bol-van software"
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
function Check-ProcessorArchitecture {
    $processor = Get-WmiObject -Class Win32_Processor
    return $processor.AddressWidth -eq 64
}
if (Check-ProcessorArchitecture) {
    Write-Host "- CPU Architecture is 64-bit"
} else {
    Write-Host "- CPU Architecture is not 64-bit"
    return
}
if (Test-Path "$folderPath\uninstall.cmd") {
    & "$folderPath\uninstall.cmd" *> $null
}

Write-Host "- Terminating processes"
$processesToKill = @("GoodbyeDPI.exe", "winws.exe", "zapret.exe")
foreach ($process in $processesToKill) {
    Stop-Process -Name $process -Force -ErrorAction SilentlyContinue | Out-Null
}

Write-Host "- Removing services"
$servicesToStop = @("zapret", "winws1", "goodbyedpi", "windivert", "windivert14")
foreach ($service in $servicesToStop) {
    $serviceStatus = Get-Service -Name $service -ErrorAction SilentlyContinue | Out-Null

    if ($serviceStatus) {
        try {
            Stop-Service -Name $service -Force -ErrorAction Stop
        } catch {
            Write-Host ("{0}: {1}" -f $service, $_.Exception.Message) -ForegroundColor Red
        }
        
        try {
            sc.exe delete $service -ErrorAction Stop | Out-Null
        } catch {
            Write-Host ("{0}: {1}" -f $service, $_.Exception.Message) -ForegroundColor Yellow
	    Write-Host "If you have problems, try restart your machine!" -ForegroundColor Yellow
        }
    } else {
    
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
Write-Host "- Adding exclusion"
if (-not (Test-Path $exclusionPath)) {
    New-Item -Path $exclusionPath -ItemType File | Out-Null
}
try {
    Add-MpPreference -ExclusionPath $exclusionPath
    Start-Sleep -Seconds 5
} catch {
    Write-Host ("- Error adding exclusion") -ForegroundColor Yellow
}

Write-Host "- Downloading files"
$files = @(
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/WinDivert.dll"; Name = "WinDivert.dll"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/WinDivert64.sys"; Name = "WinDivert64.sys"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/cygwin1.dll"; Name = "cygwin1.dll"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/winws.exe"; Name = "winws.exe"},
    @{Url = "https://raw.githubusercontent.com/bol-van/zapret-win-bundle/refs/heads/master/zapret-winws/ipset-discord.txt"; Name = "ipset-discord.txt"},
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/autohostlist.txt"; Name = "autohostlist.txt"},
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/google.txt"; Name = "google.txt"},
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/exclude.txt"; Name = "exclude.txt"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/files/fake/tls_clienthello_www_google_com.bin"; Name = "tls.bin"}
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/files/fake/quic_initial_www_google_com.bin"; Name = "quic.bin"}
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/uninstall.cmd"; Name = "uninstall.cmd"}
)
foreach ($file in $files) {
    try {
        Invoke-WebRequest -Uri $file.Url -OutFile "$folderPath\$($file.Name)" -ErrorAction Stop | Out-Null
    } catch {
        Write-Host ("{0}: {1}" -f $($file.Name), $_.Exception.Message) -ForegroundColor Red
    }
}

Set-Location $folderPath | Out-Null
Write-Host "- Creating service"
try {
    sc.exe create winws1 binPath= "`"$folderPath\winws.exe $ARGS`"" DisplayName= "zapret DPI bypass" start= auto | Out-Null
    sc.exe start winws1 | Out-Null
} catch {
    Write-Host ("Failed to create or start service: {0}" -f $_.Exception.Message) -ForegroundColor Red
}

Write-Host "- Done!"
Write-Host "- To remove Zapret, run script located in $folderPath\uninstall.cmd as administrator!"
Write-Host "*** sevcator.t.me / sevcator.github.io ***"
Set-Location $initialDirectory
