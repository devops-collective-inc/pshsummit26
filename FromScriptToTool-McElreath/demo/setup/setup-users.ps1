# setup-users.ps1
# Create test users in OU=summit-users

Import-Module ActiveDirectory

$ou = "OU=summit-users,DC=home,DC=lab"
$domain = "home.lab"
$passwordPlain = (New-Guid).Guid
$securePassword = ConvertTo-SecureString $passwordPlain -AsPlainText -Force

$firstNames = @("Avery","Bailey","Camden","Delaney","Emerson","Finley","Gray","Harper","Indigo","Jules")
$lastNames  = @("Ashby","Bright","Clarke","Dawson","Ellis","Foster","Grady","Holloway","Iverson","Jenkins")

for ($i = 0; $i -lt 10; $i++) {
    $first = $firstNames[$i]
    $last  = $lastNames[$i]
    $sam   = "$first.$last".ToLower()
    $upn   = "$sam@$domain"
    $display = "$first $last"

    New-ADUser -Name $display `
      -GivenName $first `
      -Surname $last `
      -SamAccountName $sam `
      -UserPrincipalName $upn `
      -DisplayName $display `
      -Path $ou `
      -AccountPassword $securePassword `
      -Enabled $true `
      -ChangePasswordAtLogon $false

    Write-Host "Created: $display ($upn)"
}

Write-Host "Done creating users in $ou"
