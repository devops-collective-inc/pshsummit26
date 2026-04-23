function Invoke-Nonsense {
    param (
        $path,
        $process,
        $Sevice
    )

    if ($path) {
        Get-ChildItem -Path c:\Does-Not-Exist -ErrorAction Stop
    }

    if ($process) {
        Get-Process Nothing
    }

    if ($service) {
        Get-Service Unknown
    }

}