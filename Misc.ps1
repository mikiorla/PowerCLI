$a = gwmi -Class Win32_NetworkAdapterConfiguration 
$a | gm
$a | fl *

#blue screen
(gwmi -Class win32_process -ComputerName test-hy1 -Filter 'Name="wininit.exe"').Terminate()
