$serverlistpath=Read-Host "Enter complete serverlistpath(Eg:C:\Users\Desktop\files.txt)"
$sourcefile1 =Read-Host "Enter complete agent exe file path(Eg:C:\Users\Desktop\MMASetup-AMD64.exe)"
$sourcefile2 =Read-Host "Enter complete agent exe file path(Eg:C:\Users\Desktop\mmaagent.bat)"
$computername = Get-Content $serverlistpath
$myshell = New-Object -com "Wscript.Shell"
Start-Sleep -s 1
$myshell.sendkeys("Y{Enter}")
Set-Item -Path WSMan:\localhost\Client\TrustedHosts *
foreach($computer in $computername)
{     	
	$destinationFolder = "\\$computer\C$\Temp"
	if (!(Test-Path -path $destinationFolder))
	{
	        New-Item $destinationFolder -Type Directory
	}
	Copy-Item -Path $sourcefile1 -Recurse -Destination $destinationFolder; 
	Copy-Item -Path $sourcefile2 -Recurse -Destination $destinationFolder;
 	Invoke-Command -ComputerName $computer -ScriptBlock {Start-Process 'C:\temp\mmaagent.bat' /S -Wait }
	Start-Sleep -s 5
	Remove-Item \\$computer\c$\Temp -Recurse -force
	Start-Sleep -s 5
}