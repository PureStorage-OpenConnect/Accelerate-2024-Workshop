# Lab 2 - Point In Time Recovery - Using SQL Server 2022's T-SQL Snapshot Backup feature 

# Scenario
In this activity, you will build an Availability Group from Snapshot leveraging FlashArray snapshots and the new [TSQL Based Snapshot Backup](https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/create-a-transact-sql-snapshot-backup?view=sql-server-ver16) functionality in SQL Server 2022.

If you’ve been using Availability Groups, you’re familiar with the process of replica seeding (sometimes called initializing, preparing, or data synchronization). Seeding is a size of data operation, copying data from a primary replica to one or more secondary replicas. This is required before joining a database to an Availability Group. You can seed a replica with backup and restore, or with automatic seeding, each of which present their own challenges. Regardless of which method you use, the seeding operation can take an extended amount of time. The time it takes to seed a replica is based on the database's size, network, and storage speed. If you have multiple replicas, then seeding all of them is N times the fun!

But what if we told you that you could seed your Availability Group replicas from a storage-based snapshot and that the reseeding process can be nearly instantaneous?

In addition to saving you time, this process saves your database systems from the CPU, network, and disk consumption that comes with using either automatic seeding or backups and restores to seed. 

So let’s do it...we’re going to snapshot a database on **Windows1**, clone that snapshot to the second instance of SQL Server on **Windows2**, and seed an Availability Group replica from that. 

An overview of the process
* [Prepare the secondary replica](#prepare-the-secondary-replica)
* [Take a snapshot backup of TPCC100 on Windows1](#take-a-snapshot-backup-of-tpcc100-on-windows1)
* [Restore the snapshot backup to Windows2](#restore-the-snapshot-backup-to-windows2)
* [Complete the Availability Group Initialization Process](#complete-the-availability-group-initilization-process)
* [Create the Availability Group](#create-the-availability-group)
* [Check the state of the Availability Group Replication](#check-the-state-of-the-availability-group-replication)

Here is a description of the major activities in this lab:


## Environment Setup

1. Define variables for primary and secondary SQL servers, AG name, database name, backup location, FlashArray details, and volume names.
1. Establish PowerShell remoting sessions to the secondary replica and build SMO connections to both SQL Server instances.
1. Set credentials for FlashArray and connect to it.

## Snapshot Backup on Primary Replica

1. Suspend the primary database for a snapshot backup.
1. Take a snapshot of the primary database volume and replicate it.
1. Perform a metadata-only backup of the database, which will unfreeze the database.

## Prepare Secondary Replica

1. Offline the database and volumes on the secondary replica.
1. Overwrite the secondary volumes with the snapshot from the primary.
1. Bring the volumes back online and restore the database with the NORECOVERY option, leaving it in RESTORING mode.
1. Take a log backup on the primary and restore it on the secondary to ensure data consistency.

## Create the Availability Group

1. Create and distribute certificates for authentication between replicas.
1. Set permissions for the AG.
1. Use the `New-DbaAvailabilityGroup` cmdlet to create the AG with the specified parameters, including manual failover and seeding mode.

## Validation

Check the status of the AG to ensure that the synchronization state is **"Synchronized"**.


## Activity Summary and Wrapping Things Up
In this activity, you initialized an availability group using TSQL-based snapshots inside SQL Server with array-based snapshots in FlashArray, nearly instantaneously. Traditional availability group initialization or reseeding requires a size of data operation via either backup and restore or direct seeding. 

There's one nuance I want to call out here in this activity. This all happened on one array in our test lab. You will likely want your availability group replicas on separate arrays in a production environment. If you want to dive into the details of that, check out the post in the More Resources section below.

Futher, if you want to deep dive into many more SQL Server use-cases on FlashArray Check out our team's script reposistory at [Pure Storage OpenConnect SQL Server Scripts](https://github.com/PureStorage-OpenConnect/sqlserver-scripts/)

<br />
<br />

# More Resources
- [Seeding an Availability Group Replica from Snapshot](https://www.nocentino.com/posts/2022-05-26-seed-ag-replica-from-snapshot/)
- [Pure Storage OpenConnect SQL Server Scripts](https://github.com/PureStorage-OpenConnect/sqlserver-scripts/)

