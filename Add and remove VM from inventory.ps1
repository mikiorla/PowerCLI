#http://www.wooditwork.com/2011/08/11/adding-vmx-files-to-vcenter-inventory-with-powercli-gets-even-easier/

$powerCLIpssnapin = 'VMware.VimAutomation.Core'
$vServer  = Read-Host 'Enter vCenter server or ESXi host name or IP'
Add-PSSnapin $powerCLIpssnapin
Get-PSSnapin $powerCLIpssnapin

Get-Command -Module $powerCLIpssnapin

Connect-VIServer -Server $vServer

$ESXHost = "esxir900.ktehnika.local"

Get-VMHost $ESXHost | Get-VM

Get-Datastore
$VMDatastore = 'DELL 900 1Tb'

Get-Datastore -Name $VMDatastore
Get-Datastore -Name $VMDatastore | Get-VM

$VMFilePath = '[DELL 900 1Tb] hv2/hv2.vmx'
$ESXHost = "esxir900.ktehnika.local"
$VMfolder = 'PrivateCloud'

#import in inventory
New-VM -VMFilePath $VMFilePath -VMHost $ESXHost -Location $VMFolder 

Get-VM hv2 | fl *
Start-VM hv2

Get-VM hv2 | Remove-VM

Get-VM _hv1 | Remove-VM -Confirm:$false
New-VM -VMFilePath '[FAS2020] hv1/_hv1.vmx' -VMHost esxirx300.ktehnika.local -Location $VMFolder 
Start-VM _hv1
