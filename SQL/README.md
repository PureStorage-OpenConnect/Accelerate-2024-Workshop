# Accelerate 2024 Workshop - SQL Server Innovations on Pure Storage

![Accelerate 2024 - SQL Server Innovations on Pure Storage](/img/sql.png)

# About this Workshop

Welcome to this Microsoft Solutions workshop on Modern Storage Platforms for SQL Server. In this Workshop, you will learn how to make the most of a modern storage platform for SQL Server. You will learn storage fundamentals and how to leverage snapshots, enabling you to dramatically reduce the time it takes data to move between SQL Server instances.

This Workshop focuses on understanding where storage lives in your data platform and learning how to use modern storage techniques to reduce the overhead and complexity of managing data in your environment.

You'll start by logging into a virtual lab environment using your laptop, then work through a module covering leveraging snapshots to reduce the time it takes to copy, clone your databases, perform database restores, and build availability groups from the snapshots. 

<br />

# Learning Objectives

This Workshop aims to train data and storage professionals to use storage subsystems to manage data.

In this Workshop you'll learn:

- How to use snapshots to reduce the time it takes to move data between SQL Server instances
- Differentiate between crash-consistent and application consistent snapshots
- How to use SQL Server 2022's T-SQL backup snapshots to perform point-in-time database restores
- How to use SQL Server 2022's T-SQL backup snapshots to build an availability group from a snapshot

The concepts and skills taught in this Workshop form the starting points for:

- Technical professionals tasked with managing data and databases
- Data professionals tasked with complete or partial responsibility for database management and availability

<br />

# Business Applications of this Workshop

Businesses require access to data. The techniques described in this Workshop enable data professionals to decouple the size of the databases from the operations needed to be performant and accelerating business outcomes. 

<br />

# Technologies used in this Workshop

The Workshop includes the following technologies, which form the basis of the Workshop. 

| Syntax      | Description |
| ----------- | ----------- |
| Microsoft Windows Operating System     | This Workshop uses the Microsoft Windows operating system |
| [Microsoft SQL Server 2022](https://www.microsoft.com/en-us/sql-server/sql-server-2022)      | In this Workshop, you will protect, copy, clone, and build high-availability databases on SQL Server |
| [Transact-SQL snapshot backup](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/create-a-transact-sql-snapshot-backup?view=sql-server-ver16)  | A new SQL Server 2022 feature that provides application consistent snapshots integrated directly into SQL Server
| [Pure Storage FlashArray](https://www.purestorage.com/products.html)       | This Workshop uses a Pure Storage FlashArray as a block device as a storage subsystem for SQL Server |

<br />

## Crash Consistent and Application Consistent Snapshots

This workshop uses both *crash-consistent* and *application-consistent* snapshots. A crash-consistent snapshot means the application is unaware that a snapshot of its volumes has been taken. On a Pure Storage FlashArray, a clone of the volume supporting the database will always give you back a recoverable database. When using crash-consistent snapshots, the recovery point is the snapshot. You cannot roll the database forward or backwards with log backup, This is called a point in time restore.

To perform a point-in-time restore using snapshots, you must use an application-consistent snapshot, which allows you to use a snapshot as a base for point-in-time recovery. In other words, you can then restore log backups into a database restored from an application consistent snapshot. In this lab, you will use a crash-consistent snapshot. In the remaining labs in this workshop, you will use SQL Server 2022's [TSQL Based Snapshot Backup](https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/create-a-transact-sql-snapshot-backup?view=sql-server-ver16) to perform application-consistent snapshots.

In our first lab [1 - Volume Database Refresh](./1-Volume%20Database%20Refresh/README.md), you will use a crash-consistent snapshot; in the other labs, you will use application-consistent snapshots.


# Lab Layout

In this lab, you have two Windows Servers, each with SQL Server 2022 installed. Each server has one 20GB volume attached via iSCSI from FlashArray1. This volume is presented to the operating system as `Disk 1` and is mounted as the Drive `D:\`. These are used in all activities in these labs.

| Resource      | FlashArray Volume Name | Windows Disk Number | Windows Drive Letter
| -----------   |  ----  |  :----: |  :----:  |
| Windows1      | Windows1Vol1 | 1           | D:\          |
| Windows2      | Windows2Vol1 | 1           | D:\          |

<br />

# Before Taking this Workshop

You'll need a local system with a modern web browser; Chrome is preferred. In a browser-based lab environment, you will access Windows-based virtual machines running SQL Server.

This Workshop expects you to understand the following:
* SQL Server relational database fundamentals - for example, databases are made of data and log files that are stored on disks
* Basic TCP/IP networking - for example, you know what an IP address is

<br />
<br />

# Workshop Modules


| Module Description |  Topics Covered | Duration
| ----------- | ----------- | ----------- | 
| [1 - Volume Database Refresh](./1-Volume%20Database%20Refresh/README.md) | Refresh a database on the target server (Windows2) from a source database on a separate server (Windows1) | 20 mins |
| [2 - Point in Time Recovery ](./2-Point%20in%20Time%20Recovery/README.md) | Perform a point-in-time restore using SQL Server 2022's T-SQL Snapshot Backup feature. This uses a FlashArray snapshot as the base of the restore and then restores a log backup. | 30 mins | 
| [3 - Seeding an Availability Group](./2-Point%20in%20Time%20Recovery/README.md) | Seeding an Availability Group (AG) from SQL Server 2022's T-SQL Snapshot Backup | 45 mins

<br />
<br />

# Continue On To The Next Lab

Next, Continue to [1 - Volume Database Refresh](./1-Volume%20Database%20Refresh/README.md)