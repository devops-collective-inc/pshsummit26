class NetworkAdapter {
    [string]$Name
    [string]$MacAddress
    [string]$IPAddress
    [int]$VLAN
    [bool]$DhcpEnabled

    NetworkAdapter(
        [string]$Name,
        [string]$MacAddress,
        [string]$IPAddress,
        [int]$VLAN,
        [bool]$DhcpEnabled
    ) {
        $this.Name         = $Name
        $this.MacAddress   = $MacAddress
        $this.IPAddress    = $IPAddress
        $this.VLAN         = $VLAN
        $this.DhcpEnabled  = $DhcpEnabled
    }
}

class ServerRecord {
    [string]$ServerName
    [string]$OperatingSystem
    [string]$Domain
    [string]$SerialNumber
    [bool]$IsVirtual
    [string[]]$Tags
    [NetworkAdapter[]]$NetworkAdapters
    [datetime]$LastBootTime
    [datetime]$LastPatched
    [string]$PatchWindow
    
    ServerRecord(
        [string]$ServerName,
        [string]$OperatingSystem,
        [string]$Domain,
        [string]$SerialNumber,
        [bool]$IsVirtual,
        [datetime]$LastBootTime,
        [datetime]$LastPatched,
        [string]$PatchWindow,
        [string[]]$Tags,
        [NetworkAdapter[]]$NetworkAdapters
    ) {
        $this.ServerName       = $ServerName
        $this.OperatingSystem  = $OperatingSystem
        $this.Domain           = $Domain
        $this.SerialNumber     = $SerialNumber
        $this.IsVirtual        = $IsVirtual
        $this.LastBootTime     = $LastBootTime
        $this.LastPatched      = $LastPatched
        $this.PatchWindow      = $PatchWindow
        $this.Tags             = $Tags
        $this.NetworkAdapters  = $NetworkAdapters
    }
}

# Create instance
$serverRecords = [Collections.Generic.List[ServerRecord]]::new()
$serverRecords.Add([ServerRecord]::new(
    'SQL-PROD-01',
    'Windows Server 2022',
    'corp.contoso.com',
    'VMW-4221-8847',
    $true,
    [datetime]'2026-03-01T04:12:33',
    [datetime]'2026-03-15T22:30:00',
    'Sunday 02:00-04:00',
    @('SQL', 'Critical', 'Finance', 'Tier1'),
    @(
        [NetworkAdapter]::new('Ethernet0', '00-50-56-A1-B2-C3', '10.42.18.25', 120, $false),
        [NetworkAdapter]::new('Ethernet1', '00-50-56-A1-B2-C4', '192.168.50.10', 220, $false)
    )
))

$serverRecords.Add([ServerRecord]::new(
    'APP-PROD-01',
    'Windows Server 2022',
    'corp.contoso.com',
    'VMW-4221-8848',
    $true,
    [datetime]'2026-03-01T04:12:33',
    [datetime]'2026-03-15T22:30:00',
    'Sunday 02:00-04:00',
    @('App', 'Critical', 'Finance', 'Tier1'),
    @(
        [NetworkAdapter]::new('Ethernet0', '00-50-56-A1-B2-C5', '10.42.18.17', 120, $false),
        [NetworkAdapter]::new('Ethernet1', '00-50-56-A1-B2-C6', '192.168.50.22', 220, $false)
    )
))

$formatXml = @'
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
  <ViewDefinitions>
    <View>
      <Name>ServerRecord</Name>
      <ViewSelectedBy>
        <TypeName>ServerRecord</TypeName>
      </ViewSelectedBy>
      <CustomControl>
        <CustomEntries>
          <CustomEntry>
            <CustomItem>
              <ExpressionBinding>
                <ScriptBlock>
$obj = $_
$output = @()
$output += "`nServerName      : $($obj.ServerName)"
$output += "OperatingSystem : $($obj.OperatingSystem)"
$output += "Domain          : $($obj.Domain)"
$output += "SerialNumber    : $($obj.SerialNumber)"
$output += "IsVirtual       : $($obj.IsVirtual)"
$output += "LastBootTime    : $($obj.LastBootTime)"
$output += "LastPatched     : $($obj.LastPatched)"
$output += "PatchWindow     : $($obj.PatchWindow)"

$output += "Tags            : "
foreach ($tag in $obj.Tags) {
    $output += "                  $tag"
}

$output += "NetworkAdapters : "
for ($i = 0; $i -lt $obj.NetworkAdapters.Count; $i++) {
    $adapter = $obj.NetworkAdapters[$i]
    $output += "                  Name        : $($adapter.Name)"
    $output += "                  MacAddress  : $($adapter.MacAddress)"
    $output += "                  IPAddress   : $($adapter.IPAddress)"
    $output += "                  VLAN        : $($adapter.VLAN)"
    $output += "                  DhcpEnabled : $($adapter.DhcpEnabled)"
    if ($i -lt $obj.NetworkAdapters.Count - 1) {
        $output += ""
    }
}

$output -join "`n"
                </ScriptBlock>
              </ExpressionBinding>
            </CustomItem>
          </CustomEntry>
        </CustomEntries>
      </CustomControl>
    </View>
  </ViewDefinitions>
</Configuration>
'@

# Load the format definition
$formatXml | Out-File -FilePath "$PScriptRoot\ServerRecord.Format.ps1xml" -Encoding UTF8
Update-FormatData -PrependPath "$PSScriptRoot\ServerRecord.Format.ps1xml"