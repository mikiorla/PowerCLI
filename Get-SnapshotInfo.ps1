#$vmsnapshots = Get-VM *muc03* | Get-Snapshot
$vmsnapshots = Get-VM | Get-Snapshot
$processed = 0
$results = @()
foreach ($snapshot in $vmsnapshots)
{
    Write-Progress -Activity "Getting snapshot CreatedBy info" -PercentComplete (($processed/$vmsnapshots.Length)*100)
    $processed = $processed + 1
    $snapevent = Get-VIEvent -Entity $snapshot.VM -Types Info -Finish $snapshot.Created -MaxSamples 2 | Where-Object {$_.FullFormattedMessage -imatch 'Task: Create virtual machine snapshot'}
    if ($snapevent -ne $null)
    {
        $user = [string]$snapevent.UserName
        $snapshot | Add-Member CreatedBy $user
    }
    else
    {
        $snapshot | Add-Member CreatedBy '--Unknown--'
    }
    $results = $results + $snapshot
}

Write-Progress -Activity "Sorting" -PercentComplete 0
$results = $results | Sort-Object -Property Created
Write-Progress -Completed -Activity "Sorting" -PercentComplete 100

if ($env:COMPUTERNAME -like "PRD-VMG-DE-MUC1*")
{
$results | Format-Table -Property VM,Name,@{Label="Created"; Expression={Get-Date $_.Created -Format 'dd.MM.yyyy'}},CreatedBy,@{n="CreatedByName";e={ (whois $_.CreatedBy.Replace("ADS\","").Trim()).Name}}, @{n="DaysAge";e={((Get-Date) - (Get-Date $_.Created)).Days}} 
#$resultTable = $results | select VM,Name,@{Label="Created"; Expression={Get-Date $_.Created -Format 'dd.MM.yyyy'}},CreatedBy,@{n="CreatedByName";e={ (whois $_.CreatedBy.Replace("ADS\","").Trim()).Name}}, @{n="DaysAge";e={((Get-Date) - (Get-Date $_.Created)).Days}} 

}
else {
$results | Format-Table -Property VM,Name,@{Label="Created"; Expression={Get-Date $_.Created -Format 'dd.MM.yyyy'}},CreatedBy, @{n="DaysAge";e={((Get-Date) - (Get-Date $_.Created)).Days}}
}
