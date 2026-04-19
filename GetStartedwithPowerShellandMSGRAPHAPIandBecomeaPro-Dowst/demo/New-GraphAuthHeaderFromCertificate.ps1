function New-GraphAuthHeaderFromCertificate {
    <#
    .SYNOPSIS
    Builds a Microsoft Graph Authorization header by authenticating with an app certificate.

    .DESCRIPTION
    Finds a certificate in the local certificate store by subject, signs in with the specified
    Entra application (service principal) using certificate authentication, requests a Microsoft Graph
    access token, and returns a hashtable Authorization header suitable for Invoke-RestMethod
    and Invoke-WebRequest calls.

    The function validates that exactly one matching certificate exists so authentication uses
    a predictable identity.

    .PARAMETER AppId
    Application (client) ID of the Entra app registration used for certificate-based authentication.

    .PARAMETER TenantId
    Tenant ID where the app registration exists.

    .PARAMETER CertificateSubject
    Subject name of the certificate to use. Default is CN=MyCert.

    .PARAMETER CertificateStorePath
    Certificate store path to search. Default is cert:\CurrentUser\My.

    .OUTPUTS
    Hashtable

    .EXAMPLE
    $authHeader = New-GraphAuthHeaderFromCertificate -AppId '11111111-2222-3333-4444-555555555555' -TenantId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'

    Authenticates using the default certificate subject CN=MyCert and returns a Graph Authorization header.

    .EXAMPLE
    $authHeader = New-GraphAuthHeaderFromCertificate -AppId '11111111-2222-3333-4444-555555555555' -TenantId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' -CertificateSubject 'CN=spn-graph-automation' -CertificateStorePath 'cert:\LocalMachine\My'

    Uses a certificate from the local machine store and returns a Graph Authorization header.

    .NOTES
    Requires Az.Accounts and permission for the app to request Graph tokens via client credentials.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AppId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateSubject = 'CN=MyCert',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateStorePath = 'cert:\CurrentUser\My'
    )

    # Resolve a single certificate by subject so authentication uses a predictable identity.
    $certMatches = Get-ChildItem -Path $CertificateStorePath | Where-Object { $_.Subject -eq $CertificateSubject }
    if (-not $certMatches) {
        throw "No certificate found with subject '$CertificateSubject' in '$CertificateStorePath'."
    }
    if (@($certMatches).Count -gt 1) {
        throw "Multiple certificates found with subject '$CertificateSubject'. Use a more specific subject."
    }

    $cert = $certMatches | Select-Object -First 1
    # Store the AppId and TenantID in a global variable so it can be accessed by Invoke-GraphApiRequest when renewing tokens.
    $global:AppId = $AppId
    $global:TenantId = $TenantId

    # Authenticate with the app registration and request a Microsoft Graph token.
    Add-AzAccount -CertificateThumbprint $cert.Thumbprint -ApplicationId $AppId -TenantId $TenantId -ErrorAction Stop | Out-Null
    $AADToken = (Get-AzAccessToken -ResourceTypeName MSGraph -ErrorAction Stop -WarningAction SilentlyContinue).Token

    if ($AADToken -is [SecureString]) {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AADToken)
        try {
            $AADToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }

    @{
        Authorization = "Bearer $AADToken"
    }
}