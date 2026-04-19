# Get Started with PowerShell and MS GRAPH API and Become a Pro

**Speaker**: Matthew Dowst

## Overview

This guide will delve deeply into PowerShell and native GRAPH API. We will start from the beginning, providing detailed guidance on getting started. We'll then move on to the authentication process, explaining how it works clearly and understandably. We will also share queries experts frequently use, offering practical insights into their functionalities and benefits. Lastly, we'll provide real-life examples that give you a clear understanding of how these tools operate in a real-world context. This comprehensive guide aims to transform you into a pro-PowerShell and GRAPH API user.

---

# Demo Scripts

This folder contains helper functions and sample scripts for Microsoft Graph automation with PowerShell, including app registration setup, certificate-based auth, Graph REST calls, and SharePoint file upload.

## Scripts At A Glance

- Get-GraphURI.ps1
  - Function: Get-GraphURI
  - Purpose: Maps friendly names (for example AllGraphUsers) to full Microsoft Graph endpoints.

- Invoke-GraphApiRequest.ps1
  - Function: Invoke-GraphApiRequest
  - Purpose: Wrapper around Graph web requests with shared auth header support, error handling, and retry behavior.

- Get-GraphUsers.ps1
  - Function: Get-GraphUsers
  - Purpose: Retrieves users from Graph with paging support by using Get-GraphURI + Invoke-GraphApiRequest.

- New-EntraGraphServicePrincipal.ps1
  - Function: New-EntraGraphServicePrincipal
  - Purpose: Creates or updates an Entra app registration + service principal, applies Graph application permissions, optionally grants admin consent, and can optionally create/upload a self-signed certificate.

- New-EntraSelfSignedCertificateCredential.ps1
  - Function: New-EntraSelfSignedCertificateCredential
  - Purpose: Creates a self-signed certificate and uploads it as an Entra application key credential.

- New-GraphAuthHeaderFromCertificate.ps1
  - Function: New-GraphAuthHeaderFromCertificate
  - Purpose: Authenticates with app + certificate and returns a Graph Authorization header hashtable.

- GraphSamples.ps1
  - Script examples (not a function library)
  - Purpose: Demonstrates common Graph calls (users, sites, drives, content download) using $authHeader.

- Upload-FIleToSharePoint.ps1
  - Script example (not a function library)
  - Purpose: Uploads a local file to a SharePoint document library through Microsoft Graph.

## Prerequisites

1. PowerShell 7+ (Windows PowerShell 5.1 can also work for most commands).
2. Required modules:
   - Az.Accounts
   - Microsoft.Graph.Authentication
   - Microsoft.Graph.Applications
3. Entra app registration/service principal with Graph application permissions for your target operations.
4. A certificate installed in the store you plan to use (for certificate auth).

Install modules if needed:

```powershell
Install-Module Az.Accounts -Scope CurrentUser
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Applications -Scope CurrentUser
```


## Dependency Map

### Function-level dependencies

- Get-GraphUsers
  - Depends on: Get-GraphURI, Invoke-GraphApiRequest

- Invoke-GraphApiRequest
  - Depends on: $AuthHeader being set (usually from New-GraphAuthHeaderFromCertificate)

- New-EntraGraphServicePrincipal
  - Optional internal dependency: New-EntraSelfSignedCertificateCredential when -CreateSelfSignedCertificate is used
  - Module dependency: Microsoft.Graph.Authentication, Microsoft.Graph.Applications

- New-EntraSelfSignedCertificateCredential
  - Depends on: active Graph context (for Get-MgApplication / Update-MgApplication)

- New-GraphAuthHeaderFromCertificate
  - Depends on: Az.Accounts
  - Produces: Graph auth header used by direct REST calls and by Invoke-GraphApiRequest

### Script-level dependencies

- GraphSamples.ps1
  - Depends on: New-GraphAuthHeaderFromCertificate.ps1
  - Requires variables: $AppId, $TenantId

- Upload-FIleToSharePoint.ps1
  - Depends on: New-GraphAuthHeaderFromCertificate.ps1
  - Requires variables: $AppId, $TenantId

### Recommended execution order

```powershell
# 1) Load helpers
. .\New-GraphAuthHeaderFromCertificate.ps1
. .\Invoke-GraphApiRequest.ps1
. .\Get-GraphURI.ps1
. .\Get-GraphUsers.ps1

# 2) Build auth header
$authHeader = New-GraphAuthHeaderFromCertificate -AppId $AppId -TenantId $TenantId -CertificateSubject 'CN=MyCert'
$script:AuthHeader = $authHeader

# 3) Call higher-level functions or sample scripts
Get-GraphUsers
. .\GraphSamples.ps1
. .\Upload-FIleToSharePoint.ps1
```

## Common Workflows

### 1) Create or update Entra app + service principal for Graph

```powershell
$newSpnParams = @{
  DisplayName = "spn-graph-automation"
  GraphApplicationPermissions = @("User.Read.All", "Group.Read.All", "Directory.Read.All")
  GrantAdminConsent = $true
  CreateSelfSignedCertificate = $true
  PfxOutputPath = ".\spn-graph-automation.pfx"
}

New-EntraGraphServicePrincipal @newSpnParams
```

### 2) Build Graph auth header from certificate

```powershell
$AppId = "<app-client-id>"
$TenantId = "<tenant-id>"

$authHeaderParams = @{
  AppId = $AppId
  TenantId = $TenantId
  CertificateSubject = "CN=MyCert"
}

$authHeader = New-GraphAuthHeaderFromCertificate @authHeaderParams
```

### 3) Get all users through helper functions

```powershell
# Required by Invoke-GraphApiRequest
$script:AuthHeader = $authHeader

$users = Get-GraphUsers
$users | Select-Object displayName,userPrincipalName -First 10
```

### 4) Run the sample scripts

```powershell
# Graph API examples (expects $AppId and $TenantId to already be set)
. .\GraphSamples.ps1

# SharePoint upload example (expects $AppId and $TenantId and local file path in script)
. .\Upload-FIleToSharePoint.ps1
```

## Notes

- Some scripts rely on shared variables ($AppId, $TenantId, $AuthHeader). Define these before running dependent scripts.
- If you get permission errors, verify Graph app roles and admin consent on the app registration.
- Use Get-Help <FunctionName> -Detailed for full help on documented functions.

