
# Exploring commands and parameters in PowerShell

# Identify the command to get user information from Active Directory
Get-ADUser

# Get detailed information about the command and its parameters
Update-Help

Get-Help Get-ADUser
Get-Help Get-ADUser -Examples
Get-Help Get-ADUser -Full

# Getting all users in Active Directory
Get-ADUser -Filter *

# Getting all users with a specific name
Get-ADUser -Filter "Name -eq 'Dale Cooper'"

Get-ADUser -Filter "Name -eq 'Dale Cooper'" | Select-Object *

# Getting all properties for a specific user
Get-ADUser -Filter "Name -eq 'Dale Cooper'" -Properties *

# Filtering and selecting specific properties
Get-ADUser -Filter * -SearchBase "OU=summit-users,DC=home,DC=lab" | Select-Object Name,SamAccountName,UserPrincipalName

# Grouping users by their office location and sorting by count
Get-ADUser -Filter * -Properties * | Group-Object Office | Sort-Object Count -Descending

# Filtering users based on office location and selecting specific properties
Get-ADUser -Filter "Office -eq 'Twin Peaks'" -Properties * | Select-Object Name,Office,Description,whenCreated,LastLogonDate | Format-Table

# Exporting the results to a CSV file
Get-ADUser -Filter "Office -eq 'Twin Peaks'" -Properties * | 
    Select-Object Name,Office,Description,whenCreated,LastLogonDate | Export-Csv -Path ".\ADUsers.csv" -NoTypeInformation

