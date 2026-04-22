# Build the Authorization header once and reuse it for every Graph request below.
$authHeader = New-GraphAuthHeaderFromCertificate -AppId $AppId -TenantId $TenantId -CertificateSubject 'CN=MyCert'

# Example 1: list users in the tenant and project only the most readable properties.
# Remember calls that return multiple items will be nested under a 'value' property in the response.
$users = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users" -Headers $authHeader -Method Get -ContentType "application/json"
$users.value | Select-Object -Property displayName, userPrincipalName
$users.value[0]


# Example 2: resolve the root SharePoint site for the tenant.
$uri = "https://graph.microsoft.com/v1.0/sites/root"
$site = Invoke-RestMethod -Uri $uri -Headers $authHeader -Method Get -ContentType "application/json"
$site

# Example 3: list document libraries (drives) in that site so you can inspect their ids and names.
$uri = "https://graph.microsoft.com/v1.0/sites/{0}/drives?select=weburl,system,id,name,driveType" -f $site.id
$folders = Invoke-RestMethod -Uri $uri -Headers $authHeader -Method Get -ContentType "application/json"
$folders.value

# Example 4: query one specific library by id to return its files.
$uri = "https://graph.microsoft.com/v1.0/sites/{0}/drives/{1}" -f $site.id, $folders.value[2].id
$files = Invoke-RestMethod -Uri $uri -Headers $authHeader -Method Get -ContentType "application/json"
$files.value

# Show how many child objects came back in the last response.
$files.value.Count

# Example 5: build a JSON payload that can be sent to a PATCH/POST style request.
# In this case we'll update the display name of the first user returned in Example 1, but you can modify the body and URI to target any other endpoint and supported properties.
$body = @{
    "displayName" = "Adele Vance"
} | ConvertTo-Json
$uri = "https://graph.microsoft.com/v1.0/users/{0}" -f $users.Value[0].id
$userUpdate = $null

# Submit the update request for the first returned user and inspect the raw response.
$userUpdate = Invoke-WebRequest -Uri $uri -Headers $authHeader -Method Post -Body $body -ContentType "application/json"
$userUpdate 

# Example 6: download the contents of a file from OneDrive or SharePoint by path.
Invoke-WebRequest -Uri 'https://graph.microsoft.com/v1.0/me/drive/root:/FolderA/FileB.txt:/content' -Headers $authHeader -Method Get -ContentType "text/plain"

