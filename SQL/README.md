# Accelerate 2024 Workshop - SQL Server Innovations on Pure Storage

# About this Workshop

Welcome to this Microsoft Solutions workshop on Modern Storage Platforms for SQL Server. In this Workshop, you will learn how to make the most of a modern storage platform for SQL Server. You will learn storage fundamentals and how to leverage snapshots, enabling you to dramatically reduce the time it takes data to move between SQL Server instances.

This Workshop focuses on understanding where storage lives in your data platform and learning how to use modern storage techniques to reduce the overhead and complexity of managing data in your environment.

You'll start by logging into a virtual lab environment using your laptop, then work through a module covering leveraging snapshots to reduce the time it takes to copy, clone your databases, perform database restores, and build availability groups from the snapshots. 

# Learning Objectives

This Workshop aims to train data and storage professionals to use storage subsystems to manage data.

In this Workshop you'll learn:

- How to use snapshots to reduce the time it takes to move data between SQL Server instances
- How to use SQL Server 2022's T-SQL backup snapshots to perform point-in-time database restores
- How to use SQL Server 2022's T-SQL backup snapshots to build an availability group from a snapshot

The concepts and skills taught in this Workshop form the starting points for:

- Technical professionals tasked with managing data and databases
- Data professionals tasked with complete or partial responsibility for database management and availability

<br />
<br />

# Business Applications of this Workshop

Businesses require access to data. The techniques described in this Workshop enable data professionals to decouple the size of the databases from the operations needed to be performant. 


<br />
<br />

# Technologies used in this Workshop

The Workshop includes the following technologies, which form the basis of the Workshop. 


| Syntax      | Description |
| ----------- | ----------- |
| Microsoft Windows Operating System     | This Workshop uses the Microsoft Windows operating system |
| Microsoft SQL Server 2022      | In this Workshop, you will protect, copy, clone, and build high-availability databases on SQL Server |
| [Transact-SQL snapshot backup](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/create-a-transact-sql-snapshot-backup?view=sql-server-ver16)  | A new SQL Server 2022 feature that provides application consistent snapshots integrated directly into SQL Server
| Pure Storage FlashArray       | This Workshop uses a Pure Storage FlashArray as a block device as a storage subsystem for SQL Server |


<br />
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

In each of the modules, anywhere you see a - [ ], there is an activity you need to perform.

<br />
<br />

# Next Steps

Next, Continue to [1 - Volume Database Refresh](./1-Volume%20Database%20Refresh/Volume%20Database%20Refresh.ps1)