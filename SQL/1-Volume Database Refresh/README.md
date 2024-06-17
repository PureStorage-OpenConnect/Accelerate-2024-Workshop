# Lab 1 - Volume Database Refresh

## Introduction.

In this lab, you will clone a volume from **Windows1** to **Windows2** in this activity. You will replace the contents of the volume on the target instance, **Windows2**, with the contents of the clone from **Windows1** which contains the `TPCC100` database. This replaces the need to back up and restore the database. 

Since this operation is inside the array, it happens nearly instantaneously. Another benefit is when you clone a volume and present it to another host, the volume does not consume additional space until data starts changing. When data does start changing, the changed blocks are tracked and exposed as a performance metric on the FlashArray Web Interface Dashboard and Array Capacity panel.

Each section of line of code is intended to be executed sequentially to facilitate understanding, discovery and learning.


Here is a description of the major activities in this lab:

## Environment Setup:

In this section of code you are defining key parameters and variables for reuse throughout the script.

1. **Define variables:** for source and target SQL servers, FlashArray FQDN, target disk serial number, source volume name, and target volume name. 
1. **Set credentials** for connecting to FlashArray.
1. **SQL Server Connection:** Build a persistent SMO connection to the SQL Server instance.
1. **Create Remoting Session**: Create a PowerShell Remoting session to the target server (Windows2).
1. **Database Information:** Retrieve and display the size of database to be cloned (TPCC100)
## Volume Cloning Process:

In this section of code you are cloning a volume and presenting it to a second Windows server and attaching the database.

1. Offline the target volume on Windows2.
1. Connect to the FlashArray's REST API.
1. Clone the volume from Windows1 to Windows2 using FlashArray.
1. Online the volume on Windows2.
1. Attach the cloned database to the SQL Server on Windows2.
1. Verify the cloned database on the target SQL instance (Windows2).

## Activity Summary

In this demo, you copied, nearly instantaneously, a 12GB database between two instances of SQL Server. This snapshot does not take up any additional space in the array since the shared blocks between the volumes will be data reduced. Any changed blocks are reported as Snapshot space in the FlashArray Web Interface Dashboard on the Array Capacity panel.

<br />
<br />

# Continue On To The Next Lab

Now move onto the next lab, [2-Point in Time Recovery](../2-Point%20in%20Time%20Recovery/README.md)

