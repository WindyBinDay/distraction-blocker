$progs = Get-Content "$PSScriptRoot\applicationList.txt"

$Path_HostsFile = "C:\Windows\System32\drivers\etc\hosts"
$Path_hostsFileBackup = "C:\Windows\System32\drivers\etc\hosts_backup"
$siteList = Get-Content "$PSScriptRoot\siteList.txt"

function blockThings {
    #CHANGE HOSTS FILE TO BLOCK WEBSITES
    $blockList = Get-Content $Path_HostsFile
    $blockList += "`r`n"
    foreach ($line in $siteList) {
        if ($line -ne "" -and !($line.startswith('#'))) {
            $blocklist += "127.0.0.1 " + $line
        }
    }

    Copy-Item $Path_HostsFile -Destination $Path_hostsFileBackup -Force
    Set-Content -Path $Path_HostsFile -Value $blockList
        
    #REGISTRY ENTRIES TO BLOCK PROGRAMS
    New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisallowRun" -Value 1  -PropertyType "DWord"
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name DisallowRun
    $count = 1
    foreach ($prog in $progs) {    
        New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" -Name $count -Value $prog  -PropertyType "String"
        $count++
    }

    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $result = [System.Windows.Forms.MessageBox]::Show('Do you want to close distracting programs now?' , "Close Programs" , 4)
    if (($result) -eq 'Yes') {
        foreach ($prog in $progs) {    
            Get-Process ($prog -replace ".exe*") | Foreach-Object { $_.CloseMainWindow() | Out-Null }
        }
    }
}

function restoreNormality {
    #REMOVE REGISTRY ENTRIES
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name DisallowRun
    Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" -Recurse

    #RESTORE HOSTS FILE
    Copy-Item $Path_hostsFileBackup -Destination $Path_HostsFile -Force
}


if (Test-Path -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun") {
    restoreNormality
}
else {
    blockThings
}