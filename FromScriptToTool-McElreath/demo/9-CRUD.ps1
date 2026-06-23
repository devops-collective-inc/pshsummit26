
# (R)ead operations
Get-ADUser -Filter "Office -eq 'Twin Peaks'" -Properties * | 
    Select-Object Name,Office,Description,whenCreated,LastLogonDate | Format-Table

Get-ADUser -Identity "Dale.Cooper" -Properties * | 
    Select-Object Name,Office,Description,whenCreated,LastLogonDate


# (U)pdate operations
Set-ADUser -Identity "Dale.Cooper" `
    -Office "Seattle" `
    -Description "Moved to Seattle office"

Get-ADUser -Identity "Dale.Cooper" -Properties * | 
    Select-Object Name,Office,Description,whenCreated,LastLogonDate

# (C)reate operations
New-ADUser -Name "Pete Martell" `
    -GivenName "Pete" `
    -Surname "Martell" `
    -SamAccountName "Pete.Martell" `
    -Office "Twin Peaks" `
    -Description "Gone Fishin'" `
    -Path "OU=summit-users,DC=home,DC=lab"

Get-ADUser -Identity "Pete.Martell" -Properties * | Select-Object Name,Office,Description,whenCreated,LastLogonDate

# (D)elete operations
Remove-ADUser -Identity "Pete.Martell" 

Remove-ADUser -Identity "Pete.Martell" -Confirm:$false





## Reset user
# Set-ADUser -Identity "Dale.Cooper" -Office "Twin Peaks" -Description "Special Agent"