Function Get-CIBCJSONTransactions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $WebDriverDir = "$PSScriptRoot",
        [Parameter(Mandatory = $false)]
        [string] $EdgeBinaryPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        [Parameter(Mandatory = $false)]
        [pscredential] $Credential = $(get-secret CIBC),
        [Parameter(Mandatory = $false)]
        [pscredential] $AccountID = $(get-secret CIBC_AccID),
        [Parameter(Mandatory = $false)]
        [int]$limit = 1000,
        [Parameter(Mandatory = $false)]
        [int]$stopAt,
        [Parameter(Mandatory = $false)]
        [switch]$NotHeadless
    )
    #Don't hate.
    Import-Module "$PSScriptRRoot\..\Selenium\SeleniumFunctions.ps1"

    #Full Disclosure I don't think I ever got 5.1 working.  This is Act III people so hang on to your butts okay?
    Switch ($psVersionTable.PSEdition) {
        "Desktop" {
            $webDriverFileName = "WebDriver2.dll"
         
        }
        "Core" {
            $webDriverFileName = "WebDriver8.dll"
        }
    }

    
    If ( -Not $WebDriverDir) {
        $WebDriverDir = $PSScriptRoot
    }
    
    $webDriverPath = $(Join-Path -Path $WebDriverDir -childPath $webDriverFileName)

    If (-Not (Test-Path $webDriverPath)) {
        Write-Warning "Unable to find $webDriverFileName, run Invoke-SeleniumUpgrade to download latest version"
        Write-Error "Unable to find $webDriverFileName in $WebDriverDir" -ErrorAction Stop
    }
    If (-Not (Test-Path $EdgeBinaryPath)) {
        Write-Warning "Unable to find Edge binary, run Invoke-SeleniumUpgrade to download the version that matches your Edge binary"
        Write-Error "Unable to find Edge binary in $EdgeBinaryPath"
    }

    $edgeBinaryVersion = (Get-Item $EdgeBinaryPath).VersionInfo.FileVersion
    $webDriverVersion = (Get-Item $webDriverPath).VersionInfo.FileVersion
    $seleniumVersion = (Get-Item $(Join-Path -Path $WebDriverDir -childPath "msedgedriver.exe")).VersionInfo.ProductVersion

    Write-Verbose "Edge binary version: $edgeBinaryVersion"
    Write-Verbose "WebDriver version:   $webDriverVersion"
    Write-Verbose "Selenium version:    $seleniumVersion"


    If ($edgeBinaryVersion -ne $seleniumVersion) {
        
        Write-Warning "Edge binary version does not match Selenium version, running Invoke-SeleniumUpgrade to download the version that matches your Edge binary..."
        Try {
            Invoke-SeleniumUpgrade -OutputDir $WebDriverDir -EdgeBinaryVersion $edgeBinaryVersion
        }
        Catch {
            Write-Error "Invoke-SeleniumUpgrade failed, unable to continue." -ErrorAction Stop
        }
        #Write-Error "Edge binary version $edgeBinaryVersion does not match Selenium version $seleniumVersion" -ErrorAction Stop
        Write-Host "Done." -NoNewline
    }
    Add-Type -Path $webDriverPath


    $edgeOptions = [OpenQA.Selenium.Edge.EdgeOptions]::new()

    $edgeOptions.AddArgument("profile-directory=Default")
    $edgeOptions.AddArgument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36")
    If (-Not $NotHeadless) { $edgeOptions.AddArgument("headless") }
    $edgeOptions.AddArgument("disable-blink-features=AutomationControlled")
    $edgeOptions.AddArgument("log-level=3")
    $edgeOptions.AddArgument("windows-size=1920,1080")
    $edgeOptions.AddArgument("disable-extensions")
    $edgeOptions.AddArgument("disable-gpu")
    $edgeOptions.AddArgument("silentOutput")
    $edgeOptions.BinaryLocation = $EdgeBinaryPath


    $edge = [OpenQA.Selenium.Edge.EdgeDriver]::new("$WebDriverDir", [OpenQA.Selenium.Edge.EdgeOptions]$edgeOptions)
    Try {
        Start-Sleep -Seconds 5
        Write-Verbose "Navigating to CIBC..."
        $edge.Navigate().GoToUrl('https://www.cibconline.cibc.com/ebm-resources/online-banking/client/index.html#/auth/signon?locale=en')
        Try{
            Write-Verbose "Accepting cookies..."
            Start-Sleep -Seconds 5
            $acceptCookiesButton =  $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="onetrust-accept-btn-handler"]'))
            $acceptCookiesButton.Click()
            
        }
        Catch {
            Write-Verbose "Unable to accept cookies, continuing..."
        }

        Try {
            Write-Verbose "Searching for username field..."
            Start-Sleep -Seconds 5
            $usertxt = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="textfield-40-input"]'))
            $userTxt.SendKeys("$($credential.Username)")
        }
        Catch {
            Write-Verbose "Unable to send username, retying..."
            Start-Sleep -Seconds 5
            $userTxt = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="textfield-40-input"]'))
            $userTxt.SendKeys("$($credential.Username)")
        }

        Try {
            Write-Verbose "Searching for Next button field..."
            Start-Sleep -Seconds 5
            $nextButton1 = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="mainContainer"]/div/div/div/div[2]/div[2]/form/div[4]/div/div/button[1]'))
            $nextButton1.Click()
        }
        Catch {
            Write-Verbose "Unable to find Next button, retrying..."
            Start-Sleep -Seconds 5
            $nextButton1 = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="mainContainer"]/div/div/div/div[2]/div[2]/form/div[4]/div/div/button[1]'))
            $nextButton1.SendKeys($($credential.GetNetworkCredential().Password))
        }
        Try {
            Write-Verbose "Searching for password field..."
            Start-Sleep -Seconds 5
            $pwTxt = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="textfield-57-input"]'))
            $pwTxt.SendKeys($($credential.GetNetworkCredential().Password))
        }
        Catch {
            Write-Verbose "Unable to send password, retrying..."
            Start-Sleep -Seconds 5
            $pwTxt = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="textfield-57-input"]'))
            $pwTxt.SendKeys($($credential.GetNetworkCredential().Password))
        }

        $date = Get-Date
    
        Try {
        
            Write-Verbose "Searching for next button..."
            Start-Sleep -Seconds 1
            $nextBtn = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="mainContainer"]/div/div/div/div[2]/div[2]/form/div[3]/button'))
            $nextBtn.Click()
        }
        Catch {
            Write-Verbose "Unable to click next button, retrying..."
            Start-Sleep -Seconds 3
            $nextBtn = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="mainContainer"]/div/div/div/div[2]/div[2]/form/div[3]/button'))
            $nextBtn.Click()
        }
    
    
    
        
            $mfaCode = Get-MFAFromNotifications -Date $date
        
            Try {
                Write-Verbose "Searching for MFA input field..."
                Start-Sleep -Seconds 5
                $usertxt = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="textfield-76-input"]'))
                $userTxt.SendKeys("$mfaCode")
            }
            Catch {
                Write-Verbose "Unable to send MFA code, retrying..."
                Start-Sleep -Seconds 5
                $userTxt = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="textfield-76-input"]'))
                $userTxt.SendKeys("$mfaCode")
            }


            Try {
        
                Write-Verbose "Searching for next button..."
                Start-Sleep -Seconds 5
                $nextBtn = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="mainContainer"]/div/div/div/div[2]/div[2]/div[2]/form/div[3]/div/div/button[1]'))    
                $nextBtn.Click()
            }
            Catch {
                Write-Verbose "Unable to click next button, retrying..."
                Start-Sleep -Seconds 1
                TRY {
                    $nextBtn = $edge.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="mainContainer"]/div/div/div/div[2]/div[2]/div[2]/form/div[3]/div/div/button[1]'))    
                    $nextBtn.Click()
                }
                CATCH {}
            
    
        }
        Start-Sleep -Seconds 5
        $xAuthToken = $edge.ExecuteScript("return sessionStorage.getItem('ebanking:session_token')") -replace '"', ''
    

        $accountID           = $AccountID.GetNetworkCredential().Password
        $filterBy            = "range"
        $fromDate            = "2018-01-01"
        $toDate              = (Get-Date -Day 31 -Month 12 -Year (Get-Date).Year).ToString("yyyy-MM-dd")
        $interaction         = $null
        $lastFilterBy        = $filterBy
        $limit               = 1000
        $lowerLimitAmount    = $null
        $offset              = 0
        $sortAsc             = "false"
        $sortByField         = "date"
        $transactionLocation = $null
        $transactionType     = $null
        $upperLimitAmount    = $null
        $stopAt              = 1000                                                                       #>

        $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0"
        $total = @()
        Do {
            $uri = "https://www.cibconline.cibc.com/ebm-ai/api/v1/json/transactions?accountId=$accountId&filterBy=$filterby&fromDate=$fromDate&interaction=$interaction&lastFilterBy=$lastFilterBy&limit=$limit&lowerLimitAmount=$lowerLimitAmount&offset=$offset&sortAsc=$sortAsc&sortByField=$sortByField&toDate=$toDate&transactionLocation=$transactionLocation&transactionType=$transactionType&upperLimitAmount=$upperLimitAmount"
    
            $resp = Invoke-RestMethod -Uri $uri `
                -WebSession $session `
                -Headers @{
                "authority"        = "www.cibconline.cibc.com"
                "method"           = "GET"
                "scheme"           = "https"
                "accept"           = "application/vnd.api+json"
                "accept-encoding"  = "gzip, deflate, br, zstd"
                "accept-language"  = "en"
                "brand"            = "cibc"
                "client-type"      = "default_web"
                "path"             = $uri
                "x-auth-token"     = "$xAuthToken"
                "x-device-id"      = "undefined"
                "x-requested-with" = "XMLHttpRequest"
            } `
                -ContentType "application/vnd.api+json"
            $total += $resp.transactions 
            Write-Verbose "Fetched $($total.Count) transactions..."
            $offset += $limit
        
        } While ($resp.meta.hasNext -eq $true -AND (@(($total.Count -lt $stopAt), $true)[($false -eq $stopAt + 0)]))

        foreach ($entry in  ($total)) {
            $accountId      = $entry.accountId
            $date           = $entry.date
            $postedDate     = $entry.postedDate
            $description    = $entry.transactionDescription -replace '\s+', '_'
            $debit          = $entry.debitAmount
            $credit         = $entry.creditAmount
            $runningBalance = $entry.runningBalance
            #My attempt at creating a unique transaction ID since CIBC doesn't provide one.  This is a naive implementation and may not be 100% unique but should be sufficient for demo purposes.
            $transactionId = "{0}--{1}--{2}--{3}--{4}--{5}--{6}" -f $accountId, $date, $postedDate, $description, $debit, $credit, $runningBalance
            Add-Member -InputObject $entry -NotePropertyMembers @{
                TransactionId = $transactionId
            }
        }
        $edge.Quit()

        Write-Output $total
    }
    Catch {
        $edge.Quit()
        Write-Error "An error occurred: $_"
    }
}