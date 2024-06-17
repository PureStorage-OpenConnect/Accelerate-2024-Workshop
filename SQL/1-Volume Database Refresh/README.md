# Lab 1 - Volume Database Refresh

In this lab, you will learn how to use array-based volume snapshots to decouple the time it takes to perform DBA operations from the size of the data. You will clone a database on Windows1 and present it to a another instance SQL Server instance on Windows2

Here is a description of the major activities in this lab:

## Environment Setup:

In this section of code you are defining key parameters and variables for reuse throughout the script.

1. Define variables for source and target SQL servers, FlashArray FQDN, target disk serial number, source volume name, and target volume name. 
1. Set credentials for connecting to FlashArray.
1. Establish persistent SMO connections to the source and target SQL instances.
1. Create a PowerShell session to the target server (Windows2).
1. Check the size of the database to be cloned (TPCC100).

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

# Next Steps

Now move onto the next lab, [2-Point in Time Recovery](../2-Point%20in%20Time%20Recovery/README.md)

