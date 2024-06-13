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
#
# Here is a listing of the resources in your lab
# Windows1	    Primary administrator desktop and SQL Server Instance
# Windows2	    SQL Server Instance
# FlashArray1	Primary block storage device and storage subsystem for SQL Server instances
#
##############################################################################################################################

# Import powershell modules
Import-Module dbatools
Import-Module PureStoragePowerShellSDK2


# Declare variables
$SourceSqlServer         = 'Windows1'                                       # Name of target VM
$TargetSqlServer         = 'Windows2'                                       # Name of target VM
$ArrayName               = 'flasharray1.testdrive.local'                    # FlashArray FQDN
$TargetDiskSerialNumber  = 'B64D29B183714E0600012396'                       # Target Disk Serial Number
$SourceVolumeName        = 'Windows1Vol1'                                   # Source volume name on FlashArray
$TargetVolumeName        = 'Windows2Vol1'                                   # Target volume name on FlashArray



# Build a persistent SMO connection to use throughout this demo.
$SourceSqlInstance = Connect-DbaInstance -SqlInstance $SourceSqlServer -TrustServerCertificate -NonPooledConnection
$TargetSqlInstance = Connect-DbaInstance -SqlInstance $TargetSQLServer -TrustServerCertificate -NonPooledConnection



# Let's check out the size of the database we're going to clone, 12GB...the cloning operation is instant, regardless of databases size, 12KB or 12TB will take just as long.
Get-DbaDatabase -SqlInstance $SourceSqlInstance -Database 'TPCC100' |
  Select-Object Name, SizeMB



# Create a Powershell session against the target VM
$TargetSession = New-PSSession -ComputerName $TargetSqlServer



# Set credential to connect to FlashArray, username pureuser, password testdrive
$Password = ConvertTo-SecureString 'testdrive1' -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ('pureuser', $Password)




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
Invoke-DbaQuery -SqlInstance $TargetSqlInstance -Database master -Query $Query 



# Check out the clone on the Target Sql Instance, Windows2. We cloned the database instantly between two instances of SQL Server
Get-DbaDatabase -SqlInstance $TargetSqlInstance -Database 'TPCC100' |
  Select-Object Name, SizeMB


# Clean up
Remove-PSSession $TargetSession


# When you are finished, move on to demo 2 - Click File->Open->.\Accelerate-2024-Workshop-main\SQL\2-Point in Time Recovery\Point in Time Recovery.ps1