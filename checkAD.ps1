<#
.SYNOPSIS
    Name: checkAD.ps1
    A tool to search Active Directory for user information.

.DESCRIPTION
    Using this script, you will be able to search Active Directory for information on a user or group.

.PARAMETER Type
    The Active Directory object to search. Can be either "group" or "user". Default: "User".
    TODO: Add group search

.PARAMETER Value
    The group or user name to search in Active Directory

.PARAMETER Domain
    The domain to search in Active Directory. Leave blank to allow the script to identify available domains.

.PARAMETER Copy
    Switch to copy the output directly to clipboard.

.PARAMETER Groups
    Switch to get group memebership list of the user.

.NOTES
    Release Date: 2021-05-12

    Author: Hnav3

.EXAMPLE
    Run checkAD.ps1 to get information on a user.
    checkAD.ps1 -type user -value Hnav3
    checkAD.ps1 -value Hnav3
    checkAD.ps1 Hnav3
    checkAD.ps1 Hnav3@example.com

.EXAMPLE
    Run checkAD.ps1 to list members of a group.
    checkAD.ps1 -type group -value Developers-Group
    This isn't done yet.
#>

[CmdletBinding()]
PARAM(
    [parameter(mandatory=$true)]
    [string]$Search,
    [string]$Type = "User",
    [string]$Domain,
    [switch]$Copy=$false,
    [switch]$Groups=$false
)

Function Get-DomainList{
    $objForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest() #Get the currect AD forest.
    $Domains = @($objForest.Domains) | foreach {$_.name} #Iterate through forest and add domains to domain object.

    #Sometimes not all domains are found. Uncomment below to add domains manually.
    #$Domains = $Domains + "ad1.example.com" + "ad2.example.com"

    #Write domain list to console and prompt user for domain to search.
    Write-Host "Please choose a domain to search:"
    For($i=0; $i -lt $Domains.Count; $i++) {
        Write-Host "$($i+1): $($Domains[$i])"
    }

    [int]$number = Read-Host "Press the number to select a domain:"

    $searchDomain = $($Domains[$number-1])

    return $searchDomain
}

Function Search-ADUser($Search, $Domain){
    #Change this setting if you do not want to grab all LDAP properties.
    #https://activedirectorypro.com/ad-ldap-field-mapping/
    $propertylist = @("*")

    if($Search -like '*@*') {  #Check if email address or username was given and set appropriate ldap field mapping.
        $field = "Mail"
    }
    else{
        $field = "sAMAccountName"
    }

    Write-Host "...Searching for $search in $domain"

    $User = Get-ADUser -Server $Domain -LDAPFilter "($field=$Search)" -properties * | Format-list -property $propertylist | Out-string

    return $user
}

Function Get-GroupMembership($search, $domain){
    Write-Host "...Getting group membership for $Search in $Domain."

    try {
        $Groups = Get-ADPrincipalGroupMembership -Server $Domain $Search | Format-table -Property name,GroupCategory - autosize | Out-string
    }
    catch{
        $Groups = "Error finding $Search's group membership in $Domain."
    }

    return $groups
}

#----------------------------[ Main Function ]---------------------------------------------

Import-Module ActiveDirectory

if($Domain -eq ''){$domain=Get-DomainList}
if($Type -eq 'user'){
    if($Groups -eq $true){
        $Groupmembership=Get-GroupMembership $Search $Domain
        Write-host $Groupmembership
    }
    else{
        $userinfo=Search-ADUser $Search $Domain
        if($userinfo -eq ''){write-warning "$Search not found in Active Directory"}
        else{write-host $userinfo}
    }
}
