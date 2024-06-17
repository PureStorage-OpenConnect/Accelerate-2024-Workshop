# Lab 2 - Point In Time Recovery - Using SQL Server 2022's T-SQL Snapshot Backup feature 

# Scenario
In this lab you will learn how to perform a point-in-time restore using SQL Server 2022's T-SQL Snapshot Backup feature, leveraging a FlashArray snapshot as the base and restoring a log backup. 

Each section of line of code is intended to be executed sequentially to facilitate understanding, discovery and learning.

Here is a description of the major activities in this lab:

## Environment Setup 

1. **Define Variables:** Set up variables for the target SQL Server, FlashArray name, database name, backup location, FlashArray volume name, and target disk serial number.
1. **Set Credentials:** Create credentials for connecting to the FlashArray.
1. **Connect to FlashArray:** Establish a connection to the FlashArray's REST API.
1. **SQL Server Connection:** Build a persistent SMO connection to the SQL Server instance (Windows1).
1. **Database Information:** Retrieve and display the size of the target database (TPCC100).

## Snapshot Backup

1. **Suspend Database for Snapshot:** Use T-SQL to suspend the database to ensure an application-consistent snapshot.
1. **Create Snapshot:** Take a snapshot of the Volume while the database is suspended.
1. **Metadata Backup:** Perform a metadata-only backup of the database, which creates a small backup file describing the snapshot contents.

## Backup Validation

1. **Check Error Log:** Review the SQL Server error log to confirm that the snapshot backup was successful.
1. **Backup History:** Examine the backup history in MSDB to verify that the full backup (snapshot) and subsequent log backup are recorded.
1. **Log Backup:** Perform a transaction log backup to capture changes made after the snapshot.

## Point-in-Time Restore:

1. **Offline the Database:** Take the database offline, which is necessary for a full restore.
1. **Offline the Volume:** Offline the disk volume containing the database files.
1. **Restore Snapshot:** Overwrite the existing volume with the snapshot taken earlier.
1. **Online the Volume:** Bring the disk volume back online.
1. **Restore Database:** Restore the database using the metadata-only backup file with the NORECOVERY option to allow subsequent log restores.
1. **Restore Log Backup:** Apply the transaction log backup to bring the database to the desired point in time.
1. **Recover Database:** Bring the database back online using the RECOVERY option.

# Validation

1. **Check Database State:** Confirm that the database state is 'RESTORING' before applying the log backup and 'ONLINE' after recovery.
1. **Verify Data Integrity:** Ensure that critical data, such as tables, is present and correct in the restored database.

## Activity Summary

In this demo, you copied, nearly instantaneously, a 12GB database between two instances of SQL Server. This snapshot does not take up any additional space in the array since the shared blocks between the volumes will be data reduced. Any changed blocks are reported as Snapshot space in the FlashArray Web Interface Dashboard on the Array Capacity panel.

<br />
<br />

# Continue On To The Next Lab

Now move onto the next lab, [3-Seeding an Availability Group](../3-Seeding%20an%20Availability%20Group/README.md)

