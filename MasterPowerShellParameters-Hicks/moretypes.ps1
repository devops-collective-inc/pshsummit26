return 'This is a demo script file'

function Get-LocationInfo {
    [cmdletbinding()]
    param(
        [System.IO.DirectoryInfo]$Path = '.'
    )

    Write-Host "Processing $($Path.Name)"
}

function Get-FileDetail {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$FilePath
    )

    Write-Host "Processing $($FilePath.Name) in $($FilePath.DirectoryName)"
}

function Get-ServiceDetail {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('Service')]
        [ValidateScript({$_.Name},ErrorMessage = "The specified value does not appear to be a valid service")]
        [System.ServiceProcess.ServiceController]$Name
    )
    Write-Host "Processing $($name.Name) which is currently $($name.Status)" -ForegroundColor Cyan
}

