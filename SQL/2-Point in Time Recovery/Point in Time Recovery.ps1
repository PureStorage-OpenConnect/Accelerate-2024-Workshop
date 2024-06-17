##############################################################################################################################
# Point In Time Recovery - Using SQL Server 2022's T-SQL Snapshot Backup feature 
#
# Scenario: 
#    Perform a point in time restore using SQL Server 2022's T-SQL Snapshot Backup 
#    feature. This uses a FlashArray snapshot as the base of the restore, then restores 
#    a log backup.
#
# Usage Notes:
#   Each section of the script is meant to be run one after the other. 
#   The script is not meant to be executed all at once.
#
# Disclaimer:
#    This example script is provided AS-IS and is meant to be a building
#    block to be adapted to fit an individual organization's 
#    infrastructure.
##############################################################################################################################

# Import powershell modules
Import-Module dbatools
Import-Module PureStoragePowerShellSDK2

##############################################################################################################################
## 1 - Setting up the enviroment - Here you'll define some variables and make a SQL Server connections and connect to your FlashArray, get some database information
#


# Let's initalize some variables we'll use for connections to our SQL Server and it's base OS
$TargetSQLServer = 'Windows1'                         # SQL Server Name
$ArrayName       = 'flasharray1.testdrive.local'      # FlashArray
$DbName          = 'TPCC100'                          # Name of database
$BackupShare     = '\\Windows2\backup'                # File system location to write the backup metadata file
$FlashArrayDbVol = 'Windows1Vol1'                     # Volume name on FlashArray containing database files
$TargetDisk      = 'B64D29B183714E0600012395'         # The serial number if the Windows volume containing database files



# Set credential to connect to FlashArray, username pureuser, password testdrive
$Passowrd = ConvertTo-SecureString 'testdrive1' -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ('pureuser', $Passowrd)



# Connect to the FlashArray's REST API
$FlashArray = Connect-Pfa2Array -EndPoint $ArrayName -Credential $Credential -IgnoreCertificateError



# Build a persistent SMO connection.
$SqlInstance = Connect-DbaInstance -SqlInstance $TargetSQLServer -TrustServerCertificate -NonPooledConnection



# Let's get some information about our database, take note of the size, 12GB again.
Get-DbaDatabase -SqlInstance $SqlInstance -Database $DbName |
  Select-Object Name, SizeMB

##############################################################################################################################


##############################################################################################################################
## 2 - Taking an application consistent backup with SQL Server 2022's T-SQL-based snapshot feature.
##


# Let's use the new SQL Server 2022 TSQL-based snapshot to take an application consistent snapshot with no external tools!
# This code will freeze the database until we take the backup on line 81.
# Once you execute this code, the verbose output will report to you that the database is frozen.
$Query = "ALTER DATABASE $DbName SET SUSPEND_FOR_SNAPSHOT_BACKUP = ON"
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $Query -Verbose



# Take a snapshot of the Volume while the database is frozen
$Snapshot = New-Pfa2VolumeSnapshot -Array $FlashArray -SourceName $FlashArrayDbVol 
$Snapshot



# Take a metadata backup of the database, this will automatically unfreeze if successful.
# Since the backup is snapshot based, you will see that 0 pages have been backed up. This is normal.
# This command generates a small backup file in \\Windows2\backup which describes what's in the snapshot.
$BackupFile = "$BackupShare\$DbName$(Get-Date -Format FileDateTime).bkm"
$Query = "BACKUP DATABASE $DbName 
          TO DISK='$BackupFile' 
          WITH METADATA_ONLY"
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $Query -Verbose

##############################################################################################################################



##############################################################################################################################
## 3 - Examine the backup history according to SQL Server, check the error log and the backup history
##


# Let's check out the error log to see what SQL Server thinks happened, looking at the last line 
# you should see the string 'BACKUP DATABASE successfully processed 0 pages in 0.009 seconds (0.000 MB/sec).... ' indicating a successful backup
Get-DbaErrorLog -SqlInstance $SqlInstance -LogNumber 0 | Format-Table



# The backup is recorded in MSDB as a Full backup with snapshot, this backup time should be a few seconds ago
Get-DbaDbBackupHistory -SqlInstance $SqlInstance -Database $DbName -LastFull



# Now that we have a snapshot as a full backup, let's take a log backup
$LogBackup = Backup-DbaDatabase -SqlInstance $SqlInstance -Database $DbName -Type Log -Path $BackupShare -CompressBackup


# Looking at the backup history we see the full backup (snapshot) and the log backup we just took
Get-DbaDbBackupHistory -SqlInstance $SqlInstance -Database $DbName -Since (Get-Date).AddDays(-1)

##############################################################################################################################


##############################################################################################################################
## 4 - Deleting a Critical Database Table
##

# Delete a table...I should update my resume, right? :P 
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $DbName -Query "DROP TABLE customer"

##############################################################################################################################


##############################################################################################################################
## 5 - Performing a point in time restore using snapshot backup
##


# Offline the database, which we'd have to do anyway if we were restoring a full backup
$Query = "ALTER DATABASE $DbName SET OFFLINE WITH ROLLBACK IMMEDIATE" 
Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $Query



# Offline the volume that our database is on
Get-Disk | Where-Object { $_.SerialNumber -eq $TargetDisk } | Set-Disk -IsOffline $True 



# Restore the snapshot over the volume
New-Pfa2Volume -Array $FlashArray -Name $FlashArrayDbVol -SourceName ($Snapshot.Name) -Overwrite $true



# Online the volume
Get-Disk | Where-Object { $_.SerialNumber -eq $TargetDisk} | Set-Disk -IsOffline $False



# Restore the database with no recovery, which means we can restore LOG native SQL Server backups 
$Query = "RESTORE DATABASE $DbName FROM DISK = '$BackupFile' WITH METADATA_ONLY, REPLACE, NORECOVERY" 
Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $Query -Verbose



# Let's check the current state of the database...its RESTORING
Get-DbaDbState -SqlInstance $SqlInstance -Database $DbName 



# Restore the log backup. This is a regular native transaction log backup that we took earlier in the lab
Restore-DbaDatabase -SqlInstance $SqlInstance -Database $DbName -Path $LogBackup.BackupPath -NoRecovery -Continue


##############################################################################################################################
## 6 - Recovery the database and verify the data is restored
##

# Online the database
$Query = "RESTORE DATABASE $DbName WITH RECOVERY" 
Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $Query



# Let's see if our table is back in our database...
# whew...we don't have to tell anybody since our restore was so fast :P 
Get-DbaDbTable -SqlInstance $SqlInstance -Database $DbName -Table 'Customer' | Format-Table

##############################################################################################################################
## When you are finished, move on to demo 3 - Click File->Open->.\Accelerate-2024-Workshop-main\SQL\3-Seeding an Availability Group
##