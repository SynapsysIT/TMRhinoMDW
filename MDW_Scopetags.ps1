# Input bindings are passed in via param block.
param($Timer)

write-host "This is a WELCOME MESSAGE"

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"



$pwd = $env:PASS
$useraddress = $env:USER

import-module azuread -usewindowspowershell
import-module azureadpreview -usewindowspowershell
import-module microsoft.graph.intune -usewindowspowershell

$password = ConvertTo-SecureString $pwd –asplaintext –force
$cred = New-Object System.Management.Automation.PSCredential("$useraddress", $password);

Connect-AzureAD -TenantID "de55da9f-7c4c-44c6-8cbe-af4d0a0bfec0" -credential $cred 

connect-msgraph -credential $cred

write-host "Connexion is all ok"

$devicesids = Get-IntuneManagedDevice -Top 1000 | select -ExpandProperty azureaddeviceid

#for each device
foreach ($id in $devicesids) {

#get the device's Azure Object id 
$objectidsofdevice = Get-AzureADDevice | where-object deviceid -EQ $id | select -ExpandProperty objectid

#get the user who enrolled the device (just the username)
$username = Get-IntuneManagedDevice | where-object azureaddeviceid -EQ $id | select -ExpandProperty userprincipalname
$user = $username.Replace('@synapsystest.onmicrosoft.com','')

#get device OS
$os = Get-IntuneManagedDevice | where-object azureaddeviceid -EQ $id | select -ExpandProperty operatingsystem



#check OS and add the device to the right group
switch ($os) {
    "Android" {
        $azureadgroupid = Get-AzureADGroup -SearchString "AZ-GRP-DEVICE-Android-$user" | select -ExpandProperty objectid
        $members = Get-AzureADGroupMember -ObjectId $azureadgroupid | select -ExpandProperty deviceid
        if ($members -notcontains $id) {
        write-host "The Device $id has been added to AZ-GRP-DEVICE-Android-$user"
        Add-AzureADGroupMember -ObjectId $azureadgroupid -RefObjectId $objectidsofdevice }
        else {
        write-host "The Device $id is already member of AZ-GRP-DEVICE-Android-$user"
        }

    }

    "Windows" {

        $azureadgroupid = Get-AzureADGroup -SearchString "AZ-GRP-DEVICE-W10-$user" | select -ExpandProperty objectid
        $members = Get-AzureADGroupMember -ObjectId $azureadgroupid | select -ExpandProperty deviceid
        if ($members -notcontains $id) {
        Add-AzureADGroupMember -ObjectId $azureadgroupid -RefObjectId $objectidsofdevice 
        write-host "The Device $id has been added to AZ-GRP-DEVICE-W10-$user"
}
        else {
        write-host "The Device $id is already member of AZ-GRP-DEVICE-W10-$user"
        }

    }


    "iOS" {

        $azureadgroupid = Get-AzureADGroup -SearchString "AZ-GRP-DEVICE-IOS-$user" | select -ExpandProperty objectid
        $members = Get-AzureADGroupMember -ObjectId $azureadgroupid | select -ExpandProperty deviceid
        if ($members -notcontains $id) {
        Add-AzureADGroupMember -ObjectId $azureadgroupid -RefObjectId $objectidsofdevice 
        write-host "The Device $id has been added to AZ-GRP-DEVICE-Android-$user"
}
        else {
        write-host "The Device $id is already member of AZ-GRP-DEVICE-Android-$user"
        }

    }


}

}