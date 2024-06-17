# Accelerate 2024 Workshop - SQL Server Innovations on Pure Storage

# About this Workshop

Welcome to this Microsoft solutions workshop on Modern Storage Platforms for SQL Server. In this workshop you will learn how to make the most of a modern storage platform for SQL Server. You will learn storage fundamentals and how to leverage snapshots enabling you to dramatically reduce the time it takes data to move between SQL Server instances.

The focus of this workshop is to understand where storage lives in your data platform and learn how to use modern storage techniques to reduce the overhead and complexity of managing data in your enviroment.

You'll start by logging into a virtual lab enviroment using your own laptop, then work through a module covering leveraging snapshots to reduce time it takes to copying, cloning your databases, performing database restores, and building availability groups from snapshot. 

# Learning Objectives

The goal of this workshop is to train data and storage professionals on how to use storage subsystems to manage data.

In this workshop you'll learn:

- How to use snapshots to reduce the time it takes to move data between SQL Server instances
- How to use SQL Server 2022's T-SQL backup snapshots to perform point in time database restores
- How to use SQL Server 2022's T-SQL backup snapshots to build an availability group from snapshot

The concepts and skills taught in this workshop form the starting points for:

- Technical professionals tasked with managing data and databases
- Data professionals tasked with complete or partial responsibility for database management and availability

<br />
<br />

# Business Applications of this Workshop

Businesses require access to data. The techniques described in this workshop enable data professionals the ability to decouple the size of the databases from the operations needed to be performant. 


<br />
<br />

# Technologies used in this Workshop

The workshop includes the following technologies which form the basis of the workshop. At the end of the workshop you will learn how to extrapolate these components into other solutions, solutions which are not solely limited to the technologies used in the lab. You will cover these at an overview level, with references to much deeper training provided.


| Syntax      | Description |
| ----------- | ----------- |
| Microsoft Windows Operating System	 | This workshop uses the Microsoft Windows operating system |
| Microsoft SQL Server 2022      | In this workshop you will protect, copy, clone and build high availability databases on SQL Server |
| [Transact-SQL snapshot backup](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/create-a-transact-sql-snapshot-backup?view=sql-server-ver16)  | A new SQL Server 2022 feature that provides application consistent snapshots integrated directly into SQL Server
| Pure Storage FlashArray	    | This workshop uses a Pure Storage FlashArray as a block device as a storage subsystem for SQL Server |


<br />
<br />

# Before Taking this Workshop

You'll need a local system with a modern web browser, Chrome is preferred. You will access Windows based virtual machines running SQL Server in a browser based lab enviroment.

This workshop expects that you understand:
* SQL Server relational database fundamentals - for example, that databases are made of data and log files that are stored on disks
* Basic TCP/IP networking - for example, you know what an IP address is

<br />
<br />

# Workshop Modules


| Module Description |  Topics Covered | Duration
| ----------- | ----------- | ----------- | 
| [1 - Volume Database Refresh](./1-Volume%20Database%20Refresh/README.md) | Refresh a database on the target server (Windows2) from a source database on a separate server (Windows1) | 20 mins |
| [2 - Point in Time Recovery ](./2-Point%20in%20Time%20Recovery/README.md) | Perform a point in time restore using SQL Server 2022's T-SQL Snapshot Backup feature. This uses a FlashArray snapshot as the base of the restore, then restores a log backup. | 30 mins | 
| [3 - Seeding an Availability Group](./2-Point%20in%20Time%20Recovery/README.md) | Seeding an Availability Group (AG) from SQL Server 2022's T-SQL Snapshot Backup | 45 mins

In each of the modules, anywhere you see a - [ ], there is an activity you need to perform.

<br />
<br />

# Next Steps

Next, Continue to [1 - Volume Database Refresh](./1-Volume%20Database%20Refresh/Volume%20Database%20Refresh.ps1)