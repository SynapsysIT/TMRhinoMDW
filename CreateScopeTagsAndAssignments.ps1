[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
    $CSVPath, 
    $AdminRoleDefinitionName = "GLB - UEM - Role - EntityAdmins",
    $HelpDeskRoleDefinitionName = "GLB - UEM - Role - HelpDeskOperators",
    $ReadOnlyRoleDefinitionName = "GLB - UEM - Role - ReadOnlyOperators",
    $AppRoleDefinitionName = "GLB - UEM - Role - ScopeTagApp",
    $ServiceAccountID = "xxxxxxx",
    $Delimiter = ";"
)

function CreateRoleAssignment {
    param (
        $DefinitionName,
        $RoleAssignmentName,
        $ScopeGroups,
        $Members,
        $ScopeTag
    )
    process {
        Write-host ("[{0}] Creating role assignement $DefinitionName" -f $MyInvocation.MyCommand);

        $roleDefinition = Get-IntuneRoleDefinition -Filter "displayname eq '$DefinitionName'";

        $roleAssignment = Get-IntuneRoleAssignment -Filter "displayname eq '$RoleAssignmentName'";
        if ($null -eq $roleAssignment) {
            Write-Host "Creating role assignement $RoleAssignmentName based on role definition $DefinitionName";
            if (-not $WhatIfPreference) {
                New-UEMIntuneRoleAssignment -roleDefinitionID $roleDefinition.ID -Name $RoleAssignmentName -Members $members -ResourceScopes $ScopeGroups -RoleScopeTagID $ScopeTag | Out-Null;
            }
        }
        else {
            Write-Host "Role assignement $RoleAssignmentName based on role defition $DefinitionName already exists";
        }
    }
}

if (-not (Test-Path $CSVPath)) {
    throw "CSV file not found";
}

Import-Module UEM.Intune;

$countries = Import-Csv -Delimiter $Delimiter -LiteralPath $CSVPath -ErrorAction Stop;
#$serviceAccount = Get-AzureADUser -SearchString $serviceAccountName;

$countries | ForEach-Object {
    $country = $_;
    $bu = $country.BusinessUnit;
    $countryCode = $country.countryCode;
    Write-Host "================================================================================================";
    
    $domain = "CE";
    if ($countryCode -eq "NA") {
        $domain = "NA";
    }

    #Get corresponding groups
    $devicesGroupName = "SG.AZ.$countryCode.$bu-UEM-Devices";
    $entityAdminGroupName = "SG.$domain.$countryCode.$bu-UEM-EntityAdmins";
    $userGroupName = "SG.$domain.$countryCode.$bu-UEM-Users";
    $keyuserGroupName = "SG.$domain.$countryCode.$bu-UEM-KeyUsers";
    $DevicesGroupsGroupName = "SG.$domain.$countryCode.$bu-UEM-DevicesGroups";
    $UsersGroupsGroupName = "SG.$domain.$countryCode.$bu-UEM-UsersGroups";
    $helpDeskGroupName = "SG.$domain.$countryCode.$bu-UEM-HelpDeskOperators";
    $readOnlyGroupName = "SG.$domain.$countryCode.$bu-UEM-ReadOnlyOperators";
    $roleScopeTagName = "$countryCode - $bu - UEM - RoleScopeTag";
    $AdminRoleAssignmentDisplayName = "$countryCode - $bu - RoleAssignment - SchoolAdministrator - EntityAdmins";
    $AppRoleAssignmentDisplayName = "$countryCode - $bu - RoleAssignment - ScopeTagApp - EntityAdmins";
    $HelpDeskAssignmentDisplayName = "$countryCode - $bu - RoleAssignment - HelpDeskOperators";
    $ReadOnlyAssignmentDisplayName = "$countryCode - $bu - RoleAssignment - ReadOnlyOperators";
    
    $devicesGroup = Get-AzureADGroup -Filter "DisplayName eq '$devicesGroupName'" -ErrorAction Stop;
    if ($null -eq $devicesGroup) {
        throw "$devicesGroupName not found";
    }

    $entityAdminGroup = Get-AzureADGroup -Filter "DisplayName eq '$entityAdminGroupName'" -ErrorAction Stop;
    if ($null -eq $entityAdminGroup) {
        throw "$entityAdminGroupName not found";
    }
    
    $userGroup = Get-AzureADGroup -Filter "DisplayName eq '$userGroupName'"  -ErrorAction Stop;
    if ($null -eq $userGroup) {
        throw "$userGroupName not found";
    }

    $keyUserGroup = Get-AzureADGroup -Filter "DisplayName eq '$keyuserGroupName'" -ErrorAction Stop;
    if ($null -eq $keyUserGroup) {
        throw "$keyuserGroupName not found";
    }

    $usersGroupsGroup = Get-AzureADGroup -Filter "DisplayName eq '$UsersGroupsGroupName'" -ErrorAction Stop;
    if ($null -eq $usersGroupsGroup) {
        throw "$UsersGroupsGroupName not found";
    }

    $devicesGroupsGroup = Get-AzureADGroup -Filter "DisplayName eq '$DevicesGroupsGroupName'" -ErrorAction Stop;
    if ($null -eq $devicesGroupsGroup) {
        throw "$DevicesGroupsGroupName not found";
    }

    $helpDeskGroup = Get-AzureADGroup -Filter "DisplayName eq '$helpDeskGroupName'" -ErrorAction Stop;
    if ($null -eq $helpDeskGroup) {
        throw "$helpDeskGroupName not found";
    }

    $readOnlyGroup = Get-AzureADGroup -Filter "DisplayName eq '$readOnlyGroupName'" -ErrorAction Stop;
    if ($null -eq $readOnlyGroup) {
        throw "$readOnlyGroupName not found";
    }

    # Begin scope tag creation
    $roleScopeTag = Get-UEMIntuneRoleScopeTag -RoleScopeTagName $roleScopeTagName;
    if ($null -eq $roleScopeTag) {
        Write-Host "Creating role scope tag $roleScopeTagName";
        if (-not $WhatIfPreference) {
            $roleScopeTag = New-UEMIntuneRoleScopeTag -RoleScopeTagName $roleScopeTagName;
        }
    }
    else {
        Write-Host "Role scope tag $roleScopeTagName already exists";
    }

    Write-Host "Setting role scope tag $roleScopeTagName on $($devicesGroup.displayname)";
    if (-not $WhatIfPreference) {
        Set-UEMIntuneRoleScopeTag -RoleScopeTagID $roleScopeTag.id -GroupID $devicesGroup.ObjectId | Out-Null;
    }
    # End scope tag creation


    
    # Begin role assignement creation
    #$AdminScopes = @($devicesGroup.ObjectId, $entityAdminGroup.ObjectId, $userGroup.ObjectId, $keyUserGroup.ObjectId);
    $AdminScopes = @($devicesGroup.ObjectId, $entityAdminGroup.ObjectId, $userGroup.ObjectId, $keyUserGroup.ObjectId, $usersGroupsGroup.objectid, $devicesGroupsGroup.objectid);
    $AppScopes = @($userGroup.ObjectId, $keyUserGroup.ObjectId);

    $adminMembers = @($entityAdminGroup.ObjectId);
    $helpDeskMembers = @($helpDeskGroup.ObjectId);
    $readOnlyMembers = @($readOnlyGroup.ObjectId);

    CreateRoleAssignment -DefinitionName $AdminRoleDefinitionName -RoleAssignmentName $AdminRoleAssignmentDisplayName -Members $adminMembers -ScopeGroups $AdminScopes -ScopeTag $roleScopeTag.id;
    CreateRoleAssignment -DefinitionName $AppRoleDefinitionName -RoleAssignmentName $AppRoleAssignmentDisplayName -Members $adminMembers -ScopeGroups $AppScopes -ScopeTag 0;
    CreateRoleAssignment -DefinitionName $HelpDeskRoleDefinitionName -RoleAssignmentName $HelpDeskAssignmentDisplayName -Members $helpDeskMembers -ScopeGroups $AdminScopes -ScopeTag $roleScopeTag.id;
    CreateRoleAssignment -DefinitionName $ReadOnlyRoleDefinitionName -RoleAssignmentName $ReadOnlyAssignmentDisplayName -Members $readOnlyMembers -ScopeGroups $AdminScopes -ScopeTag $roleScopeTag.id;

    # End role assignement creation

    # Begin group owner setting
    $baseDevicesGroupName = "SG.AZ.$countryCode.$bu-UEM";
    $groupsToSetOwner = Get-AzureADGroup -filter "startswith(Displayname,'$baseDevicesGroupName-W10') or startswith(Displayname, '$baseDevicesGroupName-iOS') or startswith(Displayname, '$baseDevicesGroupName-Android')" -all $true;
    $groupsToSetOwner | ForEach-Object {
        $currentGroup = $_;
        $owner = Get-AzureADGroupOwner -ObjectId $currentGroup.ObjectId | Where-Object { $_.ObjectId -eq $ServiceAccountID }
        if ($null -eq $owner) {
            Write-Host "Adding UEM service account as ownner of $($currentGroup.displayname)";
            if (-not $WhatIfPreference) {
                Add-AzureADGroupOwner -RefObjectId $ServiceAccountID -ObjectId $currentGroup.objectid;
            }
        }
        else {
            Write-Host "UEM service account already ownner of $($currentGroup.displayname)";
        }
    }
    # End group owner setting
}
