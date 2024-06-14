##############################################################################################################################
# Simple Configuration drift example
# 
# Scenario: 
#    We wish to use the API Directly in order to monitor simple configuration items on a FB fleet.
#
#
# Usage Notes:
#    Parameters are used to define the location of our configuration file, to set the mode to plan (which will show pending changes) or apply (which will apply the changes). 
#    Also an option parameter to simulate opening an incident ticke
#
# Example Calls:
#    C:\Workshop\FB_Configdrift\FBConfigDrift.ps1 -mode "plan"
#    C:\Workshop\FB_Configdrift\FBConfigDrift.ps1 -mode "apply" -openincident $true
#
# Other Notes:
#    Created by Cody Mautner in Pure Professional Services as an oversimplified version of configuration drift.  To account for all settings and to have an enterprise solution
#    much work will be needed to update this solution.  This serves as just an example of calling configuration items against the FB.
#
# Disclaimer:
#    This example script is provided AS-IS and meant to be a building block to be adapted to fit an individual 
#    organization's infrastructure.
##############################################################################################################################


PARAM(
[Parameter(Mandatory=$false, Position=0)]
[string] $configPath = ".\fbarrayconfig.json",    #location of our configuration file
[Parameter(Mandatory=$false, Position=1)]
[ValidateSet("plan","apply")]
[string] $mode = "plan",                          #Plan will show pending changes, apply will implement the changes
[boolean] $openIncident = $false                  #Simulate opening an incident if a drift is detected.
)

#This is added to handle PowerShell5 TSL settings.  We must do this when hitting the API directly from PS5
Add-Type -TypeDefinition '
  using System;
  using System.Net;
  using System.Net.Security;
  using System.Security.Cryptography.X509Certificates;
  public class ServerCertificateValidationCallback {
    public static void Ignore() {
      if (ServicePointManager.ServerCertificateValidationCallback == null) {
        ServicePointManager.ServerCertificateValidationCallback +=
          delegate (
            Object obj,
            X509Certificate certificate,
            X509Chain chain,
            SslPolicyErrors errors
          ) {
            return true;
          };
      }
    }
  }
  '
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[ServerCertificateValidationCallback]::Ignore()




Function Create-Drift{
#Function to build a custom PS object based on the information we pass in.  
    PARAM
    (
        [parameter(Mandatory = $true)]
        $FlashBlade,
        [parameter(Mandatory = $true)]
        $settingName,
        [parameter(Mandatory = $true)]
        $currentSetting,
        [parameter(Mandatory = $true)]
        $newSetting
    )
    $drift = New-Object -TypeName psobject 
    $drift | Add-Member -MemberType NoteProperty -Name flashblade -Value $FlashBlade
    $drift | Add-Member -MemberType NoteProperty -Name settingName -Value $settingName
    $drift | Add-Member -MemberType NoteProperty -Name currentSetting -Value $currentSetting
    $drift | Add-Member -MemberType NoteProperty -Name newSetting -Value $newSetting
    return $drift
}

Function Set-FBconfig
#driving function to perform our checks and make changes if applicable/desired.
{
    PARAM
    (
        [parameter(Mandatory = $true)]
        $FlashBlade,
        [parameter(Mandatory = $true)]
        $AuthHeader,
        [parameter(Mandatory = $true)]
        $setting
    )
    try{
        $drift = ''
        switch($setting.Name)
        {
            "BannerPath"
            {
                $currentBanner = Invoke-restmethod  -Method get -Uri "https://$flashblade/api/login-banner"  -Headers $AuthHeader|select -ExpandProperty login_banner
                $newBanner = get-content $setting.Value|Out-String

                #lets remove returns and EOL from our comparison.
                $currentBannerClean = $currentBanner -replace "`n","" -replace "`r",""
                $newBannerClean = $newBanner  -replace "`n","" -replace "`r",""

                if($currentBannerClean -ne $newBannerClean){
                    Write-host "       The $($setting.Name) did change" -ForegroundColor yellow
                    $drift = Create-Drift -FlashBlade $FlashBlade -settingName $setting.Name -currentSetting $currentBanner -newSetting $newBanner
                    if($mode -eq "apply"){
                        write-host "         Applying config for $($setting.Name) " -ForegroundColor magenta
                        $Body = [ordered]@{
                            banner = $newBanner
                        } | ConvertTo-Json
                        Invoke-restmethod  -Method patch -Uri "https://$flashblade/api/2.12/arrays" -body $Body -Headers $AuthHeader|out-null
                     
                    }
                }
            }
            "GUIIdleTimeoutMinutes"
            {
                $currenttimeout =   Invoke-restmethod  -Method get -Uri "https://$flashblade/api/2.12/arrays"  -Headers $AuthHeader|select -ExpandProperty items|select -ExpandProperty idle_timeout
              
                $timeoutInMS = [int]$setting.Value * 60000         #converting minute to milliseconds, we use milliseconds backend
                if($currenttimeout -ne $timeoutInMS){
                    Write-host "       The GUI Idle Timeout did change" -ForegroundColor yellow
                    $drift = Create-Drift -FlashBlade $FlashBlade -settingName $setting.Name -currentSetting $currenttimeout -newSetting $timeoutInMS
                    if($mode -eq "apply"){
                        write-host "         Applying config for $($setting.Name) " -ForegroundColor magenta
                        $Body = [ordered]@{
                            idle_timeout = $timeoutInMS
                        } | ConvertTo-Json
                        Invoke-restmethod  -Method patch -Uri "https://$flashblade/api/2.12/arrays" -body $Body -Headers $AuthHeader|out-null
                    }
                }
            }
            "NTPServersCommaDelmited"
            {
                
                $driftexists = 0
                $currentNTPServers =   Invoke-restmethod  -Method get -Uri "https://$flashblade/api/2.12/arrays"  -Headers $AuthHeader|select -ExpandProperty items|select -ExpandProperty ntp_servers

                $arrNewSettingNTP = $setting.Value.split(',')    #working with data types in Powershell can be tricky.  Here we must import values that are CSV, which turns to an array of strings
                #We need to compare every item in each array of stringfs, to determine if a change has been made.
                foreach($item in $arrNewSettingNTP){
                    if($currentNTPServers -notcontains $item){
                        $driftexists = 1
                        }
                }
                foreach($item in $currentNTPServers){
                    if($arrNewSettingNTP -notcontains $item){
                        $driftexists = 1
                        }
                }
                if($driftexists){
                    Write-host "       The NTP Servers did change" -ForegroundColor yellow
                    $drift = Create-Drift -FlashBlade $FlashBlade -settingName $setting.Name -currentSetting $currentNTPServers -newSetting $arrNewSettingNTP
                    if($mode -eq "apply"){
                        write-host "         Applying config for $($setting.Name) " -ForegroundColor magenta
                        $Body = [ordered]@{
                            ntp_servers= @($arrNewSettingNTP)
                        } | ConvertTo-Json
                        Invoke-restmethod  -Method patch -Uri "https://$flashblade/api/2.12/arrays" -body $Body -Headers $AuthHeader|out-null
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
$FlashBlades = $JSONImport.FlashBlades
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
foreach($fb in $FlashBlades){
    Write-host "Connecting to array $($fb.name) to check for configuration drift" -ForegroundColor Green
    try{
        $headers = @{
            "api-token" = $fb.APIToken
         }
        $session = Invoke-WebRequest  -Method Post -Uri "https://$($fb.name)/api/login" -Headers $headers  #webrequest allows me to extract header, vs using Powershell session management
        $xAuthToken = $session.headers.'x-auth-token'
        $AuthHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $AuthHeader.Add("X-Auth-Token", "$xAuthToken")
    }
    catch{
        Write-Host "An error occurred while trying to connect to our array $($array.name).  Error: $($_.Exception.Message)" -ForegroundColor Red
        #Call a function here to send an email letting appropriate teams know the job failed
        exit 1
    }
    $siteConfig = $sites|?{$_.name -eq $fb.Site}|Select-Object -ExpandProperty settings #Takes the site assigned to our array and extracts the appropraite config items
    Write-host "  Starting our checks to make sure array $($fb.name) is configured for site code $($fb.Site)" -ForegroundColor Green
    #Loops through those config items for our array, and perform our checks in the set-FAconfig function
    foreach($setting in $siteConfig){
        Write-host "     Checking $($setting.Name)" -ForegroundColor Green
        $result = Set-Fbconfig -flashblade $fb.name -authHeader $authHeader -setting $setting
        if($result){
            $drifts += $result  #if there is a drift lets record it
        }
    }
}

#lets let the user know what has changed (if anything)
foreach($item in $drifts){
    write-host "We detected $($item.flashblade) with setting $($item.settingName) is incorrectly set to $($item.currentSetting) instead of $($item.newSetting)" -ForegroundColor yellow
}

#If we are set to open an incident and there was a drift, lets open the incident
if($openIncident -and $drifts){
    write-host "We detected a change was made, because the openIncident flag was opened we will open a ticket" -ForegroundColor Green
    #Do API call to ticketing system here passing information, priority, and assignments
    $rndIncident = 'INC' + '{0:d5}' -f (get-random -Maximum 10000) #random for the sake of output
    write-host "    We have opened incident $rndIncident" -ForegroundColor yellow
}
