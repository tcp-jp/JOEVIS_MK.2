function Start-prelim {
    $script:cwd="C:\JOEVIS"
    icacls $cwd /q /c /t /grant everyone:F >$nul
    $script:backupDate=(get-date -Format "yyyy-MM-dd").ToString()
    if (Test-Path $cwd) {
        write-host JOEVIS directory exists -foregroundColor Green
    }
    else {
        write-host JOEVIS directory not found -foregroundColor Red
        new-item -itemtype Directory -path $cwd > $null
        if (Test-Path $cwd) {
            write-host JOEVIS directory successfully created -foregroundColor Green
        }
    }
    Start-transcript -path $cwd\JOEVIS_Transcript_$backupDate.txt 
    $script:ip=(get-NetIPAddress -InterfaceAlias Ethernet).IPAddress.ToString()
    $script:gateway=(get-NetIPConfiguration -interfaceAlias Ethernet).IPv4DefaultGateway.NextHop.ToString()
    $script:subnet=$ip.Substring(0,$ip.LastIndexOf("."))
    $script:bakFile="$cwd\JOEVIS_Backup_$backupDate.bak"
    $script:zipFile="$cwd\JOEVIS_Backup_$backupDate.zip"
    $script:sqlLog="$cwd\JOEVIS_SQL_Log_$backupDate.txt"
    $script:errLog="$cwd\JOEVIS_Error_Log_$backupDate.txt"
    $script:daysToKeep=14
    $script:passwords="Password1 Password2 Password3"
}


function Check-RemoteDevices {
    $remoteDevices=@()
    1..254 | ForEach-Object {start-process -WindowStyle Hidden ping -ArgumentList "-n 1 $subnet$_"}
    $computers=$Computers =(arp.exe -a | Select-String "$Subnet.*dynamic") -replace ' +',','| ConvertFrom-Csv -Header Empty,IP 
    $remoteDevices=foreach($computer in $computers) {nslookup $computer.IP | select-String -Pattern "^Name" | % {$_ -replace "Name:    "} 
        }
    $remoteDevices=$remoteDevices.split(" ")
    if ($remoteDevices.length -gt 0) {$script:remoteDevicesFound="True"}
    else {$script:remoteDevicesFound="False"}
    
    # ===================================
    # Loop used to copy to remote devices
    # ===================================
    foreach($name in $remoteDevices) {
        # This is the loop to copy things over I guess
        write-host $name -foregroundColor Green}
}


function Check-AlreadyRan {
    if (Test-Path $zipFile) {
        write-host JOEVIS Backup already exists for today -foregroundColor Green
        if ($remoteDevices.length -gt 0) {
            write-host Remote devices exist. Checking remote backups -foregroundColor Green
        }
    }
}
    

function Write-Settings { 
    write-host ** Settings ** 
    write-host IP Address      : $ip -foregroundColor Green 
    write-host Default Gateway : $gateway -foregroundColor Green 
    write-host Raw Backup File : $bakFile -foregroundColor Green  
    write-host Zip Backup File : $zipFile -foregroundColor Green  
    write-host SQL Log File    : $sqlLog -foregroundColor Green  
    write-host Error Log File    : $errLog -foregroundColor Green  
    write-host Days To Keep    : $daysToKeep -foregroundColor Green  
}


function Check-7zip { 
    if (Test-Path "c:\Program Files (x86)\7-Zip") { 
        write-host 7-Zip found in "c:\Program Files (x86)\7-Zip" -foregroundColor Green
    }
    elseif (Test-Path "c:\Program Files\7-Zip") { 
        write-host 7-Zip found in c:\Program Files\7-Zip -foregroundColor Green
    }
    else {
        write-host 7-Zip not found. Installing -foregroundColor Red
        ((new-object system.net.webclient).downloadfile("https://www.7-zip.org/a/7z1900.exe", "$cwd\7-ZipInstaller.exe"))
        write-host 7-Zip downloaded successfully -foregroundColor Green
        Start-process -wait -filePath "$cwd\7-ZipInstaller.exe" -ArgumentList "/S" 
        write-host 7-Zip installed successfully -foregroundColor Green
        remove-item $cwd\7-ZipInstaller.exe 
        write-host 7-Zip installer deleted successfully -foregroundColor Green
    }
}


function Check-scheduledTask { 
    if (get-scheduledTask -taskName "JOEVIS" 2> $nul) {
        write-host JOEVIS task already created. Checking configuration -foregroundColor Green 
        write-host ** JOEVIS Task Settings ** 
        $task="True"
        # ============
        # Task Enabled
        # ============
        if ((get-scheduledtask -taskname JOEVIS).Settings.Enabled) { 
            write-host JOEVIS Task is enabled -foregroundColor Green
        }
        else {
            write-host JOEVIS Task is disabled
        }
        # =============
        # Run on demand
        # =============
        if ((get-scheduledtask -taskname JOEVIS).Settings.AllowDemandStart) { 
            write-host JOEVIS Task run on remand is enabled -foregroundColor Green
        }
        else {
            write-host JOEVIS Task run on demand is is disabled. Amending -foregroundColor Red
            write-host Unfinished -foregroundColor Red
        }
        # ==========================
        # DisallowStartIfOnBatteries
        # ==========================
        if ((get-scheduledtask -taskname JOEVIS).Settings.DisallowStartIfOnBatteries) { 
            write-host Power settings incorrect. Amending -foregroundColor Red
        }
        # ==========================
        # Stop if going on batteries
        # ==========================
        if ((get-scheduledtask -taskname JOEVIS).Settings.StopIfGoingOnBatteries) {
            write-host Power settings incorrect. Amending -foregroundColor Red
        }
        # ================
        # Run only if idle
        # ================
        if ((get-scheduledtask -taskname JOEVIS).Settings.RunOnlyIfIdle) {
            write-host Idle settings incorrect. Amending -foregroundColor Red
        }
        # ================
        # Stop on Idle end
        # ================
        if ((get-scheduledtask -taskname JOEVIS).Settings.IdleSettings.StopOnIdleEnd) { 
            write-host Idle settings incorrect. Amending -foregroundColor Red
        }
        # ===========
        # Wake to run
        # ===========
        if ((get-scheduledtask -taskname JOEVIS).Settings.WakeToRun) {
            write-host Wake to run set correctly -foregroundColor Green
        }
        else { 
            write-host Wake to run set incorrectly -foregroundColor red 
            write-host Unfinished -foregroundColor Red
        }
        # =============================
        # Run only if network available
        # =============================
        if ((get-scheduledtask -taskname JOEVIS).Settings.RunOnlyIfNetworkAvailable) { 
            write-host Network settings incorrect. Amending -foregroundColor Red
        }
        # ==================
        # Multiple Instances
        # ==================
        if ((get-scheduledtask -taskname JOEVIS).Settings.MultipleInstances) { 
            write-host Incorrect settings for multiple instances. Amending -foregroundColor Red
        }
        else {
            write-host Correct settings for multiple instances -foregroundColor Green
            write-host Unfinished -foregroundColor Red
        }
        # ==========
        # Start Time
        # ==========
        if ((get-scheduledtask -taskname JOEVIS).Triggers.StartBoundary.contains("T02:35:00")) {
            write-host JOEVIS Task start time correct -foregroundColor Green
        }
        else {
            write-host JOEVIS Task start time incorrect. Amending -foregroundColor Red
            write-host Unfinished -foregroundColor Red
        }
    }
    # ==================
    # Task doesn't exist
    # ==================
    else {
        write-host JOEVIS task not already created. Creating scheduled task -foregroundColor Green 
        $task="False"
        $action=New-ScheduledTaskAction -Execute "C:\FPOS5\Bin\JOEVIS.exe"
        $trigger=New-ScheduledTaskTrigger -Daily -At 2:35am
        $principal=New-ScheduledTaskPrincipal "$env:computername\Administrator"
        $settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -MultipleInstances Parallel -WakeToRun  
        $scheduledTask=new-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings
        register-ScheduledTask "JOEVIS\JOEVIS" -InputObject $scheduledTask
    }
}

function Check-OSConfig {
    # ========
    # Firewall
    # ========
    write-host Disabling Firewalls -foregroundColor Green
    netsh advfirewall set allprofiles state off
    # ====================
    # User Account Control
    # ====================
    write-host Checking UAC -foregroundColor Yellow
    if ((Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\).EnableLUA -eq 1) {
        write-host UAC not disabled. Disabling -foregroundColor Red
        write-host Unfinished -foregroundColor Red
    }
    else {write-host UAC disabled}
    # ================
    # Clear temp files
    # ================
    remove-item -force -path $env:temp
    # ========================
    # Disabling Windows Update
    # ========================
    write-host Checking Windows Update 
    if ((get-service -name "Windows Update").StartType -eq "Manual") {
        write-host Windows Update is enabled. Disabling -foregroundColor Red
        write-host Unfinished -foregroundColor Red
        stop-service -DisplayName "Windows Update"
        get-service -DisplayName "Windows Update" | set-service -Status Stopped -StartupType Disabled
        }
}

function Check-DNS { 
    if (-not (Get-DnsClientServerAddress -InterfaceAlias Ethernet -AddressFamily IPv4).ServerAddresses.Contains("$gateway")) { 
        Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses ("$gateway","8.8.8.8")
        write-host DNS addresses amended -foregroundColor Green
    }
    else {
        write-host DNS addresses are correct -foregroundColor Green
    }
}


function Check-requirements {
    Check-7zip
    Check-scheduledTask
    Check-DNS
}


function Start-MainSQL {


    }


function main {
    Start-prelim
    Check-RemoteDevices
    Check-AlreadyRan
    Write-Settings
    Check-OSConfig
    Check-requirements
    Start-MainSQL

}

main


