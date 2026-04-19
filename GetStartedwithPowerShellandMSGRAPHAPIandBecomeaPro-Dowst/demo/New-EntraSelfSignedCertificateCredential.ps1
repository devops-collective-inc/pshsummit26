function New-EntraSelfSignedCertificateCredential {
    <#
    .SYNOPSIS
    Creates a self-signed certificate and uploads it to an Entra application as a key credential.

    .DESCRIPTION
    Generates a self-signed certificate in the current user's certificate store and appends the certificate
    public key to the target Entra application key credentials.

    The uploaded key credential is used by the service principal for certificate-based client credentials flow.
    Optionally exports the certificate as a PFX file and returns the generated password in output.

    .PARAMETER ApplicationObjectId
    Object ID of the Entra application to update.

    .PARAMETER DisplayName
    Friendly name used in the generated key credential display name.

    .PARAMETER ValidityYears
    Certificate validity period in years. Allowed range is 1 to 10.

    .PARAMETER Subject
    Certificate subject. Defaults to CN=<DisplayName>.

    .PARAMETER PfxOutputPath
    Optional output path for exporting a PFX file.

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    New-EntraSelfSignedCertificateCredential -ApplicationObjectId '11111111-2222-3333-4444-555555555555' -DisplayName 'spn-graph-automation'

    Creates a 2-year self-signed certificate, uploads it as an app key credential, and returns certificate details.

    .EXAMPLE
    New-EntraSelfSignedCertificateCredential -ApplicationObjectId '11111111-2222-3333-4444-555555555555' -DisplayName 'spn-graph-automation' -ValidityYears 3 -Subject 'CN=spn-graph-automation, O=Contoso' -PfxOutputPath '.\spn-graph-automation.pfx'

    Creates a 3-year certificate with a custom subject, uploads it, exports a PFX, and returns the generated PFX password.

    .NOTES
    Requires Microsoft Graph connection with sufficient permissions to update application credentials.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApplicationObjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$ValidityYears = 2,

        [Parameter()]
        [string]$Subject = "CN=$DisplayName",

        [Parameter()]
        [string]$PfxOutputPath
    )

    $notAfter = (Get-Date).AddYears($ValidityYears)
    $cert = New-SelfSignedCertificate -Subject $Subject -CertStoreLocation 'cert:\CurrentUser\My' -KeySpec Signature -NotAfter $notAfter

    $app = Get-MgApplication -ApplicationId $ApplicationObjectId
    $keyCredential = [Microsoft.Graph.PowerShell.Models.MicrosoftGraphKeyCredential]@{
        Type        = 'AsymmetricX509Cert'
        Usage       = 'Verify'
        DisplayName = "$DisplayName-certificate"
        Key         = $cert.RawData
        StartDateTime = $cert.NotBefore
        EndDateTime = $cert.NotAfter
    }

    $allKeys = @()
    if ($app.KeyCredentials) {
        $allKeys += $app.KeyCredentials
    }
    $allKeys += $keyCredential

    if ($PSCmdlet.ShouldProcess($DisplayName, 'Upload certificate credential to Entra application')) {
        # Application credentials are used by the service principal during client credential flows.
        Update-MgApplication -ApplicationId $ApplicationObjectId -KeyCredentials $allKeys
    }

    $pfxPassword = $null
    if (-not [string]::IsNullOrWhiteSpace($PfxOutputPath)) {
        $pfxPassword = [guid]::NewGuid().ToString()
        $securePass = ConvertTo-SecureString $pfxPassword -AsPlainText -Force
        Export-PfxCertificate -Cert "cert:\CurrentUser\My\$($cert.Thumbprint)" -FilePath $PfxOutputPath -Password $securePass | Out-Null
    }

    [pscustomobject]@{
        Thumbprint   = $cert.Thumbprint
        Subject      = $cert.Subject
        NotBefore    = $cert.NotBefore
        NotAfter     = $cert.NotAfter
        PfxOutputPath = $PfxOutputPath
        PfxPassword  = $pfxPassword
    }
}