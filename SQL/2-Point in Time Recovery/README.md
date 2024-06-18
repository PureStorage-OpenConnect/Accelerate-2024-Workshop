# Lab 2 - Point In Time Recovery - Using SQL Server 2022's T-SQL Snapshot Backup 

# Scenario
In this lab you will learn how to perform a point-in-time restore using SQL Server 2022's [TSQL Based Snapshot Backup](https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/create-a-transact-sql-snapshot-backup?view=sql-server-ver16) feature, leveraging a FlashArray snapshot as the base and restoring a log backup. This lab is on **Windows1**

> Each line of code below is intended to be executed sequentially to facilitate understanding, discovery and learning.

Here is a description of the major activities in this lab:

## 1 - Setting up the enviroment

1. **Define Variables:** Set up variables for the target SQL Server, FlashArray name, database name, backup location, FlashArray volume name, and target disk serial number.
    ```
    $TargetSQLServer = 'Windows1'                         # SQL Server Name
    $ArrayName       = 'flasharray1.testdrive.local'      # FlashArray
    $DbName          = 'TPCC100'                          # Name of database
    $BackupShare     = '\\Windows2\backup'                # File system location to write the backup metadata file
    $FlashArrayDbVol = 'Windows1Vol1'                     # Volume name on FlashArray containing database files
    $TargetDisk      = 'B64D29B183714E0600012395'         # The serial number if the Windows volume containing database files
    ```

1. **Set Credentials:** Create credentials for connecting to the FlashArray, username pureuser, password testdrive

    ```
    $Passowrd = ConvertTo-SecureString 'testdrive1' -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ('pureuser', $Passowrd)
    ```

1. **Connect to FlashArray:** Establish a connection to the FlashArray's REST API.
    ```
    $FlashArray = Connect-Pfa2Array -EndPoint $ArrayName -Credential $Credential -IgnoreCertificateError
    ```

1. **SQL Server Connection:** Build a persistent SMO connection to the SQL Server instance (Windows1).
    ```
    $SqlInstance = Connect-DbaInstance -SqlInstance $TargetSQLServer -TrustServerCertificate -NonPooledConnection
    ```

1. **Database Information:** Retrieve and display the size of the target database (TPCC100), take note of the size, 12GB again.
    ```
    Get-DbaDatabase -SqlInstance $SqlInstance -Database $DbName | Select-Object Name, SizeMB

    Name    SizeMB
    ----    ------
    TPCC100  12288
    ```

## 2 - Taking an application consistent backup with SQL Server 2022's T-SQL-based snapshot feature.

1. **Suspend Database for Snapshot:** Use the new SQL Server 2022 T-SQL to suspend the database to ensure an application-consistent snapshot, with no external tools. This code will freeze the database until we take the metadata backup below. 

    ```
    $Query = "ALTER DATABASE $DbName SET SUSPEND_FOR_SNAPSHOT_BACKUP = ON"
    Invoke-DbaQuery -SqlInstance $SqlInstance -Query $Query -Verbose
    ```

    Once you execute this code, the verbose output will report to you that the database is frozen. You should see output similar to what is below.

    ```
    VERBOSE: Database 'TPCC100' acquired suspend locks in session 149.
    VERBOSE: I/O is frozen on database TPCC100. No user action is required. However, if I/O is not resumed promptly, you could cancel the backup.
    VERBOSE: Database 'TPCC100' successfully suspended for snapshot backup in session 149.
    ```

1. **Create Snapshot:** Take a snapshot of the Volume while the database is suspended. You should see output similar to what is below, indicating the success of the snapshot. 

    ```
    $Snapshot = New-Pfa2VolumeSnapshot -Array $FlashArray -SourceName $FlashArrayDbVol
    $Snapshot

    Id            : 4aaa1f35-6d02-9db6-15c8-e2755ba116d3
    Name          : Windows1Vol1.10
    Created       : 6/18/2024 3:37:03 PM
    Destroyed     : False
    Pod           : 
    Provisioned   : 21474836480
    Source        : @{Id='cc8b751e-ec39-3f05-c485-f164f325451d'; Name='Windows1Vol1'}
    Suffix        : 10
    TimeRemaining : 
    Serial        : B64D29B183714E0600016A17
    Space         : @{Snapshots=0; TotalPhysical=0; TotalProvisioned=21474836480; Unique=0; Virtual=0; SnapshotsEffective=0}
    VolumeGroup   :  
    ```

1. **Metadata Backup:** Perform a metadata-only backup of the database, which creates a small backup file in `\\Windows2\backup` describing the snapshot contents. Once complete, the database automatially unfreezes. 

    ```
    $BackupFile = "$BackupShare\$DbName$(Get-Date -Format FileDateTime).bkm"
    $Query = "BACKUP DATABASE $DbName 
            TO DISK='$BackupFile' 
            WITH METADATA_ONLY"
    Invoke-DbaQuery -SqlInstance $SqlInstance -Query $Query -Verbose
    ```

    If the snapshot backup is successful, you should see output similar to what is below.

    ```
    VERBOSE: I/O was resumed on database TPCC100. No user action is required.
    VERBOSE: Database 'TPCC100' released suspend locks in session 149.
    VERBOSE: Database 'TPCC100' originally suspended for snapshot backup in session 149 successfully resumed in session 149.
    VERBOSE: Processed 0 pages for database 'TPCC100', file 'tpcc100' on file 1.
    VERBOSE: BACKUP DATABASE successfully processed 0 pages in 0.027 seconds (0.000 MB/sec).
    ``

## 3 - Examine the backup history according to SQL Server, check the error log and the backup history

1. **Check Error Log:** Review the SQL Server error log to confirm that the snapshot backup was successful. You should see the string `BACKUP DATABASE successfully processed 0 pages in 0.009 seconds (0.000 MB/sec)...` indicating a successful backup

    ```
    Get-DbaErrorLog -SqlInstance $SqlInstance -LogNumber 0 | Format-Table
    Windows1     MSSQLSERVER  Windows1    6/18/2024 8:37:59 AM spid149 Database 'TPCC100' originally suspended for snapshot backup in session 149 successfully resumed in session 149.  
    Windows1     MSSQLSERVER  Windows1    6/18/2024 8:37:59 AM Backup  Database backed up. Database: TPCC100, creation date(time): 2023/04/26(01:31:53), pages dumped: 917114, first ...
    Windows1     MSSQLSERVER  Windows1    6/18/2024 8:37:59 AM Backup  BACKUP DATABASE successfully processed 0 pages in 0.027 seconds (0.000 MB/sec)....
    ```

1. **Backup History:** Examine the backup history in MSDB to verify that the full backup (snapshot) and subsequent log backup are recorded.

    ```
    Get-DbaDbBackupHistory -SqlInstance $SqlInstance -Database $DbName -LastFull

    SqlInstance Database Type TotalSize DeviceType Start                   Duration End                    
    ----------- -------- ---- --------- ---------- -----                   -------- ---                    
    Windows1    TPCC100  Full 7.00 GB   Disk       2024-06-18 08:37:59.000 00:00:00 2024-06-18 08:37:59.000

    ```

1. **Log Backup:** Perform a transaction log backup to capture changes made after the snapshot.

    ```
    $LogBackup = Backup-DbaDatabase -SqlInstance $SqlInstance -Database $DbName -Type Log -Path $BackupShare -CompressBackup
    ```

1. **Backup History Revisited:**  Looking at the backup history we see the full backup (snapshot) and the log backup we just took.

    ```
    Get-DbaDbBackupHistory -SqlInstance $SqlInstance -Database $DbName -Since (Get-Date).AddDays(-1)

    SqlInstance Database Type TotalSize DeviceType Start                   Duration End                    
    ----------- -------- ---- --------- ---------- -----                   -------- ---                    
    Windows1    TPCC100  Log  813.00 KB Disk       2024-06-18 08:40:43.000 00:00:00 2024-06-18 08:40:43.000
    Windows1    TPCC100  Full 7.00 GB   Disk       2024-06-18 08:37:59.000 00:00:00 2024-06-18 08:37:59.000
    ```

## 4 - Deleting a Critical Database Table

1.  Delete a table...I should update my resume, right? :P 

    ```
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $DbName -Query "DROP TABLE customer"
    ```

## 5 - Performing a point in time restore using snapshot backup

1. **Offline the Database:** Take the database offline, which is necessary for a full restore.
    ```
    $Query = "ALTER DATABASE $DbName SET OFFLINE WITH ROLLBACK IMMEDIATE" 
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $Query
    ```

1. **Offline the Volume:** Offline the disk volume containing the database files.
    ```
    Get-Disk | Where-Object { $_.SerialNumber -eq $TargetDisk } | Set-Disk -IsOffline $True 
    ```

1. **Restore Snapshot:** Overwrite the existing volume with the snapshot taken earlier.

    ```
    New-Pfa2Volume -Array $FlashArray -Name $FlashArrayDbVol -SourceName ($Snapshot.Name) -Overwrite $true

    Id                      : cc8b751e-ec39-3f05-c485-f164f325451d
    Name                    : Windows1Vol1
    ConnectionCount         : 1
    Created                 : 6/18/2024 3:37:03 PM
    Destroyed               : False
    HostEncryptionKeyStatus : none
    PriorityAdjustment      : @{PriorityAdjustmentOperator='+'; PriorityAdjustmentValue=0}
    Provisioned             : 21474836480
    Qos                     : 
    Serial                  : B64D29B183714E0600012395
    Space                   : @{DataReduction=6.061869; Snapshots=844349; ThinProvisioning=0.5451926; TotalPhysical=853291; TotalProvisioned=21474836480; TotalReduction=13.32843; 
                            Unique=8942; Virtual=9766914560; SnapshotsEffective=278748160; TotalEffective=283435008; UniqueEffective=4686848}
    TimeRemaining           : 
    Pod                     : 
    Priority                : 0
    PromotionStatus         : promoted
    RequestedPromotionState : promoted
    Source                  : @{Id='cc8b751e-ec39-3f05-c485-f164f325451d'; Name='Windows1Vol1'}
    Subtype                 : regular
    VolumeGroup             : 
    ```

1. **Online the Volume:** Bring the disk volume back online.
    ```
    Get-Disk | Where-Object { $_.SerialNumber -eq $TargetDisk} | Set-Disk -IsOffline $False
    ```

1. **Restore Full Snapshot Backup :** Restore the database using the metadata-only backup file with the `NORECOVERY` option to allow subsequent log restores. This restore is instant regardless of the size of data and can be used in place of a full backup.

    ```
    $Query = "RESTORE DATABASE $DbName FROM DISK = '$BackupFile' WITH METADATA_ONLY, REPLACE, NORECOVERY" 
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $Query -Verbose
    ```

    Once the command completes, you should see output similar to this:
    
    ```
    VERBOSE: RESTORE DATABASE successfully processed 0 pages in 0.350 seconds (0.000 MB/sec).
    ```

1. **Verify Database State:** Let's check the current `Status` of the database...its RESTORING
    ```
    Get-DbaDbState -SqlInstance $SqlInstance -Database $DbName 

    Access       : MULTI_USER
    ComputerName : Windows1
    DatabaseName : TPCC100
    InstanceName : MSSQLSERVER
    RW           : READ_WRITE
    SqlInstance  : Windows1
    Status       : RESTORING
    ```

1. **Restore Log Backup:** Apply the transaction log backup to bring the database to the desired point in time. This is a regular native transaction log backup that we took earlier in the lab.

    ```
    Restore-DbaDatabase -SqlInstance $SqlInstance -Database $DbName -Path $LogBackup.BackupPath -NoRecovery -Continue
    ```

    Once the command completes, you should see output similar to this:

    ```
    ComputerName         : Windows1
    InstanceName         : MSSQLSERVER
    SqlInstance          : Windows1
    BackupFile           : \\Windows2\backup\TPCC100_202406180840.trn
    BackupFilesCount     : 1
    BackupSize           : 813.00 KB
    CompressedBackupSize : 241.68 KB
    Database             : TPCC100
    Owner                : WINDOWS1\Administrator
    DatabaseRestoreTime  : 00:00:01
    FileRestoreTime      : 00:00:01
    NoRecovery           : True
    RestoreComplete      : True
    RestoredFile         : tpcc100.mdf,tpcc100_log.ldf
    RestoredFilesCount   : 2
    Script               : {RESTORE LOG [TPCC100] FROM  DISK = N'\\Windows2\backup\TPCC100_202406180840.trn' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10}
    RestoreDirectory     : D:\SQL
    WithReplace          : True
    ```

# 6 - Recover the database and verify the data is restored

1. **Check Database State:** Confirm that the database state is 'RESTORING' before applying the log backup and 'ONLINE' after recovery.

    ```
    Get-DbaDbState -SqlInstance $SqlInstance -Database $DbName 
    ```

1. **Verify Data Integrity:** Ensure that critical data, such as tables, is present and correct in the restored database.
    ```
    Get-DbaDbTable -SqlInstance $SqlInstance -Database $DbName -Table 'Customer' | Format-Table
    ```

    ```
    ComputerName InstanceName SqlInstance Database Schema Name     IndexSpaceUsed DataSpaceUsed RowCount HasClusteredIndex IsFileTable IsMemoryOptimized IsPartitioned FullTextIndex 
    ------------ ------------ ----------- -------- ------ ----     -------------- ------------- -------- ----------------- ----------- ----------------- ------------- ------------- 
    Windows1     MSSQLSERVER  Windows1    TPCC100  dbo    customer          43744        654568   900000              True       False             False         False               

    ```

## Activity Summary

In this demo, you copied, nearly instantaneously, a 12GB database between two instances of SQL Server. This snapshot does not take up any additional space in the array since the shared blocks between the volumes will be data reduced. Any changed blocks are reported as Snapshot space in the FlashArray Web Interface Dashboard on the Array Capacity panel.

<br />
<br />

# Continue On To The Next Lab

Now move onto the next lab, [3-Seeding an Availability Group](../3-Seeding%20an%20Availability%20Group/README.md)

