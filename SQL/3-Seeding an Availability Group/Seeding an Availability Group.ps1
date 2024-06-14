##############################################################################################################################
#Seeding an Availability Group - Using SQL Server 2022's T-SQL Snapshot Backup feature 
# Scenario:
#   Seeding an Availability Group (AG) from SQL Server 2022's T-SQL Snapshot Backup
#
# Usage Notes:
#   Each section of the script is meant to be run one after the other. The script is not meant to be executed all at once.
#
# Disclaimer
#   This example script is provided AS-IS and is meant to be a building 
#   block to be adapted to fit an individual organization's infrastructure.
##############################################################################################################################
# Import powershell modules
Import-Module dbatools
Import-Module PureStoragePowerShellSDK2

##############################################################################################################################
## 1 - Setting up the enviroment - Here you'll define some variables and make a SQL Server connections and connect to your FlashArray, get some database information
#

# Set up some variables and sessions to talk to the replicas in the AG
$PrimarySqlServer   = 'Windows1'                    # SQL Server Name - Primary Replica
$SecondarySqlServer = 'Windows2'                    # SQL Server Name - Secondary Replica
$AgName             = 'ag1'                         # Name of availability group
$DbName             = 'TPCC100'                     # Name of database to place in AG
$BackupShare        = '\\Windows2\backup'           # File location for metadata backup file.
$FlashArrayName     = 'flasharray1.testdrive.local' # FlashArray containing the volumes for our primary replica
$SourceVolumeName   = 'Windows1Vol1'                # Name of the Protection Group on FlashArray1
$TargetVolumeName   = 'Windows2Vol1'                # Name of the Protection Group replicated from FlashArray1 to FlashArray2, in the format of ArrayName:ProtectionGroupName
$TargetDisk         = 'B64D29B183714E0600012396'    # The serial number if the Windows volume containing database files



# Build a PowerShell Remoting Session to the secondary replica
$SecondarySession = New-PSSession -ComputerName $SecondarySqlServer



# Build persistent SMO connections to each SQL Server that will participate in the availability group
$SqlInstancePrimary = Connect-DbaInstance -SqlInstance $PrimarySqlServer -TrustServerCertificate -NonPooledConnection 
$SqlInstanceSecondary = Connect-DbaInstance -SqlInstance $SecondarySqlServer -TrustServerCertificate -NonPooledConnection 



# Set credential to connect to FlashArray, username pureuser, password testdrive
$Passowrd = ConvertTo-SecureString 'testdrive1' -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ('pureuser', $Passowrd)



# Connect to the FlashArray with for the AG Primary
$FlashArray = Connect-Pfa2Array -EndPoint $FlashArrayName -Credential $Credential -IgnoreCertificateError

##############################################################################################################################


##############################################################################################################################
## 2 - Take a snapshot backup of the database on the instance that will become the primary replica in the availability group
##

# Freeze the database 
$Query = "ALTER DATABASE [$DbName] SET SUSPEND_FOR_SNAPSHOT_BACKUP = ON"
Invoke-DbaQuery -SqlInstance $SqlInstancePrimary -Query $Query -Verbose



# Take a snapshot of the Protection Group, and replicate it to our other array
$SourceSnapshot = New-Pfa2VolumeSnapshot -Array $FlashArray -SourceName $SourceVolumeName


# Take a metadata backup of the database, this will automatically unfreeze if successful
$BackupFile = "$BackupShare\$DbName$(Get-Date -Format FileDateTime).bkm"
$Query = "BACKUP DATABASE $DbName 
          TO DISK='$BackupFile' 
          WITH METADATA_ONLY"
Invoke-DbaQuery -SqlInstance $SqlInstancePrimary -Query $Query -Verbose


##############################################################################################################################


##############################################################################################################################
## 3 - Prepare the secondary replica to perform a point in time restor and leaving the database in RESTORING mode to join the availability group
##

# Offline the database on the Secondary Replica
$Query = "ALTER DATABASE [$DbName] SET OFFLINE WITH ROLLBACK IMMEDIATE"
Invoke-DbaQuery -SqlInstance $SqlInstanceSecondary -Query $Query



# Offline the volumes on the Secondary
Invoke-Command -Session $SecondarySession -ScriptBlock { Get-Disk | Where-Object { $_.SerialNumber -eq $using:TargetDisk } | Set-Disk -IsOffline $True }



# Overwrite the volumes on the Secondary from the protection group snapshot
New-Pfa2Volume -Array $FlashArray -Name $TargetVolumeName -SourceName ($SourceSnapshot.Name) -Overwrite $true



# Online the volumes on the Secondary
Invoke-Command -Session $SecondarySession -ScriptBlock { Get-Disk | Where-Object { $_.SerialNumber -eq $using:TargetDisk } | Set-Disk -IsOffline $False }



# Restore the database with no recovery...the database state should be RESTORING
$Query = "RESTORE DATABASE [$DbName] FROM DISK = '$BackupFile' WITH METADATA_ONLY, REPLACE, NORECOVERY" 
Invoke-DbaQuery -SqlInstance $SqlInstanceSecondary -Database master -Query $Query -Verbose



# Take a log backup on the Primary
$Query = "BACKUP LOG [$DbName] TO DISK = '$BackupShare\$DbName-seed.trn' WITH FORMAT, INIT" 
Invoke-DbaQuery -SqlInstance $SqlInstancePrimary -Database master -Query $Query -Verbose



# Restore it on the Secondary
$Query = "RESTORE LOG [$DbName] FROM DISK = '$BackupShare\$DbName-seed.trn' WITH NORECOVERY" 
Invoke-DbaQuery -SqlInstance $SqlInstanceSecondary -Database master -Query $Query -Verbose

##############################################################################################################################


##############################################################################################################################
## 4 - Create the availability group on the primary replica, first create some certificates for the replicas to authenticate to each other
##     We'll set come permissions on the endpoing and then we will use the cmdlet New-DbaAvailabilityGroup to build the AG 
##


#Now create a new certificate on Windows1, backup the certificate on Windows1 and restore it to Windows2
New-DbaDbCertificate -SqlInstance $SqlInstancePrimary -Name ag_cert -Subject ag_cert -StartDate (Get-Date) -ExpirationDate (Get-Date).AddYears(10) -Confirm:$false
Backup-DbaDbCertificate -SqlInstance $SqlInstancePrimary -Certificate ag_cert -Path $BackupShare -EncryptionPassword $Credential.Password -Confirm:$false


$Certificate = (Get-DbaFile -SqlInstance $SqlInstancePrimary -Path $BackupShare -FileType cer).FileName
Restore-DbaDbCertificate -SqlInstance $SqlInstanceSecondary -Path $Certificate -DecryptionPassword $Credential.Password -Confirm:$false



$Query = 'GRANT ALTER ANY AVAILABILITY GROUP TO [NT AUTHORITY\SYSTEM];
GRANT CONNECT SQL TO [NT AUTHORITY\SYSTEM];
GRANT VIEW SERVER STATE TO [NT AUTHORITY\SYSTEM];
'
Invoke-DbaQuery -SqlInstance $SqlInstancePrimary -Query $Query -Verbose
Invoke-DbaQuery -SqlInstance $SqlInstanceSecondary -Query $Query -Verbose



#Now, let's create the AG, lots 'o parameters. This creates a clusterless, manual failover AG using the certificate we just created to authenticate the database mirroring endpoints
New-DbaAvailabilityGroup `
    -Primary $SqlInstancePrimary `
    -Secondary $SqlInstanceSecondary `
    -Name $AgName `
    -Database $DbName `
    -ClusterType None  `
    -FailoverMode Manual `
    -SeedingMode Manual `
    -SharedPath $BackupShare `
    -Certificate 'ag_cert' `
    -Verbose -Confirm:$false



# Now let's check the status of the AG...check to see if the SynchronizationState is Synchronized
Get-DbaAgDatabase -SqlInstance $SqlInstancePrimary -AvailabilityGroup $AgName 

##############################################################################################################################
# When you are finished, move on to demo 4 - Click File->Open->.\Accelerate-2024-Workshop-main\SQL\4-Working with the FlashArray API\Working with the FlashArray API.ps1