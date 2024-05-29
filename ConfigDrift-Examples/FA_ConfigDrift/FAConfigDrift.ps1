##############################################################################################################################
# Simple Configuration drift example
# 
# Scenario: 
#    We wish to use the PureStoragePowershelSDKv2 in order to monitor simple configuration items on a FA fleet.
#
#
# Usage Notes:
#    Parameters are used to define the location of our configuration file, to set the mode to plan (which will show pending changes) or apply (which will apply the changes). 
#    Also an option parameter to simulate opening an incident ticke
#
# Example Calls:
#    ./FAConfigDrift.ps1 -mode "plan"
#    ./FAConfigDrift.ps1 -mode "apply" -openincident $true
#
# Other Notes:
#    Created by Cody Mautner in Pure Professional Services as an oversimplified version of configuration drift.  To account for all settings and to have an enterprise solution
#    much work will be needed to update this solution.  This serves as just an example of calling configuration items against the FA.
#
# Disclaimer:
#    This example script is provided AS-IS and meant to be a building block to be adapted to fit an individual 
#    organization's infrastructure.
##############################################################################################################################


PARAM(
[Parameter(Mandatory=$false, Position=0)]
[string] $configPath = ".\faarrayconfig.json",    #location of our configuration file
[Parameter(Mandatory=$false, Position=1)]
[ValidateSet("plan","apply")]
[string] $mode = "plan",                          #Plan will show pending changes, apply will implement the changes
[boolean] $openIncident = $false                  #Simulate opening an incident if a drift is detected.
)

Function Create-Drift{
#Function to build a custom PS object based on the information we pass in.  
    PARAM
    (
        [parameter(Mandatory = $true)]
        $FlashArray,
        [parameter(Mandatory = $true)]
        $settingName,
        [parameter(Mandatory = $true)]
        $currentSetting,
        [parameter(Mandatory = $true)]
        $newSetting
    )
    $drift = New-Object -TypeName psobject 
    $drift | Add-Member -MemberType NoteProperty -Name Array -Value $FlashArray.arrayname
    $drift | Add-Member -MemberType NoteProperty -Name settingName -Value $settingName
    $drift | Add-Member -MemberType NoteProperty -Name currentSetting -Value $currentSetting
    $drift | Add-Member -MemberType NoteProperty -Name newSetting -Value $newSetting
    return $drift
}

Function Set-FAconfig
#driving function to perform our checks and make changes if applicable/desired.
{
    PARAM
    (
        [parameter(Mandatory = $true)]
        $FlashArray,
        [parameter(Mandatory = $true)]
        $setting
    )
    try{
        $drift = ''
        switch($setting.Name)
        {
            "BannerPath"
            {
                $objArrayInfo = Get-pfa2array -Array $FlashArray
                $newBanner = get-content $setting.Value|Out-String

                #lets remove returns and EOL from our comparison.
                $currentBannerClean = $objArrayInfo.banner -replace "`n","" -replace "`r",""
                $newBannerClean = $newBanner  -replace "`n","" -replace "`r",""

                if($currentBannerClean -ne $newBannerClean){
                    Write-host "       The $($setting.Name) did change" -ForegroundColor yellow
                    $drift = Create-Drift -FlashArray $FlashArray -settingName $setting.Name -currentSetting $objArrayInfo.banner -newSetting $newBanner
                    if($mode -eq "apply"){
                        write-host "         Applying config for $($setting.Name) " -ForegroundColor magenta
                        Update-Pfa2Array -Array $objArray -Banner $newBanner -ErrorAction stop|Out-Null
                    }
                }
            }
            "GUIIdleTimeoutMinutes"
            {
                $objArrayInfo = Get-pfa2array -Array $FlashArray
                $timeoutInMS = [int]$setting.Value * 60000         #converting minute to milliseconds, we use milliseconds backend
                if($objArrayInfo.IdleTimeout -ne $timeoutInMS){
                    Write-host "       The GUI Idle Timeout did change" -ForegroundColor yellow
                    $drift = Create-Drift -FlashArray $FlashArray -settingName $setting.Name -currentSetting $objArrayInfo.IdleTimeout -newSetting $timeoutInMS
                    if($mode -eq "apply"){
                        write-host "         Applying config for $($setting.Name) " -ForegroundColor magenta
                        Update-Pfa2Array -Array $objArray -IdleTimeout $timeoutInMS -ErrorAction stop|Out-Null
                    }
                }
            }
            "NTPServersCommaDelmited"
            {
                
                $driftexists = 0
                $objArrayInfo = Get-pfa2array -Array $FlashArray
                $arrNewSettingNTP = $setting.Value.split(',')    #working with data types in Powershell can be tricky.  Here we must import values that are CSV, which turns to an array of strings
                $convertedtoStrArray = $objArrayInfo.NtpServers|ForEach-Object {$_.tostring()}   #in order to compare, we must change our powershell native object from the JSON import, into a string
                #We need to compare every item in each array of strings, to determine if a change has been made.
                foreach($item in $arrNewSettingNTP){
                    if($convertedtoStrArray -notcontains $item){
                        $driftexists = 1
                        }
                }
                foreach($item in $convertedtoStrArray){
                    if($arrNewSettingNTP -notcontains $item){
                        $driftexists = 1
                        }
                }
                if($driftexists){
                    Write-host "       The NTP Servers did change" -ForegroundColor yellow
                    $drift = Create-Drift -FlashArray $FlashArray -settingName $setting.Name -currentSetting $convertedtoStrArray -newSetting $arrNewSettingNTP
                    if($mode -eq "apply"){
                        write-host "         Applying config for $($setting.Name) " -ForegroundColor magenta
                        Update-Pfa2Array -Array $objArray -NtpServers $arrNewSettingNTP -ErrorAction stop|Out-Null
                    }
                }
            }
        }
    }
    catch{
        Write-Host "An error occurred while checking/changing setting $($setting.Name) on FlashArray $($FlashArray.arrayname) Error: $($_.Exception.Message)" -ForegroundColor Red
        #Call a function here to send an email letting appropriate teams know the job failed
        exit 1
    }
    if($drift){
        return $drift
    }
    else{
        return 0
    }

}

$drifts=@()
try{
    $JSONImport = get-content $configPath|convertfrom-json  #Bring out config in and make it a native powershell object
}
catch{
    Write-Host "An error occurred while importing our config file at $configPath.  Error: $($_.Exception.Message)" -ForegroundColor Red
    #Call a function here to send an email letting appropriate teams know the job failed
    exit 1
}
#we might as well extract our values out the import, since there are two distinct sections in our config
$arrays = $JSONImport.arrays
$sites = $JSONImport.sites

#Let the operator know what they set us onset to do
switch($mode){
    "Plan"{
        Write-host "Our job is running in $mode mode, meaning we will only report changes" -ForegroundColor green
    }
    "Apply"{
        Write-host "Our job is running in $mode mode, meaning we will make changes" -ForegroundColor green
    }
}

#We will sort through each array first for drifts
foreach($array in $arrays){
    Write-host "Connecting to array $($array.name) to check for configuration drift" -ForegroundColor Green
    $password = ConvertTo-SecureString $array.pass -AsPlainText -Force    #In this example we store the password as plain text, it is better to use an AES256 key or checkout from a secure vault in a production enviornment
    $Cred = New-Object System.Management.Automation.PSCredential ($array.username, $password)
    try{
        $objArray = connect-pfa2array -Endpoint $array.name -Credential $Cred -IgnoreCertificateError
    }
    catch{
        Write-Host "An error occurred while trying to connect to our array $($array.name).  Error: $($_.Exception.Message)" -ForegroundColor Red
        #Call a function here to send an email letting appropriate teams know the job failed
        exit 1
    }
    $siteConfig = $sites|?{$_.name -eq $array.Site}|Select-Object -ExpandProperty settings #Takes the site assigned to our array and extracts the appropraite config items
    Write-host "  Starting our checks to make sure array $($array.name) is configured for site code $($array.Site)" -ForegroundColor Green
    #Loops through those config items for our array, and perform our checks in the set-FAconfig function
    foreach($setting in $siteConfig){
        Write-host "     Checking $($setting.Name)" -ForegroundColor Green
        $result = Set-FAconfig -FlashArray $objArray -setting $setting
        if($result){
            $drifts += $result  #if there is a drift lets record it
        }
    }
}

#lets let the user know what has changed (if anything)
foreach($item in $drifts){
    write-host "We detected $($item.array) with setting $($item.settingName) is incorrectly set to $($item.currentSetting) instead of $($item.newSetting)" -ForegroundColor yellow
}

#If we are set to open an incident and there was a drift, lets open the incident
if($openIncident -and $drifts){
    write-host "We detected a change was made, because the openIncident flag was opened we will open a ticket" -ForegroundColor Green
    #Do API call to ticketing system here passing information, priority, and assignments
    $rndIncident = 'INC' + '{0:d5}' -f (get-random -Maximum 10000) #random for the sake of output
    write-host "    We have opened incident $rndIncident" -ForegroundColor yellow
}
