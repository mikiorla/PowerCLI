﻿#break
# http://vlenzker.net/tag/powercli/
#import-module VMware.VimAutomation.Core
Import-Module VMware.PowerCLI

$pathToCSV = " ... "
$date = (Get-Date).DateTime.replace(" ",".").replace(",",".").replace("..",".")
$hosts = Get-cluster | Get-VMHost | sort Name
$up = "↑"
$down = "↓"
foreach ($vmhost in $hosts)
{

$host_csv = import-csv "$pathToCSV\$($vmhost.Name)_SMART.csv" -Delimiter "," -ErrorAction Continue

$esxcli = Get-EsxCli -VMHost $vmhost -V2
$deviceList = $esxcli.storage.core.device.list.Invoke() | ? {($_.DeviceType -ne "CD-ROM") -and ($_.IsUSB -eq $false)}
$arg = $esxcli.storage.core.device.smart.get.CreateArgs()

Write-host -for Cyan "$vmhost.Name"
foreach($device in $deviceList)
{
$ReadCountersSame,$WriteCountersSame=$false
$Error.Clear()
try {
    $host_csv_device = $host_csv|?{$_.DeviceName -eq $device.DisplayName}
    $previousReadErrorCount = ($host_csv_device.ReadErrorCount | select -Last 1).Split(" ")[0]
    $previousWriteErrorCount = ($host_csv_device.WriteErrorCount | select -Last 1).Split(" ")[0]
    $previousInitialBadBlockCount = ($host_csv_device.InitialBadBlockCount | select -Last 1).Split(" ")[0]    
    
    $arg.devicename =$device.Device
    $smart = $esxcli.storage.core.device.smart.get.Invoke($arg)
    
    $ReadErrorCount = ($smart | ? {$_.Parameter -contains "Read Error Count"} ).value
    $WriteErrorCount = ($smart | ? {$_.Parameter -contains "Write Error Count"} ).value
    $HealthStatus = ($smart | ? {$_.Parameter -contains "Health Status"} ).value
    $InitialBadBlockCount =  ($smart | ? {$_.Parameter -contains "Initial Bad Block Count"} ).value
    $host_device = New-Object -TypeName PSObject -Property @{
    Date = $date
    DeviceName = $device.DisplayName
    ReadErrorCount = if ($ReadErrorCount -gt $previousReadErrorCount) {"$ReadErrorCount $up" } elseif ($ReadErrorCount -lt $previousReadErrorCount){"$ReadErrorCount $down"} else {$ReadErrorCount;$ReadCountersSame=$true}
    WriteErrorCount = if ($WriteErrorCount -gt $previousWriteErrorCount) {"$WriteErrorCount $up" } elseif ($WriteErrorCount -lt $previousWriteErrorCount){"$WriteErrorCount $down"} else {$WriteErrorCount;$WriteCountersSame=$true}
    HealthStatus = $HealthStatus
    InitialBadBlockCount = $InitialBadBlockCount        
    }
    
    if (!$WriteCountersSame){"$($device.DisplayName) Previous.WriteErrorCount $previousWriteErrorCount New.WriteErrorCount $($host_device.WriteErrorCount)"}
    if (!$ReadCountersSame){"$($device.DisplayName) Previous.ReadErrorCount $previousReadErrorCount New.ReadErrorCount $($host_device.ReadErrorCount)"}
    
    $host_device | Export-Csv -Append -Path "C:\Users\b280082_adm\Documents\$($vmhost.Name)_SMART.csv" -NoTypeInformation -NoClobber

}

catch {Write-Warning $Error.Exception.Message}

}


