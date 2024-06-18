# Lab 2 - Point In Time Recovery - Using SQL Server 2022's T-SQL Snapshot Backup 

# Scenario
In this lab you will learn how to perform a point-in-time restore using SQL Server 2022's [TSQL Based Snapshot Backup](https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/create-a-transact-sql-snapshot-backup?view=sql-server-ver16) feature, leveraging a FlashArray snapshot as the base and restoring a log backup. This lab is on **Windows1**

Each section of line of code is intended to be executed sequentially to facilitate understanding, discovery and learning.

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
    Get-DbaDatabase -SqlInstance $SqlInstance -Database $DbName Select-Object Name, SizeMB
    ```

## 2 - Taking an application consistent backup with SQL Server 2022's T-SQL-based snapshot feature.

1. **Suspend Database for Snapshot:** Use the new SQL Server 2022 T-SQL to suspend the database to ensure an application-consistent snapshot, with no external tools. This code will freeze the database until we take the metadata backup below. Once you execute this code, the verbose output will report to you that the database is frozen.

    ```
    $Query = "ALTER DATABASE $DbName SET SUSPEND_FOR_SNAPSHOT_BACKUP = ON"
    Invoke-DbaQuery -SqlInstance $SqlInstance -Query $Query -Verbose
    ```

1. **Create Snapshot:** Take a snapshot of the Volume while the database is suspended.

    ```
    $Snapshot = New-Pfa2VolumeSnapshot -Array $FlashArray -SourceName $FlashArrayDbVol 
    ```

1. **Metadata Backup:** Perform a metadata-only backup of the database, which creates a small backup file in `\\Windows2\backup` describing the snapshot contents. Once complete, the database automatially unfreezes. 

    ```
    $BackupFile = "$BackupShare\$DbName$(Get-Date -Format FileDateTime).bkm"
    $Query = "BACKUP DATABASE $DbName 
            TO DISK='$BackupFile' 
            WITH METADATA_ONLY"
    Invoke-DbaQuery -SqlInstance $SqlInstance -Query $Query -Verbose
    ``

## 3 - Examine the backup history according to SQL Server, check the error log and the backup history

1. **Check Error Log:** Review the SQL Server error log to confirm that the snapshot backup was successful. You should see the string `BACKUP DATABASE successfully processed 0 pages in 0.009 seconds (0.000 MB/sec)...` indicating a successful backup

    ```
    Get-DbaErrorLog -SqlInstance $SqlInstance -LogNumber 0 | Format-Table
    ```

1. **Backup History:** Examine the backup history in MSDB to verify that the full backup (snapshot) and subsequent log backup are recorded.

    ```
    Get-DbaDbBackupHistory -SqlInstance $SqlInstance -Database $DbName -LastFull
    ```

1. **Log Backup:** Perform a transaction log backup to capture changes made after the snapshot.

    ```
    $LogBackup = Backup-DbaDatabase -SqlInstance $SqlInstance -Database $DbName -Type Log -Path $BackupShare -CompressBackup
    ```

1. **Backup History Revisited:**  Looking at the backup history we see the full backup (snapshot) and the log backup we just took

    ```
    Get-DbaDbBackupHistory -SqlInstance $SqlInstance -Database $DbName -Since (Get-Date).AddDays(-1)
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

1. **Verify Database State:** Let's check the current state of the database...its RESTORING
    ```
    Get-DbaDbState -SqlInstance $SqlInstance -Database $DbName 
    ```

1. **Restore Log Backup:** Apply the transaction log backup to bring the database to the desired point in time. This is a regular native transaction log backup that we took earlier in the lab.

    ```
    Restore-DbaDatabase -SqlInstance $SqlInstance -Database $DbName -Path $LogBackup.BackupPath -NoRecovery -Continue
    ```

# 6 - Recovery the database and verify the data is restored

1. **Check Database State:** Confirm that the database state is 'RESTORING' before applying the log backup and 'ONLINE' after recovery.

    ```
    Get-DbaDbState -SqlInstance $SqlInstance -Database $DbName 
    ```

1. **Verify Data Integrity:** Ensure that critical data, such as tables, is present and correct in the restored database.
    ```
    Get-DbaDbTable -SqlInstance $SqlInstance -Database $DbName -Table 'Customer' | Format-Table
    ```

## Activity Summary

In this demo, you copied, nearly instantaneously, a 12GB database between two instances of SQL Server. This snapshot does not take up any additional space in the array since the shared blocks between the volumes will be data reduced. Any changed blocks are reported as Snapshot space in the FlashArray Web Interface Dashboard on the Array Capacity panel.

<br />
<br />

# Continue On To The Next Lab

Now move onto the next lab, [3-Seeding an Availability Group](../3-Seeding%20an%20Availability%20Group/README.md)

