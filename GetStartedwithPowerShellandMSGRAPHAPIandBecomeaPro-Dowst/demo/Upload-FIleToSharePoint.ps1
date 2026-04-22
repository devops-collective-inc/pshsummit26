# 1) Auth
# Acquire a Graph token up front and populate the shared Authorization header.
$authHeader = New-GraphAuthHeaderFromCertificate -AppId $AppId -TenantId $TenantId -CertificateSubject 'CN=MyCert'

# 2) Find site
# Start at the tenant root site so the script can discover the site and drive ids dynamically.
$siteUri = "https://graph.microsoft.com/v1.0/sites/root"
$site = Invoke-RestMethod -Uri $siteUri -Method Get -Headers $authHeader
$siteId = $site.id

# 3) Find document library (drive)
# List the site's drives and pick the library named Documents.
$drivesUri = "https://graph.microsoft.com/v1.0/sites/$siteId/drives?$select=id,name,webUrl"
$drives = Invoke-RestMethod -Uri $drivesUri -Method Get -Headers $authHeader
$driveId = ($drives.value | Where-Object { $_.name -eq 'Documents' }).id

# 4) Upload file
# Point to the local source file and the destination path inside the library.
$localFile = ".\Q2-Budget.xlsx"
$targetPath = "Shared Documents/Reports/Q2-Budget.xlsx"

# Encode each path segment (keeps slashes)
# Graph expects URL-safe path segments, but the folder separators still need to remain as '/'.
$encodedPath = ($targetPath -split '/') | ForEach-Object { [uri]::EscapeDataString($_) } | Join-String -Separator '/'

# The :/content suffix tells Graph to create or overwrite the file contents in one request.
$uploadUri = "https://graph.microsoft.com/v1.0/sites/$siteId/drives/$driveId/root:/$($encodedPath):/content"

$InvokeRestMethodParam = @{
	Method      = 'Put'
	Uri         = $uploadUri
	Headers     = $authHeader
	ContentType = "application/octet-stream"
	InFile      = $localFile
}
# Upload the file bytes directly from disk using the request splat above.
Invoke-RestMethod @InvokeRestMethodParam
