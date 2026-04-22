Function Get-EdgeBinaryVersion {
    param(
        [Parameter(Mandatory = $false)]
        [string] $EdgeBinaryPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    )
    $edgeBinaryVersion = (Get-Item $EdgeBinaryPath).VersionInfo.FileVersion
    Write-Output $edgeBinaryVersion
}

Function Wait-Element {
    param($xpath, $RetryMax = 5)
    $retry = 0
    Do {
        Try {
            $element = $edge.FindElement([OpenQA.Selenium.By]::XPath($xpath))
            Write-Verbose "Found $xpath"
        }
        Catch {
            $retry++
            Start-Sleep -Seconds 1
            Write-Verbose "Sleeping..."
        }
    }
    Until($null -ne $element -or $retry -eq $RetryMax)
    If ($null -eq $element) {
        Write-Error "Unable to find element $xpath"
    }
    Else {
        Write-Output $element
    }
    
}

Function Invoke-SeleniumUpgrade {
    param(
        [Parameter(Mandatory = $false)]
        [string] $OutputDir = $PSScriptRoot,
        [Parameter(Mandatory = $false)]
        [string] $EdgeBinaryVersion = $(Get-EdgeBinaryVersion)
    )
    
    $currentProgress = $ProgressPreference
    $ProgressPreference = "SilentlyContinue"
    $source = Invoke-RestMethod -uri "https://github.com/SeleniumHQ/selenium/releases/latest"
    $latestVersion = ([regex]::Match($source, "Release\sSelenium\s(?<version>\d*\.\d*\.\d*)").groups | Where-Object Name -eq "version").Value
    $edgedriverName = "edgedriver_$($edgeBinaryVersion)_win64"
    $seleniumName = "selenium-dotnet-$($latestVersion)"
    $edgeDriverURL = "https://msedgedriver.microsoft.com/$EdgeBinaryVersion/edgedriver_win64.zip"
    $seleniumURL = "https://github.com/SeleniumHQ/selenium/releases/download/selenium-$($latestVersion)/$seleniumName.zip"

    New-Item -Path $env:temp -Name $edgedriverName  -ItemType Directory -Force
    New-Item -Path $env:temp -Name $seleniumName    -ItemType Directory -Force

    Invoke-WebRequest -uri $edgeDriverURL   -OutFile "$env:temp\$edgedriverName.zip"
    Invoke-WebRequest -uri $seleniumURL     -OutFile "$env:temp\$seleniumName.zip"
    Expand-Archive -Path $env:temp\$edgedriverName.zip  -DestinationPath $env:temp\$edgedriverName -Force
    Expand-Archive -Path $env:temp\$seleniumName.zip    -DestinationPath $env:temp\$seleniumName -Force
    
    Rename-Item     -Path $env:temp\$seleniumName\Selenium.WebDriver.$($latestVersion).nupkg -NewName $env:temp\$seleniumName\Selenium.WebDriver.$($latestVersion).zip -Force
    Expand-Archive  -Path $env:temp\$seleniumName\Selenium.WebDriver.$($latestVersion).zip -DestinationPath $env:temp\$seleniumName -Force
    
    Copy-Item -Path "$env:temp\$edgedriverName\msedgedriver.exe"                -Destination $OutputDir                 -Force
    Copy-Item -Path "$env:temp\$seleniumName\lib\net8.0\WebDriver.dll"          -Destination $OutputDir\WebDriver8.dll -Force
    Copy-Item -Path "$env:temp\$seleniumName\lib\netstandard2.0\WebDriver.dll"  -Destination $OutputDir\WebDriver2.dll -Force
    
    Remove-Item -Path $env:temp\$edgedriverName -Recurse -Force
    Remove-Item -Path $env:temp\$seleniumName   -Recurse -Force
    Remove-Item -Path $env:temp\$edgedriverName.zip -Force
    Remove-Item -Path $env:temp\$seleniumName.zip   -Force
    
    $ProgressPreference = $currentProgress
}
Function Get-MFAFromNotifications {
    param(
        $Date = (Get-Date)
    )
        Do {
        $data  = Invoke-SqliteQuery -DataSource $env:localappdata\microsoft\windows\notifications\wpndatabase.db -Query 'SELECT * FROM Notification'
        $entry = $data | Where-Object {$null -ne $_.Payload} | Sort-Object Arrivaltime | Where-Object { [System.Text.Encoding]::ASCII.GetString($_.Payload) | Select-String "CIBC" } | Select-Object -last 1
        $last  = [TimeZoneInfo]::ConvertTimeFromUtc(
            [DateTime]::FromFileTimeUtc($entry.ArrivalTime),
            [TimeZoneInfo]::FindSystemTimeZoneById('Eastern Standard Time')
        )        
        Start-Sleep -Seconds 2
        Write-Host "$($last -gt $date)"
    }While ($last -lt $date)
    ([system.text.encoding]::utf8).GetString($entry.payload) -match 'Enter code: (?<code>\d{6})'|out-null
    $mfaCode = $matches.code
    Write-Output $mfaCode
    }

Function Show-MFAInputWindow {

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Data Entry Form'
    $form.Size = New-Object System.Drawing.Size(300, 200)
    $form.StartPosition = 'CenterScreen'

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75, 120)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(150, 120)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(280, 20)
    $label.Text = 'Please enter your currest MFA code:'
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10, 40)
    $textBox.Size = New-Object System.Drawing.Size(260, 20)
    $form.Controls.Add($textBox)

    $form.Topmost = $true

    $form.Add_Shown({ $textBox.Select() })
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $x = $textBox.Text
        $x
    }
}

