<#
.SYNOPSIS
Retrieve Summit office users from Active Directory.

.DESCRIPTION
Searches the `OU=summit-users,DC=home,DC=lab` container for AD user objects and
returns users whose `Office` property matches the provided value. Requires the
ActiveDirectory module and appropriate domain read permissions.

.PARAMETER Office
The Office name to filter users by (matches the `Office` AD attribute).

.EXAMPLE
Get-SummitOfficeUser -Office "Seattle"
Returns users in the Summit users OU whose Office equals "Seattle".

.NOTES
Module: Summit-Toolbox
#>
function Get-SummitOfficeUser {
    [CmdletBinding()]
    param (
        [string]$Office
    )

    Get-ADUser -Filter * -SearchBase "OU=summit-users,DC=home,DC=lab" -Properties Name,UserPrincipalName,Description,Office |
        Where-Object Office -eq $Office | Select-Object Name,UserPrincipalName,Description,Office

}