#
# sevcator.github.io
#
Clear-Host

Write-Host "  ______                         _   "
Write-Host " |___  /                        | |  "
Write-Host "    / /  __ _  _ __   _ __  ___ | |_ "
Write-Host "   / /  / _` || '_ \ | '__|/ _ \| __|"
Write-Host "  / /__| (_| || |_) || |  |  __/| |_ "
Write-Host " /_____|\__,_|| .__/ |_|   \___| \__|"
Write-Host "              | |                    "
Write-Host "              |_|                    "
Write-Host "Script - github.com/sevcator/zapret-powershell"
Write-Host "Zapret - github.com/bol-van/zapret"
Write-Host ""

function Check-Admin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Check-Admin)) {
    Add-Type -AssemblyName System.Windows.Forms 
    [System.Windows.Forms.MessageBox]::Show("zapret-sevcator | Run as administrator rights!")
    exit
}

$initialDirectory = Get-Location

Write-Host "--- START INSTALLATION ---"

$os = Get-CimInstance -ClassName Win32_OperatingSystem

if ($os.Version -ge "10.0") {
    Write-Host "Windows version is 10 or later."
} else {
    Add-Type -AssemblyName System.Windows.Forms 
    [System.Windows.Forms.MessageBox]::Show("zapret-sevcator | Windows version is earlier than 10.")
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
            Write-Host ("Failed to kill {0}: {1}" -f $process, $_.Exception.Message) -ForegroundColor Yellow
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
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/binaries/win64/WinDivert.dll"; Name = "WinDivert.dll"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/binaries/win64/WinDivert64.sys"; Name = "WinDivert64.sys"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/binaries/win64/cygwin1.dll"; Name = "cygwin1.dll"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/binaries/win64/winws.exe"; Name = "winws.exe"},
    @{Url = "https://raw.githubusercontent.com/bol-van/zapret-win-bundle/refs/heads/master/zapret-winws/ipset-discord.txt"; Name = "ipset-discord.txt"},
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/autohostlist.txt"; Name = "autohostlist.txt"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/files/fake/tls_clienthello_www_google_com.bin"; Name = "tls_clienthello_www_google_com.bin"}
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/files/fake/quic_initial_www_google_com.bin"; Name = "quic_initial_www_google_com.bin"}
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/args.txt"; Name = "args.txt"}
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/uninstall.cmd"; Name = "uninstall.cmd"}
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

$argFilePath = "$folderPath\args.txt"

if (Test-Path $argFilePath) {
    try {
        # Read the entire content of args.txt in one go
        $ARGS1 = Get-Content -Path $argFilePath -Raw
        Write-Host "Arguments loaded from args.txt."

        # Replace instances of $folderPath\ with the actual value of $folderPath
        $ARGS1 = $ARGS1 -replace '\$folderPath', $folderPath
    } catch {
        Write-Host ("Failed to read args.txt: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
} else {
    Write-Host "args.txt not found." -ForegroundColor Yellow
}

$ARGS = $ARGS1

Write-Host "Creating service Zapret"
try {
    sc.exe create winws1 binPath= "$folderPath\winws.exe $ARGS" DisplayName= "zapret DPI bypass" start= auto | Out-Null
    sc.exe start winws1 | Out-Null
    Write-Host "Service Zapret created and started successfully."
} catch {
    Write-Host ("Failed to create or start service Zapret: {0}" -f $_.Exception.Message) -ForegroundColor Red
}

$argFilePath = "$folderPath\args.txt"
if (Test-Path $argFilePath) {
    try {
        Remove-Item -Path $argFilePath -Force
        Write-Host "args.txt deleted successfully."
    } catch {
        Write-Host ("Failed to delete args.txt: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

Write-Host "--- END OF INSTALLATION ---"
Write-Host ""
Write-Host "Done! Now enjoy."
Write-Host "Follow me - sevcator.github.io"
Write-Host ""
Write-Host "To remove zapret run script located in $folderPath\uninstall.cmd as administrator!"
Set-Location $initialDirectory
