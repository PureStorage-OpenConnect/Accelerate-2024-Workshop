### Workshop Guide: Using the FAConfigDrift.ps1 Script



Welcome to the workshop on using the `FAConfigDrift.ps1` script! This script focuses around FlashArray configuration drive management using the PureStoragePowershellSDKv2.

This guide will walk you through understanding the configuration file, adding additional arrays, modifying the banner property, and changing other properties. By the end of this workshop, you will have a solid understanding of how to use this script to manage configuration drift in your Pure Storage FlashArray environment.

We even have a few challenges for you to enhance the solution further.


#### 1. Understanding the Configuration File



The configuration file (`faarrayconfig.json`) is a JSON file that holds the configuration settings for your FlashArrays and sites. Here's a breakdown of its structure:



```json

{
    "arrays": [
        {
            "name": "flasharray1",
            "UserName": "workshop",
            "Pass": "SOMEPASSWORD",
            "Site": "FASiteA"
        }
    ],
    "sites": [
        {
            "name": "FASiteA",
            "settings": [
                {
                    "Name": "BannerPath",
                    "Value": ".\\banners\\standardbanner.txt"
                },
                {
                    "Name": "GUIIdleTimeoutMinutes",
                    "Value": "30"
                },
                {
                    "Name": "NTPServersCommaDelmited",
                    "Value": "time1.purestorage.com,time2.purestorage.com,time3.purestorage.com"
                }
            ]
        },
        {
            "name": "FASiteB",
            "settings": [
                {
                    "Name": "BannerPath",
                    "Value": ".\\banners\\standardBanner.txt"
                },
                {
                    "Name": "GUIIdleTimeout",
                    "Value": "25"
                },
                {
                    "Name": "NTPServersCommaDelmited",
                    "Value": "SiteB1.purestorage.com,SiteB2.purestorage.com,SiteB3.purestorage.com"
                }
            ]
        }
    ]
}

```



- **Arrays Section:** This section lists all the FlashArrays. Each array has a name, username, password, and associated site.

- **Sites Section:** This section lists all the sites and their settings. Each site has a name and a list of settings. Each setting has a name and a value.



#### 2. Adding Additional Arrays



To add an additional array to the configuration, follow these steps:



1. **Identify the new array details** (name, username, password, site).

2. **Add the new array to the arrays section** of the JSON file.



For example, if you want to add a new array named `flasharray2`, your updated `arrays` section would look like this:



```json

"arrays": [
    {
        "name": "flasharray1",
        "UserName": "workshop",
        "Pass": "SOMEPASSWORD",
        "Site": "FASiteA"
    },
    {
        "name": "flasharray2",
        "UserName": "admin",
        "Pass": "SOMEPASSWORD",
        "Site": "FASiteB"
    }
]

```



#### 3. Modifying the Banner Property



To modify the banner property, you need to update the `BannerPath` value in the `sites` section.



1. **Identify the site you want to modify**.

2. **Update the `BannerPath` value** to point to the new banner file.



For example, to change the banner for `FASiteA` to a new file named `newbanner.txt`, update the `BannerPath` setting:



```json

"settings": [
    {
        "Name": "BannerPath",
        "Value": ".\\banners\\newbanner.txt"
    },
    {
        "Name": "GUIIdleTimeoutMinutes",
        "Value": "30"
    },
    {
        "Name": "NTPServersCommaDelmited",
        "Value": "time1.purestorage.com,time2.purestorage.com,time3.purestorage.com"
    }
]

```



#### 4. Changing Other Properties



Let's walk through changing some other properties like `GUIIdleTimeoutMinutes` and `NTPServersCommaDelmited`.



##### Changing `GUIIdleTimeoutMinutes`



1. **Locate the site** in the JSON file.

2. **Update the `GUIIdleTimeoutMinutes` value**.



For example, to change the `GUIIdleTimeoutMinutes` for `FASiteA` to 45 minutes:



```json

"settings": [
    {
        "Name": "GUIIdleTimeoutMinutes",
        "Value": "45"
    }
]

```



##### Changing `NTPServersCommaDelmited`



1. **Locate the site** in the JSON file.  This is a comma separated field

2. **Update the `NTPServersCommaDelmited` value**.



For example, to change the NTP servers for `FASiteA`:



```json

"settings": [
    {
        "Name": "NTPServersCommaDelmited",
        "Value": "time4.purestorage.com,time5.purestorage.com,time6.purestorage.com"
    }
]

```



#### 5. Running the Script



You can run the script in two modes: `plan` and `apply`.



- **Plan Mode:** This mode will show pending changes without applying them.

- **Apply Mode:** This mode will apply the changes.



Example command to run in plan mode:

```sh

./FAConfigDrift.ps1 -mode "plan"

```



Example command to run in apply mode and open an incident if a drift is detected:

```sh

./FAConfigDrift.ps1 -mode "apply" -openincident $true

```

#### Things to observe in the solution

- We are operating with the input in this example of stored Hash tables in the config file.  This gives us a key value/pair type format for storing and replaying the data.

  - The benefit of this design, is it allows for ease of adding additional configuration, with minimal changes to the script.  We should only need to modify the `Set-FAconfig` and our JSON file to add new checks, which is the goal of this simple workshop.

  - The downside to this approach is, things such as SNMP server, SMTP mail, etc sometimes have multiple values needed.  It is recommended, in this format, to make those fields comma delimited to hold multiple properties.

- NTPServersCommaDelmited shows an example of how to import CSV format, adjust property types for valid comparison, and comparing two arrays of strings. It is interesting for this type of field, because we want to compare all the various properties, regardless of the order.  This comparison example will not care about order of the defined elements in the config vs the array.

#### Challenge

Add a new property to our JSON file and a check to add into `Set-FAconfig`   

##### Simple Examples
-  Enable/Disable SMI-S using `Get-Pfa2SmiS` and `Update-Pfa2SmiS`

##### Harder Examples
-  Alert Watcher List using `Get-Pfa2AlertWatcher` and `Update-Pfa2AlertWatcher`
-  SMTP Configuration using `Get-Pfa2SmtpServer` and `Update-Pfa2SmtpServer`

#### Conclusion

In this workshop, you've learned how to understand and modify the configuration file for the `FAConfigDrift.ps1` script. You've seen how to add additional arrays, change the banner property, and modify other settings. You've also learned how to run the script in different modes. 

If you have taken the challenges, you have learned how to add a new property and add additional checks to this script

Feel free to experiment with the configuration and script to get more comfortable with its functionality.

