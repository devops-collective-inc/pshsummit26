function New-SummitUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$Password
    )

    # Create a new user object
    $user = New-Object PSObject -Property @{
        Username = $Username
        Password = $Password
    }

    # Return the new user object
    return $user
}