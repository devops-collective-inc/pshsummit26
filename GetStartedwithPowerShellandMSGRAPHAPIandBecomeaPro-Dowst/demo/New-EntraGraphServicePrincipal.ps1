function New-EntraGraphServicePrincipal {
    <#
    .SYNOPSIS
    Creates or updates an Entra ID application and service principal with Microsoft Graph application permissions.

    .DESCRIPTION
    Creates an Entra ID app registration when it does not already exist, ensures a matching service principal exists,
    configures Microsoft Graph application permissions on the app registration, and can optionally grant tenant admin
    consent for those app roles.

    Optionally, this function can also create a self-signed certificate and upload the public key as an application
    key credential so the service principal can authenticate with certificate-based client credentials.

    This function is idempotent for app creation, service principal creation, and app role consent assignments.

    .PARAMETER DisplayName
    Display name for the Entra application and service principal.

    .PARAMETER TenantId
    Optional tenant ID used when connecting to Microsoft Graph.

    .PARAMETER GraphApplicationPermissions
    List of Microsoft Graph application permission values (app roles) to assign to the app registration,
    such as User.Read.All or Directory.Read.All.

    .PARAMETER GrantAdminConsent
    When provided, grants admin consent for each requested Graph application permission by creating app role
    assignments on the target service principal.

    .PARAMETER CreateSelfSignedCertificate
    When provided, creates a self-signed certificate and uploads it to the application as a key credential.

    .PARAMETER CertificateValidityYears
    Certificate lifetime in years when CreateSelfSignedCertificate is used.

    .PARAMETER CertificateSubject
    Certificate subject name. Defaults to CN=<DisplayName> when omitted.

    .PARAMETER PfxOutputPath
    Optional path to export a PFX copy of the generated certificate. If supplied, a random password is generated
    and returned in the function output under Certificate.PfxPassword.

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    New-EntraGraphServicePrincipal -DisplayName 'spn-graph-automation'

    Creates or updates an app/service principal with default Graph application permissions.

    .EXAMPLE
    New-EntraGraphServicePrincipal -DisplayName 'spn-graph-automation' -GraphApplicationPermissions 'User.Read.All','Group.Read.All','Directory.Read.All' -GrantAdminConsent

    Creates or updates the app/service principal, assigns the specified Graph app permissions, and grants admin consent.

    .EXAMPLE
    New-EntraGraphServicePrincipal -DisplayName 'spn-graph-automation' -GraphApplicationPermissions 'User.Read.All' -CreateSelfSignedCertificate -CertificateValidityYears 3 -PfxOutputPath '.\spn-graph-automation.pfx'

    Creates or updates the app/service principal, uploads a self-signed certificate credential, and exports a PFX file.

    .NOTES
    Required Microsoft Graph delegated scopes for the operator typically include:
    - Application.ReadWrite.All
    - AppRoleAssignment.ReadWrite.All
    - Directory.Read.All
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter()]
        [string]$TenantId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$GraphApplicationPermissions = @(
            'User.Read.All',
            'Group.Read.All'
        ),

        [Parameter()]
        [switch]$GrantAdminConsent,

        [Parameter()]
        [switch]$CreateSelfSignedCertificate,

        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$CertificateValidityYears = 2,

        [Parameter()]
        [string]$CertificateSubject,

        [Parameter()]
        [string]$PfxOutputPath
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $requiredModules = @(
        'Microsoft.Graph.Authentication',
        'Microsoft.Graph.Applications'
    )

    foreach ($moduleName in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            throw "Required module '$moduleName' is not installed. Install-Module $moduleName -Scope CurrentUser"
        }
        Import-Module $moduleName -ErrorAction Stop
    }

    $graphScopes = @(
        'Application.ReadWrite.All',
        'AppRoleAssignment.ReadWrite.All',
        'Directory.Read.All'
    )

    if (-not (Get-MgContext)) {
        if ([string]::IsNullOrWhiteSpace($TenantId)) {
            Connect-MgGraph -Scopes $graphScopes -NoWelcome | Out-Null
        }
        else {
            Connect-MgGraph -TenantId $TenantId -Scopes $graphScopes -NoWelcome | Out-Null
        }
    }

    $graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
    if (-not $graphSp) {
        throw 'Microsoft Graph service principal was not found in this tenant.'
    }

    $graphAppRoles = $graphSp.AppRoles | Where-Object {
        $_.AllowedMemberTypes -contains 'Application' -and $_.IsEnabled
    }

    $resourceAccess = New-Object 'System.Collections.Generic.List[Microsoft.Graph.PowerShell.Models.IMicrosoftGraphResourceAccess]'
    foreach ($permission in $GraphApplicationPermissions) {
        $role = $graphAppRoles | Where-Object { $_.Value -eq $permission } | Select-Object -First 1
        if (-not $role) {
            throw "Graph application permission '$permission' was not found."
        }

        $resourceAccess.Add([Microsoft.Graph.PowerShell.Models.MicrosoftGraphResourceAccess]@{
                Id   = $role.Id
                Type = 'Role'
            })
    }

    $requiredResourceAccess = @(
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess]@{
            ResourceAppId  = '00000003-0000-0000-c000-000000000000'
            ResourceAccess = $resourceAccess
        }
    )

    $app = Get-MgApplication -Filter "displayName eq '$DisplayName'" | Select-Object -First 1
    if (-not $app) {
        if ($PSCmdlet.ShouldProcess($DisplayName, 'Create Entra application')) {
            $app = New-MgApplication -DisplayName $DisplayName -RequiredResourceAccess $requiredResourceAccess
            Write-Host "Created application: $($app.DisplayName) ($($app.AppId))" -ForegroundColor Green
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess($DisplayName, 'Update required Graph permissions on application')) {
            Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess $requiredResourceAccess
        }
        Write-Host "Using existing application: $($app.DisplayName) ($($app.AppId))" -ForegroundColor Cyan
    }

    $sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'" | Select-Object -First 1
    if (-not $sp) {
        if ($PSCmdlet.ShouldProcess($DisplayName, 'Create service principal')) {
            $sp = New-MgServicePrincipal -AppId $app.AppId
            Write-Host "Created service principal: $($sp.Id)" -ForegroundColor Green
        }
    }
    else {
        Write-Host "Using existing service principal: $($sp.Id)" -ForegroundColor Cyan
    }

    if ($GrantAdminConsent) {
        foreach ($permission in $GraphApplicationPermissions) {
            $role = $graphAppRoles | Where-Object { $_.Value -eq $permission } | Select-Object -First 1

            $existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All |
                Where-Object {
                    $_.ResourceId -eq $graphSp.Id -and $_.AppRoleId -eq $role.Id
                } |
                Select-Object -First 1

            if (-not $existingAssignment) {
                if ($PSCmdlet.ShouldProcess($permission, 'Grant Graph app role admin consent')) {
                    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $role.Id | Out-Null
                    Write-Host "Granted admin consent for: $permission" -ForegroundColor Green
                }
            }
            else {
                Write-Host "Admin consent already granted for: $permission" -ForegroundColor Cyan
            }
        }
    }

    $certificate = $null
    if ($CreateSelfSignedCertificate) {
        if ([string]::IsNullOrWhiteSpace($CertificateSubject)) {
            $CertificateSubject = "CN=$DisplayName"
        }

        $certificate = New-EntraSelfSignedCertificateCredential -ApplicationObjectId $app.Id -DisplayName $DisplayName -ValidityYears $CertificateValidityYears -Subject $CertificateSubject -PfxOutputPath $PfxOutputPath
    }

    [pscustomobject]@{
        DisplayName                   = $app.DisplayName
        ApplicationObjectId           = $app.Id
        ApplicationId                 = $app.AppId
        ServicePrincipalObjectId      = $sp.Id
        GraphApplicationPermissions   = $GraphApplicationPermissions
        GrantAdminConsent             = [bool]$GrantAdminConsent
        Certificate                   = $certificate
    }
}

# Example:
# New-EntraGraphServicePrincipal -DisplayName 'spn-graph-automation' -GraphApplicationPermissions 'User.Read.All','Group.Read.All' -GrantAdminConsent
    # New-EntraGraphServicePrincipal -DisplayName 'spn-graph-automation' -GraphApplicationPermissions 'User.Read.All','Group.Read.All' -GrantAdminConsent -CreateSelfSignedCertificate -PfxOutputPath '.\spn-graph-automation.pfx'