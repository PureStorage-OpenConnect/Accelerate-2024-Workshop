# Lab 3 - Seeding an Availability Group - Using SQL Server 2022's T-SQL Snapshot Backup 

# Scenario
In this activity, you will build an Availability Group from Snapshot leveraging FlashArray snapshots and the new [TSQL Based Snapshot Backup](https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/create-a-transact-sql-snapshot-backup?view=sql-server-ver16) functionality in SQL Server 2022. This lab is on both **Windows1** and **Windows2**

If you’ve been using Availability Groups, you’re familiar with the process of replica seeding (sometimes called initializing, preparing, or data synchronization). Seeding is a size of data operation, copying data from a primary replica to one or more secondary replicas. This is required before joining a database to an Availability Group. You can seed a replica with backup and restore, or with automatic seeding, each of which present their own challenges. Regardless of which method you use, the seeding operation can take an extended amount of time. The time it takes to seed a replica is based on the database's size, network, and storage speed. If you have multiple replicas, then seeding all of them is N times the fun!

But what if we told you that you could seed your Availability Group replicas from a storage-based snapshot and that the reseeding process can be nearly instantaneous?

In addition to saving you time, this process saves your database systems from the CPU, network, and disk consumption that comes with using either automatic seeding or backups and restores to seed. 

So let’s do it...we’re going to snapshot a database on **Windows1**, clone that snapshot to the second instance of SQL Server on **Windows2**, and seed an Availability Group replica from that. 

* **Windows1** will be the **primary replica** in the availability group. The TPCC100 database on **Windows1** will become the source of the availability group database. You will clone this database to **Windows2**. 
* **Windows2** - This will be the **secondary replica** in the availability group. There is already a copy of TPCC100 on this instance from a previous demo. You will overwrite that database with a clone operation based off of a snapshot from **Windows1**

## Demo Overview

Here's a high-level overview of the process:

* [Snapshot Backup on Primary Replica](#2---snapshot-backup-on-primary-replica) - Seeding an availability requires a full backup or direct seeding to move the data between replicas. Here, you will take a snapshot, allowing you to clone the volume instantly. 
* [Prepare Secondary Replica](#3---prepare-secondary-replica)—Rather than performing a full restore, you will perform a point-in-time restore instantly using a clone. You will then perform the normal seeding operations of taking an additional log backup on the primary, restoring it on the secondary replica,, leaving the database in `RESTORING` mode, and preparing it to join the AG.
* [Create the Availability Group](#4---create-the-availability-group) - Create the availability group using the cmdlet `New-DbaAvailabilityGroup`. This operation should only take several seconds. 
* [Validation](#5---validation) - Once finished, ensure that the synchronization state is **"Synchronized"**. 

> Each line of code below is intended to be executed sequentially to facilitate understanding, discovery and learning. Below you will find code and if there's output from the cmdlet you will see that immediatly below the cmdlet.

Here is a description of the major activities in this lab:

## 1 - Environment Setup

1. Define variables for primary and secondary SQL servers, AG name, database name, backup location, FlashArray details, and volume names.

    ```
    $PrimarySqlServer   = 'Windows1'                    # SQL Server Name - Primary Replica
    $SecondarySqlServer = 'Windows2'                    # SQL Server Name - Secondary Replica
    $AgName             = 'ag1'                         # Name of availability group
    $DbName             = 'TPCC100'                     # Name of database to place in AG
    $BackupShare        = '\\Windows2\backup'           # File location for metadata backup file.
    $FlashArrayName     = 'flasharray1.testdrive.local' # FlashArray containing the volumes for our primary replica
    $SourceVolumeName   = 'Windows1Vol1'                # Name of the Volume on FlashArray1 for Windows1
    $TargetVolumeName   = 'Windows2Vol1'                # Name of the Volume on FlashArray1 for Windows2
    ```

1. Establish PowerShell remoting sessions to the secondary replica and build SMO connections to both SQL Server instances.
    ```
    $SecondarySession = New-PSSession -ComputerName $SecondarySqlServer
    ```

1. Build persistent SMO connections to each SQL Server that will participate in the availability group
    ```
    $SqlInstancePrimary = Connect-DbaInstance -SqlInstance $PrimarySqlServer -TrustServerCertificate -NonPooledConnection 
    $SqlInstanceSecondary = Connect-DbaInstance -SqlInstance $SecondarySqlServer -TrustServerCertificate -NonPooledConnection 
    ```

1. Set credentials for FlashArray and connect to it, username `pureuser`, password `testdrive`
    ```
    $Passowrd = ConvertTo-SecureString 'testdrive1' -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ('pureuser', $Passowrd)
    $FlashArray = Connect-Pfa2Array -EndPoint $FlashArrayName -Credential $Credential -IgnoreCertificateError
    ```

## 2 - Snapshot Backup on Primary Replica

1. Suspend the primary database for a snapshot backup.
    ```
    $Query = "ALTER DATABASE [$DbName] SET SUSPEND_FOR_SNAPSHOT_BACKUP = ON"
    Invoke-DbaQuery -SqlInstance $SqlInstancePrimary -Query $Query -Verbose
    ```

    You should see output similar to this:

    ```
    VERBOSE: Database 'TPCC100' acquired suspend locks in session 156.
    VERBOSE: I/O is frozen on database TPCC100. No user action is required. However, if I/O is not resumed promptly, you could cancel the backup.
    VERBOSE: Database 'TPCC100' successfully suspended for snapshot backup in session 156.
    ```

1. Take a snapshot of the primary database volume.
    ```
    $SourceSnapshot = New-Pfa2VolumeSnapshot -Array $FlashArray -SourceName $SourceVolumeName
    ```

    You should see output similar to this:

    ```
    Id            : b5d4c9aa-80fe-f7f8-258e-67e8b8769647
    Name          : Windows1Vol1.12
    Created       : 6/18/2024 3:48:57 PM
    Destroyed     : False
    Pod           : 
    Provisioned   : 21474836480
    Source        : @{Id='cc8b751e-ec39-3f05-c485-f164f325451d'; Name='Windows1Vol1'}
    Suffix        : 12
    TimeRemaining : 
    Serial        : B64D29B183714E0600016A19
    Space         : @{Snapshots=0; TotalPhysical=0; TotalProvisioned=21474836480; Unique=0; Virtual=0; SnapshotsEffective=0}
    VolumeGroup   : 
    ```

1. Perform a metadata-only backup of the database, which will unfreeze the database.

    ```
    $BackupFile = "$BackupShare\$DbName$(Get-Date -Format FileDateTime).bkm"
    $Query = "BACKUP DATABASE $DbName 
            TO DISK='$BackupFile' 
            WITH METADATA_ONLY"
    Invoke-DbaQuery -SqlInstance $SqlInstancePrimary -Query $Query -Verbose
    ```

    You should see output similar to this:

    ```
    VERBOSE: I/O was resumed on database TPCC100. No user action is required.
    VERBOSE: Database 'TPCC100' released suspend locks in session 156.
    VERBOSE: Database 'TPCC100' originally suspended for snapshot backup in session 156 successfully resumed in session 156.
    VERBOSE: Processed 0 pages for database 'TPCC100', file 'tpcc100' on file 1.
    VERBOSE: BACKUP DATABASE successfully processed 0 pages in 0.008 seconds (0.000 MB/sec).
    ```

## 3 - Prepare Secondary Replica

1. Offline the database on the secondary replica. These are going to be joined to the availability group.  The primary can stay online.

    ```
    $Query = "ALTER DATABASE [$DbName] SET OFFLINE WITH ROLLBACK IMMEDIATE"
    Invoke-DbaQuery -SqlInstance $SqlInstanceSecondary -Query $Query
    ```

1. Offline the volume on the secondary replica. 

    ```
    Invoke-Command -Session $SecondarySession -ScriptBlock { Get-Disk | Where-Object { $_.SerialNumber -eq $using:TargetDisk } | Set-Disk -IsOffline $True }
    ```

1. Overwrite the secondary Volume with the snapshot from the primary.
    ```
    New-Pfa2Volume -Array $FlashArray -Name $TargetVolumeName -SourceName ($SourceSnapshot.Name) -Overwrite $true
    ```

    You should see output similar to this:

    ```
    Id                      : 1085e55c-3077-8e71-ae67-8a2613e88410
    Name                    : Windows2Vol1
    ConnectionCount         : 1
    Created                 : 6/18/2024 3:48:57 PM
    Destroyed               : False
    HostEncryptionKeyStatus : none
    PriorityAdjustment      : @{PriorityAdjustmentOperator='+'; PriorityAdjustmentValue=0}
    Provisioned             : 21474836480
    Qos                     : 
    Serial                  : B64D29B183714E0600012396
    Space                   : @{DataReduction=6.068545; Snapshots=47656; ThinProvisioning=0.5451922; TotalPhysical=145315; TotalProvisioned=21474836480; TotalReduction=13.3431; 
                            Unique=97659; Virtual=9766922752; SnapshotsEffective=231740416; TotalEffective=241702912; UniqueEffective=9962496}
    TimeRemaining           : 
    Pod                     : 
    Priority                : 0
    PromotionStatus         : promoted
    RequestedPromotionState : promoted
    Source                  : @{Id='cc8b751e-ec39-3f05-c485-f164f325451d'; Name='Windows1Vol1'}
    Subtype                 : regular
    VolumeGroup             : 
    ```

1. Bring the volumes back online 
    ```
    Invoke-Command -Session $SecondarySession -ScriptBlock { Get-Disk | Where-Object { $_.SerialNumber -eq $using:TargetDisk } | Set-Disk -IsOffline $False }
    ```

1. Restore the database with the NORECOVERY option, leaving it in RESTORING mode.
    ```
    $Query = "RESTORE DATABASE [$DbName] FROM DISK = '$BackupFile' WITH METADATA_ONLY, REPLACE, NORECOVERY" 
    Invoke-DbaQuery -SqlInstance $SqlInstanceSecondary -Database master -Query $Query -Verbose
    ```

    You should see output similar to this:

    ```
    VERBOSE: RESTORE DATABASE successfully processed 0 pages in 0.722 seconds (0.000 MB/sec).
    ```

1. Take a log backup on the primary 

    ```
    $Query = "BACKUP LOG [$DbName] TO DISK = '$BackupShare\$DbName-seed.trn' WITH FORMAT, INIT" 
    Invoke-DbaQuery -SqlInstance $SqlInstancePrimary -Database master -Query $Query -Verbose
    ```

    You should see output similar to this:

    ```
    VERBOSE: Processed 3 pages for database 'TPCC100', file 'tpcc100_log' on file 1.
    VERBOSE: BACKUP LOG successfully processed 3 pages in 0.054 seconds (0.406 MB/sec).
    ```

1. Restore it on the secondary to prepare the secondary replica to join the availability group.
    ```
    $Query = "RESTORE LOG [$DbName] FROM DISK = '$BackupShare\$DbName-seed.trn' WITH NORECOVERY" 
    Invoke-DbaQuery -SqlInstance $SqlInstanceSecondary -Database master -Query $Query -Verbose
    ```

    You should see output similar to this:

    ```
    VERBOSE: Processed 0 pages for database 'TPCC100', file 'tpcc100' on file 1.
    VERBOSE: Processed 3 pages for database 'TPCC100', file 'tpcc100_log' on file 1.
    VERBOSE: RESTORE LOG successfully processed 3 pages in 0.063 seconds (0.348 MB/sec).
    ```

## 4 - Create the Availability Group

1. Create and distribute certificates for authentication between replicas. This is commonly done using Active Directory, this lab use certificates since there is no Active Directory Domain. First, let's create the certificates on Window1.

    ```
    New-DbaDbCertificate -SqlInstance $SqlInstancePrimary -Name ag_cert -Subject ag_cert -StartDate (Get-Date) -ExpirationDate (Get-Date).AddYears(10) -Confirm:$false

    Backup-DbaDbCertificate -SqlInstance $SqlInstancePrimary -Certificate ag_cert -Path $BackupShare -EncryptionPassword $Credential.Password -Confirm:$false
    ```

    You should see output similar to this:

    ```
    ComputerName                 : Windows1
    InstanceName                 : MSSQLSERVER
    SqlInstance                  : Windows1
    Database                     : master
    Name                         : ag_cert
    Subject                      : ag_cert
    StartDate                    : 6/18/2024 12:00:00 AM
    ActiveForServiceBrokerDialog : False
    ExpirationDate               : 6/18/2034 12:00:00 AM
    Issuer                       : ag_cert
    LastBackupDate               : 1/1/0001 12:00:00 AM
    Owner                        : dbo
    PrivateKeyEncryptionType     : MasterKey
    Serial                       : 7d 98 4f be 3b ec bd 80 49 4f 78 26 24 3a 79 98

    Certificate  : ag_cert
    ComputerName : Windows1
    Database     : master
    DatabaseID   : 1
    InstanceName : MSSQLSERVER
    Key          : \\Windows2\backup\Windows1-master-ag_cert.pvk
    Path         : \\Windows2\backup\Windows1-master-ag_cert.cer
    SqlInstance  : Windows1
    Status       : Success

    ```


    Now let's restore those certificates on Windows1. 

    ```
    $Certificate = (Get-DbaFile -SqlInstance $SqlInstancePrimary -Path $BackupShare -FileType cer).FileName

    Restore-DbaDbCertificate -SqlInstance $SqlInstanceSecondary -Path $Certificate -DecryptionPassword $Credential.Password -Confirm:$false
    ```

    You should see output similar to this:

    ```
    ComputerName                 : Windows2
    InstanceName                 : MSSQLSERVER
    SqlInstance                  : Windows2
    Database                     : master
    Name                         : ag_cert
    Subject                      : ag_cert
    StartDate                    : 6/18/2024 12:00:00 AM
    ActiveForServiceBrokerDialog : True
    ExpirationDate               : 6/18/2034 12:00:00 AM
    Issuer                       : ag_cert
    LastBackupDate               : 1/1/0001 12:00:00 AM
    Owner                        : dbo
    PrivateKeyEncryptionType     : MasterKey
    Serial                       : 7d 98 4f be 3b ec bd 80 49 4f 78 26 24 3a 79 98
    ```

1. Set permissions for the AG.

    ```
    $Query = 'GRANT ALTER ANY AVAILABILITY GROUP TO [NT AUTHORITY\SYSTEM];
    GRANT CONNECT SQL TO [NT AUTHORITY\SYSTEM];
    GRANT VIEW SERVER STATE TO [NT AUTHORITY\SYSTEM];
    '
    Invoke-DbaQuery -SqlInstance $SqlInstancePrimary -Query $Query -Verbose
    Invoke-DbaQuery -SqlInstance $SqlInstanceSecondary -Query $Query -Verbose
    ````

1. Use the `New-DbaAvailabilityGroup` cmdlet to create the AG with the specified parameters, including manual failover, seeding mode and using the certificate we just created. 

    ```
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
    ```

    You should see output similar to this:

    ```
    ComputerName               : Windows1
    InstanceName               : MSSQLSERVER
    SqlInstance                : Windows1
    LocalReplicaRole           : Primary
    AvailabilityGroup          : ag1
    PrimaryReplica             : Windows1
    ClusterType                : None
    DtcSupportEnabled          : False
    AutomatedBackupPreference  : Secondary
    AvailabilityReplicas       : {Windows1, Windows2}
    AvailabilityDatabases      : {TPCC100}
    AvailabilityGroupListeners : {}
    ```

## 5 - Validation

1. Check the status of the AG to ensure that the synchronization state is **"Synchronized"**.
    ```
    Get-DbaAgDatabase -SqlInstance $SqlInstancePrimary -AvailabilityGroup $AgName 
    ```

    ```
    ComputerName               : Windows1
    InstanceName               : MSSQLSERVER
    SqlInstance                : Windows1
    LocalReplicaRole           : Primary
    AvailabilityGroup          : ag1
    PrimaryReplica             : Windows1
    ClusterType                : None
    DtcSupportEnabled          : False
    AutomatedBackupPreference  : Secondary
    AvailabilityReplicas       : {Windows1, Windows2}
    AvailabilityDatabases      : {TPCC100}
    AvailabilityGroupListeners : {}
    ```


## Activity Summary and Wrapping Things Up
In this activity, you initialized an availability group using T-SQL-based snapshots inside SQL Server with array-based snapshots in FlashArray, nearly instantaneously. Traditional availability group initialization or reseeding requires a size of data operation via either backup and restore or direct seeding. 

There's one nuance I want to call out here in this activity. This all happened on one array in our test lab. You will likely want your availability group replicas on separate arrays in a production environment. If you want to dive into the details of that, check out the post in the More Resources section below.

Futher, if you want to deep dive into many more SQL Server use-cases on FlashArray Check out our team's script reposistory at [Pure Storage OpenConnect SQL Server Scripts](https://github.com/PureStorage-OpenConnect/sqlserver-scripts/)

<br />
<br />

# More Resources
- [Seeding an Availability Group Replica from Snapshot](https://www.nocentino.com/posts/2022-05-26-seed-ag-replica-from-snapshot/)
- [Pure Storage OpenConnect SQL Server Scripts](https://github.com/PureStorage-OpenConnect/sqlserver-scripts/)

