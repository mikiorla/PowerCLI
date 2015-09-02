	
$ErrorActionPreference = "SilentlyContinue"
$a = New-Object -comobject Excel.Application
$a.visible = $True
$b = $a.Workbooks.Add()
#$c = $b.Worksheets.Add()

#$cred = Get-Credential vCenterMonitor 
$vcenterserver="vm-vcenter-01"
#Connect-VIServer -Server $vcenterserver  

[string]$title = (Get-Host).UI.RawUI.WindowTitle
if ($title | Select-String -Pattern "Not") # Not connected to vCenter? True --> Connect to vCenter 
{Connect-VIServer -Server $vcenterserver -user vCenterMonitor -Password M0n1t0r2010} 

$dsshash = @{}
$dss = Get-Datastore
foreach ($ds in $dss) 
	{
	$dsshash.Add($ds.Id,$ds.Name)
	}


#************************************
#********** Check Clusters **********
#************************************

$clusters = Get-Cluster
#$clusters = "Oracle-Cluster-01"  ### ------------- samo za jedan kluster
$clsnum = 1
foreach ($cluster in $clusters) #foreach-1
{
$i=2 #odavde pocinju kolone u koje se upisuje


#---excel sheet for each cluster---{
#$c = $b.Worksheets.Item($clsnum)
$c = $b.Worksheets.Add()
$c.Name = $cluster.Name
$c.Cells.Item(1,1) = "vServer"
$c.Cells.Item(1,2) = "Status"
$c.Cells.Item(1,3) = "IP Address"
$c.Cells.Item(1,4) = "Memory"
$c.Cells.Item(1,5) = "vDisk"
$c.Cells.Item(1,6) = "vCPU"
$c.Cells.Item(1,7) = "Host"
$c.Cells.Item(1,8) = "Datastore"
$c.Cells.Item(1,9) = "vmdk File"
$d = $c.UsedRange
$d.Interior.ColorIndex = 19
$d.Font.ColorIndex = 11
$d.Font.Bold = $True
$d.EntireColumn.AutoFit($True)
#---excel sheet for each cluster---}

 
$clusterhosts = Get-Cluster $cluster.Name | Get-VMhost
#$clusterhosts = Get-Cluster "Oracle-cluster-01" | Get-VMhost ### ------------- samo za jedan kluster

foreach ($h in $clusterhosts) #foreach-host
{

$vmsh = Get-VMHost $h.Name | Get-VM #listaj sve masine na tom hostu

	foreach ($vmachine in $vmsh) #foreach-vm
		{
		$vmhdds=New-Object System.Collections.ArrayList
		$vmdss=New-Object System.Collections.ArrayList
		$hd=1
		foreach ($hdd in $vmachine.HardDisks)
			{
			$vmhdd = $hdd.CapacityKB/1048576
			#$vmhdd = [math]::Truncate($hdd.CapacityKB/1048576)
			#$vmhdd = '{0:0.0}' -f ($hdd.CapacityKB/1048576)
			#$vmhdd_brojac++
			$vmhdd_name=$hdd.FileName
			$null = $vmhdds.Add($vmhdd_name)
			if ($hd -lt $vmachine.HardDisks.count) {$null = $vmhdds.Add("`n")}
			$hd++
			}
		$allvmhdds = [string]$vmhdds	
		$c.Cells.Item($i,1)=$vmachine.Name
		$c.Cells.Item($i,2)= [string]$vmachine.PowerState
		$c.Cells.Item($i,3)=(Get-VMGuest -VM $vmachine.Name).IPAddress
		$c.Cells.Item($i,4)=$vmachine.MemoryMB
				
		$c.Cells.Item($i,5)=$vmhdd
		$c.Cells.Item($i,6)=$vmachine.NumCPU
		$c.Cells.Item($i,7)=$h.Name
		$dsid = $vmachine.DatastoreIdList
		foreach ($vmds in $dsid) 
				{
				$dsname = $dsshash.Get_Item("$vmds")
				$null = $vmdss.Add($dsname)
				#if ($dsid.count -gt "1") {$null = $vmdss.Add("`n")}
				}
		$allvmdss=[string]$vmdss
		$c.Cells.Item($i,8)=$allvmdss
		
		#$c.Cells.Item($i,9)=$vmhdd_name	
		$c.Cells.Item($i,9)=$allvmhdds
		$i++
		}#end-foreach-vm


}#end-foreach-host

 $clsnum++
  
 } #end-foreach-1
 
#********************************************
#********** Check Standalone Hosts **********
#********************************************
$standalone_hosts = Get-VMHost | Where {$_.isStandAlone}

if ($standalone_hosts) #if-standalone 
{

$i=2
$c = $b.Worksheets.Add() 
#$c = $b.Worksheets.Item($clsnum)
$c.Name = "Standalone Hosts"
#$c = $b.Worksheets.Item($clsnum)
$c.Cells.Item(1,1) = "vServer"
$c.Cells.Item(1,2) = "Status"
$c.Cells.Item(1,3) = "IP Address"
$c.Cells.Item(1,4) = "Memory"
$c.Cells.Item(1,5) = "vDisk"
$c.Cells.Item(1,6) = "vCPU"
$c.Cells.Item(1,7) = "Host"
$c.Cells.Item(1,8) = "Datastore"
$c.Cells.Item(1,9) = "vmdk File"
$d = $c.UsedRange
$d.Interior.ColorIndex = 19
$d.Font.ColorIndex = 11
$d.Font.Bold = $True
$d.EntireColumn.AutoFit($True)


foreach ($sta_host in $standalone_hosts) 

{


$vmsh = Get-VMHost $sta_host.Name | Get-VM #listaj sve masine na tom hostu

	foreach ($vmachine in $vmsh) #foreach-vm
		{
		foreach ($hdd in $vmachine.HardDisks)
			{
			$vmhdd = $hdd.CapacityKB/1048576
			
			#$vmhdd = [math]::Truncate($hdd.CapacityKB/1048576)
			#$vmhdd = '{0:0.0}' -f ($hdd.CapacityKB/1048576)
			#$vmhdd_brojac++
			
			$vmhdd_name=$hdd.FileName
			}
			
		$c.Cells.Item($i,1)=$vmachine.Name
		$c.Cells.Item($i,2)= [string]$vmachine.PowerState
		$c.Cells.Item($i,3)=(Get-VMGuest -VM $vmachine.Name).IPAddress
		$c.Cells.Item($i,4)=$vmachine.MemoryMB
		$c.Cells.Item($i,5)=$vmhdd
		$c.Cells.Item($i,6)=$vmachine.NumCPU
		$c.Cells.Item($i,7)=$sta_host.Name
		$dsid = $vmachine.DatastoreIdList
		foreach ($vmds in $dsid) 
				{
				$dsname = $dsshash.Get_Item("$vmds")
				$null = $vmdss.Add($dsname)
				#$null = $vmdss.Add("`n")
				}
		$c.Cells.Item($i,8)=$dsname
		
		$c.Cells.Item($i,9)=$vmhdd_name	
		
		$i++
		}#end-foreach-vm

 
#$clsnum++
}
 
 
}#end-if-standalone 
 
#DisConnect-VIServer -Server $vcenterserver -confirm Yes

