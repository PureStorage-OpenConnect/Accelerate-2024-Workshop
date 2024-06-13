# Install-Module PureStoragePowerShellSDK2
Import-Module PureStoragePowerShellSDK2



# Declare variables
$SqlServerName         = 'Windows1'                                       # Name of target VM
$ArrayName               = 'flasharray1.testdrive.local'                    # FlashArray FQDN



# Build a persistent SMO connection to use throughout this demo.
$SqlInstance = Connect-DbaInstance -SqlInstance $SqlServerName -TrustServerCertificate -NonPooledConnection



# Build a credential to connect to our FlashArry
$Passowrd = ConvertTo-SecureString 'testdrive1' -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ('pureuser', $Passowrd)



# Connect and create a variable for reference
$FlashArray = Connect-Pfa2Array -EndPoint $ArrayName -Credential $Credential -IgnoreCertificateError 



#######################################################################################################################################
###Demo 1 - Identify and address bottlenecks by pinpointing hot volumes using the FlashArray API
#######################################################################################################################################
# Kick off a backup to generate some read workload
Start-Job -ScriptBlock {
    Backup-DbaDatabase -SqlInstance $SqlInstance -Database 'TPCC100' -Type Full -FilePath NUL 
}


# Finding hot volumes in a FlashArray, examine the properties returned by the cmdlet
Get-Pfa2VolumePerformance -Array $FlashArray | Get-Member



# Using our sorting method from earlier, I'm going to look for something that's generating a lot of reads, 
# and limit the output to the top 10
# Get the Sort field from the API Documentation, the PowerShell object is camelcase, the array API response property has a different format
# ReadsPerSec is that PowerShell property, reads_per_sec is the array API response property. 
# Notice the underscores are removed from the PowerShell propery and the API response property is lower case and is case sensitive.
#. Sorting defaults to ascending, add a - to sort descending
Get-Pfa2VolumePerformance -Array $FlashArray -Sort 'reads_per_sec-' -Limit 10 -verbose | 
    Select-Object Name, Time, ReadsPerSec, BytesPerRead



# But what if I want to look for total IOPs, we'll I have to calculate that locally.
$VolumePerformance = Get-Pfa2VolumePerformance -Array $FlashArray
$VolumePerformance | 
    Select-Object Name, ReadsPerSec, WritesPerSec, @{label="IOsPerSec";expression={$_.ReadsPerSec + $_.WritesPerSec}} | 
    Sort-Object -Property IOsPerSec -Descending | 
    Select-Object -First 10



#######################################################################################################################################
#  Key take aways: 
#   1. You can easily find volume level performance information via PowerShell and also our API.
#   2. Continue to use the filtering, sorting and limiting techniques discussed.
#   3. Its not just Volumes, you can do this for other objects too, Hosts, HostGroups, Pods, Directories, and the Array as a whole
#######################################################################################################################################


#######################################################################################################################################
###Demo 2 - Categorize, search and manage your FlashArray resources efficiently
#######################################################################################################################################
# Group a set of volumes with tags and get and performance metrics based on those tags
# * https://support.purestorage.com/?title=FlashArray/PurityFA/PurityFA_General_Administration/Tags_in_Purity_6.0_-_User%27s_Guide
# * https://www.nocentino.com/posts/2023-01-25-using-flasharray-tags-powershell/ 

# Let's get two sets of volumes using our filtering technique
$VolumesSqlA = Get-Pfa2Volume -Array $FlashArray -Filter "name='*windows1*'" | 
    Select-Object Name -ExpandProperty Name

$VolumesSqlB = Get-Pfa2Volume -Array $FlashArray -Filter "name='*windows2*'" | 
    Select-Object Name -ExpandProperty Name



#Output those to veridy the data is what we want.
$VolumesSqlA 
$VolumesSqlB



# Now, let's define some parameters for our Tags, their keys, values and namespace.
# A namespace is like a folder, a way to classify a subset of tags. 
# A tag is a key/value pair that can be attached to an object in FlashArray, like a volume or a snapshot. 
# Using tags enables you to attach additional metadata to objects for classification, sorting, and searching.
$TagNamespace = 'YourNameNamespace'
$TagKey = 'SqlInstance'
$TagValueSqlA = 'Windows1'
$TagValueSqlB = 'Windows2'



#Assign the tags keys and values to the sets of volumes we're working with 
Set-Pfa2VolumeTagBatch -Array $FlashArray -TagNamespace $TagNamespace -ResourceNames $VolumesSqlA -TagKey $TagKey -TagValue $TagValueSqlA
Set-Pfa2VolumeTagBatch -Array $FlashArray -TagNamespace $TagNamespace -ResourceNames $VolumesSqlB -TagKey $TagKey -TagValue $TagValueSqlB



#Let's get all the volumes that have the Key = SqlInstance...or in other words all the volumes associated with SQL Servers in our environment
$SqlVolumes = Get-Pfa2VolumeTag -Array $FlashArray -Namespaces $TagNamespace -Filter "Key='SqlInstance'" -verbose
$SqlVolumes



# Now, let's perform an operation on each of the volumes that are in our set of volumes.
# We'll use Id since it can take an Array/List. 
# Name generally only takes a single value, some cmdlets take an Array/List for the Id. 
# So we'll use that parameter here to operate on the set of data in SqlVolumes.
$SqlVolumes.Resource.Id

Get-Pfa2VolumeSpace -Array $FlashArray -Id $SqlVolumes.Resource.Id -Sort "space.data_reduction" | 
    Select-Object Name -ExpandProperty Space | 
    Format-Table



# Similarly on performance cmdlets..remember this is still REST, let's look at the verbose output
Get-Pfa2VolumePerformance -Array $FlashArray -Id $SqlVolumes.Resource.Id -Verbose |
    Select-Object Name, BytesPerRead, BytesPerWrite, ReadBytesPerSec, ReadsPerSec, WriteBytesPerSec, WritesPerSec, UsecPerReadOp, UsecPerWriteOp | 
    Format-Table



# And when we're done, we can clean up our tags
Remove-Pfa2VolumeTag -Array $FlashArray -Namespaces $TagNamespace -Keys $TagKey -ResourceNames $VolumesSqlA
Remove-Pfa2VolumeTag -Array $FlashArray -Namespaces $TagNamespace -Keys $TagKey -ResourceNames $VolumesSqlB


#######################################################################################################################################
#  Key take aways: 
#   1. You can classify objects in the array to give your integrations more information about
#      what's in the object...things like volumes and snapshots and the applications and systems the objects are supporting
#   2. What can you do with tags? Execute operations on sets of data, volumes, snapshots, clones, accounting, performance monitoring
#######################################################################################################################################


#######################################################################################################################################
###Demo 4 - Streamline snapshot management with powerful API-driven techniques
#######################################################################################################################################
# * https://support.purestorage.com/Solutions/Microsoft_Platform_Guide/a_Windows_PowerShell/How-To%3A_Working_with_Snapshots_and_the_Powershell_SDK_v2#Volume_Snapshots_2

# Let's take a Volume Snapshot
$VolSnapshot = New-Pfa2VolumeSnapshot -Array $FlashArray -SourceNames 'Windows1Vol1' 
$VolSnapshot



# Let's take a look at VolumeSnapshot object model
$VolSnapshot | Get-Member



# Using a snapshot suffix, take a PG Snapshot with a suffix
$VolSnapshot = New-Pfa2VolumeSnapshot -Array $FlashArray -SourceNames 'Windows1Vol1' -Suffix "DWCheckpoint1"
$VolSnapshot



# Get a PG Snapshot by suffix
Get-Pfa2VolumeSnapshot -Array $FlashArray | Where-Object { $_.Suffix -eq 'DWCheckpoint1'}
Get-Pfa2VolumeSnapshot -Array $FlashArray -SourceNames 'Windows1Vol1' -Filter "suffix='DWCheckpoint1'" 



# Find snapshots that are older than a specific date, we need to put the date into a format the API understands
# In PowerShell 7 you can use Get-Date -AsUTC, In PowerShell 5.1 you can use (Get-Date).ToUniversalTime()
$Today = (Get-Date).ToUniversalTime()
$Created = $Today.AddDays(-30)
$StringDate = Get-Date -Date $Created -Format "yyy-MM-ddTHH:mm:ssZ"



# There's likely lots of snapshots, so let's use array side filtering to 
# limit the set of objects and find snapshots older than a month on our array
Get-Pfa2VolumeSnapshot -Array $FlashArray -Filter "created<'$StringDate'" -Sort "created" |
    Select-Object Name, Created




# Let's get a listing of PG snapshots older than 30 days    
$VolSnapshots = Get-Pfa2VolumeSnapshot -Array $FlashArray -Filter "created<'$StringDate'" -Sort "created"
$VolSnapshots.Id



# You can remove snapshots with these cmdlets, pushes them into the eradication bucket with a 24 hour timer
Remove-Pfa2VolumeSnapshot -Array $FlashArray -Id $VolSnapshots.Id 



# Let's get a listing of all snapshots, you'll see that snapshots older than 30 days are now "Destroyed" is now True and TimeRemaining is now set to a value.
Get-Pfa2VolumeSnapshot -Array $FlashArray  | Format-Table



#We can remove as snapshot, but this places it in the eradication bucket rather than deleting it straight away
Remove-Pfa2VolumeSnapshot -Array $FlashArray -Name 'Windows1Vol1.DWCheckpoint1' 



