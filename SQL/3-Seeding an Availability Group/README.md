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

1. Take a snapshot of the primary database volume.
    ```
    $SourceSnapshot = New-Pfa2VolumeSnapshot -Array $FlashArray -SourceName $SourceVolumeName
    ```

1. Perform a metadata-only backup of the database, which will unfreeze the database.

    ```
    $BackupFile = "$BackupShare\$DbName$(Get-Date -Format FileDateTime).bkm"
    $Query = "BACKUP DATABASE $DbName 
            TO DISK='$BackupFile' 
            WITH METADATA_ONLY"
    Invoke-DbaQuery -SqlInstance $SqlInstancePrimary -Query $Query -Verbose
    ```


## 3 - Prepare Secondary Replica

1. Offline the database and volumes on the secondary replica. These are going to be joined to the availability group.  The primary can stay online.

    ```
    $Query = "ALTER DATABASE [$DbName] SET OFFLINE WITH ROLLBACK IMMEDIATE"
    Invoke-DbaQuery -SqlInstance $SqlInstanceSecondary -Query $Query
    ```

    ```
    Invoke-Command -Session $SecondarySession -ScriptBlock { Get-Disk | Where-Object { $_.SerialNumber -eq $using:TargetDisk } | Set-Disk -IsOffline $True }
    ```

1. Overwrite the secondary Volume with the snapshot from the primary.
    ```
    New-Pfa2Volume -Array $FlashArray -Name $TargetVolumeName -SourceName ($SourceSnapshot.Name) -Overwrite $true
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

1. Take a log backup on the primary 

    ```
    $Query = "BACKUP LOG [$DbName] TO DISK = '$BackupShare\$DbName-seed.trn' WITH FORMAT, INIT" 
    Invoke-DbaQuery -SqlInstance $SqlInstancePrimary -Database master -Query $Query -Verbose
    ```

1. Restore it on the secondary to prepare the secondary replica to join the availability group.
    ```
    $Query = "RESTORE LOG [$DbName] FROM DISK = '$BackupShare\$DbName-seed.trn' WITH NORECOVERY" 
    Invoke-DbaQuery -SqlInstance $SqlInstanceSecondary -Database master -Query $Query -Verbose
    ```

## 4 - Create the Availability Group

1. Create and distribute certificates for authentication between replicas. This is commonly done using Active Directory, this lab use certificates since there is no Active Directory Domain. First, let's create the certificates on Window1.

    ```
    New-DbaDbCertificate -SqlInstance $SqlInstancePrimary -Name ag_cert -Subject ag_cert -StartDate (Get-Date) -ExpirationDate (Get-Date).AddYears(10) -Confirm:$false

    Backup-DbaDbCertificate -SqlInstance $SqlInstancePrimary -Certificate ag_cert -Path $BackupShare -EncryptionPassword $Credential.Password -Confirm:$false
    ```

    Now let's restore those certificates on Windows1. 

    ```
    $Certificate = (Get-DbaFile -SqlInstance $SqlInstancePrimary -Path $BackupShare -FileType cer).FileName

    Restore-DbaDbCertificate -SqlInstance $SqlInstanceSecondary -Path $Certificate -DecryptionPassword $Credential.Password -Confirm:$false
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

## 5 - Validation

1. Check the status of the AG to ensure that the synchronization state is **"Synchronized"**.
    ```
    Get-DbaAgDatabase -SqlInstance $SqlInstancePrimary -AvailabilityGroup $AgName 
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

