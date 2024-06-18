# Lab 1 - Volume Database Refresh

## Introduction

In this lab, you will clone a volume from **Windows1** to **Windows2** in this activity. You will replace the contents of the volume on the target instance, **Windows2**, with the contents of the clone from **Windows1** which contains the `TPCC100` database. This replaces the need to back up and restore the database. 

Since this operation is inside the array, it happens nearly instantaneously. Another benefit is when you clone a volume and present it to another host, the volume does not consume additional space until data starts changing. When data does start changing, the changed blocks are tracked and exposed as a performance metric on the FlashArray Web Interface Dashboard and Array Capacity panel.

> Each section of line of code below is intended to be executed sequentially to facilitate understanding, discovery and learning.

Here is a description of the major activities in this lab:

## 1 - Setting up the enviroment

In this section of code you are defining key parameters and variables for reuse throughout the script.

1. **Define variables:** for source and target SQL servers, FlashArray FQDN, target disk serial number, source volume name, and target volume name. 

    ```
    $SourceSqlServer         = 'Windows1'                                       # Name of source VM
    $TargetSqlServer         = 'Windows2'                                       # Name of target VM
    $ArrayName               = 'flasharray1.testdrive.local'                    # FlashArray FQDN
    $TargetDiskSerialNumber  = 'B64D29B183714E0600012396'                       # Target Disk Serial Number
    $SourceVolumeName        = 'Windows1Vol1'                                   # Source volume name on FlashArray
    $TargetVolumeName        = 'Windows2Vol1'                                   # Target volume name on FlashArray
    ```

1. **Set credentials** for connecting to FlashArray. Set credential to connect to FlashArray, username `pureuser`, password `testdrive`

    ```
    $Password = ConvertTo-SecureString 'testdrive1' -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ('pureuser', $Password)
    ```

1. **SQL Server Connection:** Build a persistent SMO connection to the SQL Server instance.

    ```
    $SourceSqlInstance = Connect-DbaInstance -SqlInstance $SourceSqlServer -TrustServerCertificate -NonPooledConnection
    $TargetSqlInstance = Connect-DbaInstance -SqlInstance $TargetSQLServer -TrustServerCertificate -NonPooledConnection
    ```

1. **Create Remoting Session**: Create a PowerShell Remoting session to the target server (Windows2).

    ```
    $TargetSession = New-PSSession -ComputerName $TargetSqlServer
    ```

1. **Database Information:** Retrieve and display the size of database to be cloned (TPCC100). Let's check out the size of the database we're going to clone, 12GB...the cloning operation is instant, regardless of databases size, 12KB or 12TB will take just as long.

    ```
    Get-DbaDatabase -SqlInstance $SourceSqlInstance -Database 'TPCC100' |
    Select-Object Name, SizeMB
    ```

## 2 - Cloning a Database Using Volume Snapshots

In this section of code you are cloning a volume and presenting it to a second Windows server and attaching the database.

1. Offline the volume on Windows2, this is the volume that will be updated

    ```
    Invoke-Command -Session $TargetSession -ScriptBlock { Get-Disk | Where-Object { $_.SerialNumber -eq $using:TargetDiskSerialNumber } | Set-Disk -IsOffline $True }
    ```
1. Connect to the FlashArray's REST API.
    ```
    $FlashArray = Connect-Pfa2Array -EndPoint $ArrayName -Credential $Credential -IgnoreCertificateError
    ```
1. Perform the volume clone operation, cloning the contents of the volume attached to Windows1 to Windows2 
    ```
    New-Pfa2Volume -Array $FlashArray -Name $TargetVolumeName -SourceName $SourceVolumeName  -Overwrite $true 
    ```
1. Online the volume on Windows2.
    ```
    Invoke-Command -Session $TargetSession -ScriptBlock { Get-Disk | ? { $_.SerialNumber -eq $using:TargetDiskSerialNumber } | Set-Disk -IsOffline $False }
    ```
1. Attach the cloned database to the SQL Server on Windows2.
    ```
    $Query = "CREATE DATABASE [TPCC100] ON ( FILENAME = N'D:\SQL\tpcc100.mdf' ), ( FILENAME = N'D:\SQL\tpcc100_log.ldf' ) FOR ATTACH"
    Invoke-DbaQuery -SqlInstance $TargetSqlInstance -Database master -Query $Query 
    ```
1. Verify the cloned database on the target SQL instance (Windows2). We cloned the database instantly between two instances of SQL Server
    ```
    Get-DbaDatabase -SqlInstance $TargetSqlInstance -Database 'TPCC100' |
    Select-Object Name, SizeMB
    ```

## Activity Summary

In this demo, you copied, nearly instantaneously, a 12GB database between two instances of SQL Server. This snapshot does not take up any additional space in the array since the shared blocks between the volumes will be data reduced. Any changed blocks are reported as Snapshot space in the FlashArray Web Interface Dashboard on the Array Capacity panel.

<br />
<br />

# Continue On To The Next Lab

Now move onto the next lab, [2-Point in Time Recovery](../2-Point%20in%20Time%20Recovery/README.md)

