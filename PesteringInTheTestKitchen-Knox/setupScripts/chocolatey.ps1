Set-ExecutionPolicy Bypass -Force

$null = New-Item -Path 'HKLM:/SOFTWARE/Policies/Microsoft/Windows/StorageSense' -ErrorAction SilentlyContinue -Force
$null = New-ItemProperty 'HKLM:/SOFTWARE/Policies/Microsoft/Windows/StorageSense' -Name 'AllowStorageSenseGlobal' -PropertyType DWORD -Value 0 -Force
$null = New-Item -Path 'HKLM:/SOFTWARE/Policies/Microsoft/Windows/WindowsUpdate/AU' -ErrorAction SilentlyContinue -Force
$null = New-ItemProperty 'HKLM:/SOFTWARE/Policies/Microsoft/Windows/WindowsUpdate/AU' -Name 'AUOptions' -PropertyType DWORD -Value 2 -Force

# Disable First Run wizards for IE and Edge
$null = New-Item -Path 'HKLM:/Software/Policies/Microsoft/Edge' -Force
$null = New-ItemProperty -Path 'HKLM:/Software/Policies/Microsoft/Edge' -Name 'HideFirstRunExperience' -Value 1
$null = New-Item -Path 'HKLM:/Software/Microsoft/Internet Explorer/Main' -Force
$null = New-ItemProperty -Path 'HKLM:/Software/Microsoft/Internet Explorer/Main' -Name 'DisableFirstRunCustomize' -Value 1
$null = New-Item -Path 'HKLM:/Software/Policies/Microsoft/Internet Explorer/Main' -Force
$null = New-ItemProperty -Path 'HKLM:/Software/Policies/Microsoft/Internet Explorer/Main' -Name 'DisableFirstRunCustomize' -Value 1
$null = cscript C:/Windows/system32/slmgr.vbs /rearm

$packages = Resolve-Path "$PSScriptRoot/../packages"
$env:chocolateyDownloadUrl = "$packages/Chocolatey.nupkg"

& "$PSScriptRoot/installChocolatey.ps1"
choco source add -n local -s $packages
choco source disable -n chocolatey
choco feature enable -n allowGlobalConfirmation
choco feature disable -n showDownloadProgress
choco install pester chocolatey-community-validation.extension
