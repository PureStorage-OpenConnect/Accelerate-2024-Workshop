##############################################################################################################################
# Volume Database Refresh
#
# Scenario: 
#   Script will refresh a database on the target server from a source database on a separate server
#
#
# Usage Notes:
#   Each section of the script is meant to be run one after the other. The script is not meant to be executed all at once.
# 
# Disclaimer:
# This example script is provided AS-IS and meant to be a building block to be adapted to fit an individual 
# organization's infrastructure.
# 
# THIS IS A SAMPLE SCRIPT WE USE FOR DEMOS! _PLEASE_ do not save your passwords in cleartext here. 
# Use NTFS secured, encrypted files or whatever else -- never cleartext!
#
##############################################################################################################################




# Here is a listing of the resources in your lab
# Windows1	    Primary administrator desktop and SQL Server Instance
# Windows2	    SQL Server Instance
# FlashArray1	Primary block storage device and storage subsystem for SQL Server instances



# Install the required PowerShell module, click yes to all for the popups regarding installation.
# Click 'yes to all' for the popups regarding installation. 
# dbatools in not required but makes the workflow easier
Install-Module PureStoragePowerShellSDK2
Install-Module dbatools



##
# Open SQL Server Management Studio on the desktop and connect to Windows1 and Windows2
##



# Declare variables
$Target                  = 'Windows2'                                       # Name of target VM
$ArrayName               = 'flasharray1.testdrive.local'                    # FlashArray FQDN
$TargetDiskSerialNumber  = 'B64D29B183714E0600012396'                       # Target Disk Serial Number
$SourceVolumeName        = 'Windows1Vol1'                                   # Source volume name on FlashArray
$TargetVolumeName        = 'Windows2Vol1'                                   # Target volume name on FlashArray



# Create a Powershell session against the target VM
$TargetSession = New-PSSession -ComputerName $Target



# Set credential to connect to FlashArray, username pureuser, password testdrive
$Passowrd = ConvertTo-SecureString 'testdrive1' -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ('pureuser', $Passowrd)




# Offline the volume
Invoke-Command -Session $TargetSession -ScriptBlock { Get-Disk | Where-Object { $_.SerialNumber -eq $using:TargetDiskSerialNumber } | Set-Disk -IsOffline $True }



# Connect to the FlashArray's REST API, notice that by default the API version autonegotiates to the highest version. You can specify the exact version you want with the -ApiVersion parameter
$FlashArray = Connect-Pfa2Array -EndPoint $ArrayName -Credential $Credential -IgnoreCertificateError -Verbose



# You can examine the currently used ApiVerion by outputting the $FlashArray Variable
$FlashArray



# Perform the volume overwrite 
New-Pfa2Volume -Array $FlashArray -Name $TargetVolumeName -SourceName $SourceVolumeName  -Overwrite $true 



# Online the volume
Invoke-Command -Session $TargetSession -ScriptBlock { Get-Disk | ? { $_.SerialNumber -eq $using:TargetDiskSerialNumber } | Set-Disk -IsOffline $False }



# Online the database
$Query = "CREATE DATABASE [TPCC100] ON ( FILENAME = N'D:\SQL\tpcc100.mdf' ), ( FILENAME = N'D:\SQL\tpcc100_log.ldf' ) FOR ATTACH"
Invoke-DbaQuery -ServerInstance $Target -Database master -Query $Query



## Go back to SQL Server Management Studio and refresh the listing of databases on Windows2 by expanding the Server Name, then Databases, then right click Refresh on the Databases 



# Clean up
Remove-PSSession $TargetSession
