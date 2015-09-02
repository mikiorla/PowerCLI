Set-Variable -Name alarmLength -Value 80 -Option "constant" #The maximum length of the name of an Alarm defined as a constant.

$from = Get-Folder -Name "Datacenters" | Get-View	#Variables that will be used later on in the script as parameters to the function. 
$to1 = Get-Folder -Name "Folder1" | Get-View		#In the sample I’m moving all alarms from the vCenter root 
$to2 = Get-Folder -Name "Folder2" | Get-View		#(hidden entity “Datacenters”) to two folders called “Folder1″ and “Folder2″

function Move-Alarm{
	param($Alarm, $From, $To, [switch]$DeleteOriginal = $false)	# Note that the function doesn’t use strongly types parameters for the -From and -To parameters. 
																# This is because the ViObjects on which alarms can be defined can be of several types (Datacenter, Folder, HostSystem…). 
	$alarmObj = Get-View $Alarm									# This also allows to pass an array of ViObjects for the -To parameter.
	$alarmMgr = Get-View AlarmManager							# AlarmManager

	if($deleteOriginal){
		$alarmObj.RemoveAlarm()
	}
	else{														#If the -DeleteOriginal switch is set to $false the original_
		$updateAlarm = New-Object VMware.Vim.AlarmSpec			# _Alarm will be kept but it will be renamed since there can not be multiple alarms with the same name.
		$updateAlarm = $alarmObj.Info
		$oldName = $alarmObj.Info.Name
		$oldState = $alarmObj.Info.Enabled
		$oldDescription = $alarmObj.Info.Description
		$suffix = " (moved to " + ([string]($to | %{$_.Name + ","})).TrimEnd(",") + ")"
		if(($oldName.Length + $suffix.Length) -gt $alarmLength){
			$newName = $oldName.Substring(0, $alarmLength - $suffix.Length) + $suffix
		}
		else{
			$newName = $oldName + $suffix
		}
		$updateAlarm.Name =  $newName
		$updateAlarm.Enabled = $false
		$updateAlarm.Description += ("`rOriginal name: " + $oldName)
		$updateAlarm.Expression.Expression | %{
			if($_.GetType().Name -eq "EventAlarmExpression"){
				$_.Status = $null
				$needsChange = $true
			}
		}

		$alarmObj.ReconfigureAlarm($updateAlarm)

		$alarmObj.Info.Name = $oldName
		$alarmObj.Info.Enabled = $oldState
		$alarmObj.Info.Description = $oldDescription
	}

	$newAlarm = New-Object VMware.Vim.AlarmSpec
	$newAlarm = $alarmObj.Info

	$oldName = $alarmObj.Info.Name
	$oldDescription = $alarmObj.Info.Description

	foreach($destination in $To){
		if($To.Count -gt 1){
			$suffix = " (" + $destination.Name + ")"
			if(($oldName.Length + $suffix.Length) -gt $alarmLength){
				$newName = $oldName.Substring(0, $alarmLength - $suffix.Length) + $suffix
			}
			else{
				$newName = $oldName + $suffix
			}
			$newAlarm.Name = $newName
			$newAlarm.Description += ("`rOriginal name: " + $oldName)
		}
		$newAlarm.Expression.Expression | %{
			if($_.GetType().Name -eq "EventAlarmExpression"){
				$_.Status = $null
				$needsChange = $true
			}
		}

		$alarmMgr.CreateAlarm($destination.MoRef,$newAlarm)
		$newAlarm.Name = $oldName
		$newAlarm.Description = $oldDescription
	}
}

$alarmMgr = Get-View AlarmManager

$alarms = $alarmMgr.GetAlarm($from.MoRef)
$alarms | % {
	Move-Alarm -Alarm $_ -From (Get-View $_) -To $to1,$to2 -DeleteOriginal:$false
}