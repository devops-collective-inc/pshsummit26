<#
.SYNOPSIS
This script ensures that log files for Intune deployed applications are included in diagnostic log collections.
.DESCRIPTION
This script will check the list of properties under HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MdmDiagnostics\Area\DeviceProvisioning\FileEntry and ensure it matches up with the expected list of log files for Intune deployed applications. If any are missing it will add them in the remediation script.
.PARAMETER folders
A list of folders to check for log files. The script will look for .log files in these folders and add them to the FileEntry registry key if they are not already present.
.EXAMPLE
.\AddSrccodeFolderLogsToDiagnosticsCollection.ps1 -folders "C:\Program Files\Microsoft Intune Management Extension\Logs\","C:\Program Files (x86)\Microsoft Intune Management Extension\Logs\"
This command checks the specified folders for log files and ensures they are included in the FileEntry registry key for diagnostic collections.
.NOTES
Make sure to run this script with administrative privileges, as it modifies the registry. Note that if there are multiple log files of the same name, only one will end up in the collection.
#>
[cmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$folders = @("$env:windir\Logs\Software\","C:\WowItWorked\")
)
Function GetLogFolderNames {
    <#
    .SYNOPSIS
    Retrieves the names of log folders from a specified path.
    .DESCRIPTION
    This function takes a folder path as input and retrieves the unique directory names of log files with a .log extension. It uses Get-ChildItem to search for log files recursively and extracts the directory names, which are then returned as output.
    .PARAMETER LogFolderPath
    The path to the folder where log files are located. The function will search for .log files within this folder and its subfolders.
    .OUTPUTS
    An array of unique directory names containing log files.
    .EXAMPLE
    GetLogFolderNames -LogFolderPath "C:\Logs\"
    This command retrieves the unique directory names of log files located in the C:\Logs\ folder and its subfolders.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [string]$LogFolderPath = "C:\WowItWorked\"
    )
    Try {
        Write-Information -MessageData "Getting log folder names from $LogFolderPath..."
        $folderNames = Get-ChildItem -Path $LogFolderPath -Filter "*.log" -Recurse | Select-Object -ExpandProperty DirectoryName -Unique
        Write-Output $folderNames
    }
    Catch {
        Write-Information -MessageData "Error getting log folder names."
        Write-Information -MessageData $_.Exception.Message
        Exit 1
    }
}

Function CheckFileEntryProperties {
    <#
    .SYNOPSIS
    Checks if a specific log folder is already included in the FileEntry registry key.
    .DESCRIPTION
    This function takes a log folder name as input and checks if there is a corresponding property in the HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MdmDiagnostics\Area\DeviceProvisioning\FileEntry registry key. It returns $true if the property exists, indicating that the log folder is already included in diagnostic collections, or $false if it does not exist.
    .PARAMETER logFolder
    The name of the log folder to check for in the FileEntry registry key.
    .OUTPUTS
    A boolean value indicating whether the log folder is included in the FileEntry registry key.
    .EXAMPLE
    CheckFileEntryProperties -logFolder "C:\Logs\App1"
    This command checks if the log folder "C:\Logs\App1" is included in the FileEntry registry key and returns $true if it is, or $false if it is not.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$FolderName
    )
    Process {
        Write-Information -MessageData "Checking HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MdmDiagnostics\Area\DeviceProvisioning\FileEntry\ for: `n$folderName\*.log..."
        If (Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MdmDiagnostics\Area\DeviceProvisioning\FileEntry\ -Name "$folderName\*.log" -ErrorAction SilentlyContinue) {
            Write-Output $true
            Write-Information -MessageData "Found!"
        }
        Else {
            Write-Output $false
            Write-Information "Not Found!"
        }
    }
}

Function AddFileEntryProperty {
    <#
    .SYNOPSIS
    Adds a new property to the FileEntry registry key for a specified log folder.
    .DESCRIPTION
    This function takes a log folder name as input and adds a new property to the HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MdmDiagnostics\Area\DeviceProvisioning\FileEntry registry key with the name "$folderName\*.log" and a value of 255. This allows log files in the specified folder to be included in diagnostic collections.
    .PARAMETER logFolder
    The name of the log folder to add as a property in the FileEntry registry key.
    .EXAMPLE
    AddFileEntryProperty -logFolder "C:\Logs\App1"
    This command adds a new property named "C:\Logs\App1\*.log" with a value of 255 to the FileEntry registry key, allowing log files in the "C:\Logs\App1" folder to be included in diagnostic collections.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FolderName
    )
    Process {
        Try {

            Write-Information -MessageData "Adding $folderName\*.log to HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MdmDiagnostics\Area\DeviceProvisioning\FileEntry\"
            New-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MdmDiagnostics\Area\DeviceProvisioning\FileEntry\ -Name "$folderName\*.log" -Type DWORD -Value 255 | Out-Null
            Write-Information -MessageData "Added!"
        }
        Catch {
            Write-Information -MessageData "Error adding $folderName\*.log to HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MdmDiagnostics\Area\DeviceProvisioning\FileEntry\"
            Write-Information -MessageData $_.Exception.Message
            Exit 1
        }
    }
}
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"



Foreach ( $folder in $folders ) {
    Write-Information -MessageData "Checking for $folder..."
    If (Test-Path $folder) {
        
        Write-Information -MessageData "Found $folder"
        
        
        Write-Information -MessageData "Getting log folder names..."
        Try {
            $logFolderNames = GetLogFolderNames -LogFolderPath $folder
            Write-Information -MessageData "...Done."
        }
        Catch {
            Write-Information -MessageData "Error getting log folder names."
            Write-Information -MessageData $_.Exception.Message
            Exit 1
        }
        
        Write-Information -MessageData "Checking FileEntry properties..."
        Foreach ($logFolder in $logFolderNames) {
            
            If ($logFolder | CheckFileEntryProperties) {

                Write-Information -MessageData "No action required for $logFolder\*.log"

            }#if logfolder
            Else {
               
                AddFileEntryProperty -FolderName $logFolder

            }#else
        }
    }#if test-path
    Else {
        Write-Information -MessageData "$folder Not Found!"
        Exit 1
    }#else
}#foreach folder


Write-Information -MessageData "Script completed successfully."
Exit 0