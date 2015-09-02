
$a = New-Object -comobject Excel.Application
$a.visible = $True

$b = $a.Workbooks.Add()
$c = $b.Worksheets.Item(1)

$c.Columns.Item('A').ColumnWidth = 20
$c.Columns.Item('B').ColumnWidth = 10
$c.Columns.Item('C').ColumnWidth = 10
$c.Columns.Item('D').ColumnWidth = 25
#$c.Columns.Item('E').ColumnWidth = 25

$c.Cells.Item(1,1) = "DataStore"
$c.Cells.Item(1,2) = "DS size GB"
$c.Cells.Item(1,3) = "DS free GB"
$c.Cells.Item(1,4) = "VM"

$d = $c.UsedRange
$d.Interior.ColorIndex = 19
$d.Font.ColorIndex = 11
$d.Font.Bold = $True
#$d.EntireColumn.AutoFit($True)

$i = 2


#$cred = Get-Credential vCenterMonitor 
$vcenterserver="vm-vcenter-01"
#Connect-VIServer -Server $vcenterserver  

[string]$title = (Get-Host).UI.RawUI.WindowTitle
if ($title | Select-String -Pattern "Not") # Not connected to vCenter? True --> Connect to vCenter 
{Connect-VIServer -Server $vcenterserver -user vCenterMonitor -Password M0n1t0r2010} 

#$dsshash = @{}
$dss = Get-Datastore | ? {$_.Name -notlike "*local*"}
#foreach ($ds in $dss) 
#	{
#	$dsshash.Add($ds.Id,$ds.Name)
#	}


#************************************
#********** Check Clusters **********
#************************************


Foreach ($d in $dss)
{
$c.Cells.Item($i,1) = $d.Name
$c.Cells.Item($i,2) = $d.CapacityMB/1000
$c.Cells.Item($i,3) = $d.FreespaceMB/1000
$vmsh = get-datastore $d | Get-VM #listaj sve masine na tom datastore-u

	foreach ($vmachine in $vmsh) #foreach-vm
		{
		$c.Cells.Item($i,4) = $vmachine.Name
		$i++
		}#end-foreach-vm



  
 } #end-foreach-1

 
#DisConnect-VIServer -Server $vcenterserver -confirm Yes

