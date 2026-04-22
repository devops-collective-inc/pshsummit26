Function New-ScrapeSession {
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
    $session
}
Function Get-ScrapeDeals{
    param(
        [Microsoft.PowerShell.Commands.WebRequestSession]$session,
        [int]$page =0

    )
$size = 256
$xapiKey ="getyourownIHaveNoIdeaHowThisMightFingerPrintMeIfAtAll"
$cartID = "123456789-1234-1234-1234-123456789012" #This is a dummy cart ID.  
    $resp = Invoke-RestMethod -UseBasicParsing -Uri "https://api.pcexpress.ca/pcx-bff/api/v1/products/deals" `
-Method "POST" `
-WebSession $session `
-Headers @{
"Accept"="application/json, text/plain, */*"
  "x-apikey"=$xapiKey
} `
-ContentType "application/json" `
-Body "{`"pagination`":{`"from`":$page,`"size`":$size},`"banner`":`"nofrills`",`"cartId`":`"$cartID`",`"lang`":`"en`",`"date`":`"03062024`",`"storeId`":`"1335`",`"pcId`":null,`"pickupType`":`"SELF_SERVE_FULL`",`"sort`":{`"name`":`"asc`"},`"offerType`":`"ALL`"}"

$resp
}

Function Get-ScrapeListingPage{
    param(
        [Microsoft.PowerShell.Commands.WebRequestSession]$session,
        [int]$page =0,
        [int]$maxPages = 1,
        [int]$size = 256

    )

$xapiKey ="getyourownFromDevToolsIHaveNoIdeaHowThisMightFingerPrintMeIfAtAll"
$cartID = "123456789-1234-1234-1234-123456789012" #This is a dummy cart ID.  
    $resp = Invoke-RestMethod -UseBasicParsing -Uri "https://api.pcexpress.ca/pcx-bff/api/v2/listingPage/27985" `
-Method "POST" `
-WebSession $session `
-Headers @{
    "Accept"="*/*"
      "Accept-Encoding"="gzip, deflate, br, zstd"
      "Accept-Language"="en"
      "Business-User-Agent"="PCXWEB"
      "DNT"="1"
      "Origin"="https://www.nofrills.ca"
      "Origin_Session_Header"="B"
      "Referer"="https://www.nofrills.ca/"
      "Sec-Fetch-Dest"="empty"
      "Sec-Fetch-Mode"="cors"
      "Sec-Fetch-Site"="cross-site"
      "is-helios-account"="false"
      "sec-ch-ua"="`"Microsoft Edge`";v=`"125`", `"Chromium`";v=`"125`", `"Not.A/Brand`";v=`"24`""
      "sec-ch-ua-mobile"="?0"
      "sec-ch-ua-platform"="`"Windows`""
      "x-apikey"="$xapiKey"
      "x-application-type"="Web"
      "x-channel"="web"
      "x-loblaw-tenant-id"="ONLINE_GROCERIES"
      "x-preview"="false"
    } `
-ContentType "application/json" `
-Body "{`"cart`":{`"cartId`":`"$cartId`"},`"fulfillmentInfo`":{`"storeId`":`"1335`",`"pickupType`":`"SELF_SERVE_FULL`",`"offerType`":`"OG`",`"date`":`"03062024`",`"timeSlot`":null},`"listingInfo`":{`"filters`":{},`"sort`":{},`"pagination`":{`"from`":`"$page`"},`"includeFiltersInResponse`":true},`"banner`":`"nofrills`",`"userData`":{`"domainUserId`":`"afa42ba8-e451-4cde-9ba6-d6f377cffca7`",`"sessionId`":`"1db1289e-5da1-479c-92c8-09629eed4ab7`"}}"

$resp
}


Function Get-AllScrapeDeals{
    param(
        [Microsoft.PowerShell.Commands.WebRequestSession]$session,
        $maxPages
        )
    
    $page = 0
    $totalPages = 0
    $deals = @()
    do{
        $resp = Get-ScrapeDeals -session $session -page $page
        $deals += $resp.results
        $totalPages = $resp.pagination.totalResults / 255
        $page++
    }while($page -lt $totalPages)
    $deals
}

#This is where stuff goes off the rails IM SORRY 🍁
$response2 = Get-AllScrapeDeals
$list = $response2|
select Name,Brand,packagesize,stockstatus,@{n="WasPrice";e={"$($_.prices.wasPrice.value) $($_.prices.price.unit)"}},@{n="Price";e={"$($_.prices.price.value) $($_.prices.price.unit)"}},@{n="ComparisonPrice";e={"$($_.prices.comparisonPrices[0].value) per $($_.prices.comparisonPrices[0].quantity) $($_.prices.comparisonPrices[0].unit)"}}

$list | ? {$_.name -like "*dish*washer*" -or $_.name -like "*starbucks*Creamer*" -or $_.name -like "*shreddies*"} | Sort comparisonprice

