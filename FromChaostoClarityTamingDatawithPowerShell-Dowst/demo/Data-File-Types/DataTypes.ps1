# 1. The Showdown
# Run the ServerRecord.Class.ps1 first to define the ServerRecord class and its custom format

# Our Data
$serverRecords

# 2. CSV
# Export to CSV
$serverRecords | Export-Csv '.\servers.csv' -NoTypeInformation

# Reimport data back to PowerShell
$csvData = Import-Csv '.\servers.csv'

# Display imported data
$csvData
$csvData.NetworkAdapters
$csvData.Tags

# Get Data Types
$csvData | Get-Member

# 3. JSON
# Export to JSON
$serverRecords | ConvertTo-Json -Depth 5 | Set-Content '.\servers.json'

# Reimport data back to PowerShell
$jsonData = Get-Content '.\servers.json' -Raw | ConvertFrom-Json

# Display imported data
$jsonData
$jsonData.NetworkAdapters
$jsonData.Tags

# Get Data Types
$jsonData | Get-Member

# 4. YAML
# Requires the powershell-yaml module
# Install-Module powershell-yaml -Repository PSGallery

# Export to YAML
$serverRecords | ConvertTo-Yaml | Set-Content '.\servers.yml'

# Reimport data back to PowerShell
$yamlData = Get-Content '.\servers.yml' -Raw | ConvertFrom-Yaml

# Display imported data
$yamlData

# Get Data Types
$yamlData | Get-Member

# 5. XML
# Create XML document
$xmlDoc = New-Object System.Xml.XmlDocument
$root = $xmlDoc.CreateElement('Servers')
$xmlDoc.AppendChild($root) | Out-Null
foreach ($server in $serverRecords) {
    $serverNode = $xmlDoc.CreateElement('Server')

    # Simple properties
    foreach ($prop in @(
        'ServerName','OperatingSystem','Domain','SerialNumber',
        'IsVirtual','LastBootTime','LastPatched','PatchWindow'
    )) {
        $node = $xmlDoc.CreateElement($prop)
        $node.InnerText = $server.$prop.ToString()
        $serverNode.AppendChild($node) | Out-Null
    }

    # Tags
    $tagsNode = $xmlDoc.CreateElement('Tags')
    foreach ($tag in $server.Tags) {
        $tagNode = $xmlDoc.CreateElement('Tag')
        $tagNode.InnerText = $tag
        $tagsNode.AppendChild($tagNode) | Out-Null
    }
    $serverNode.AppendChild($tagsNode) | Out-Null

    # NetworkAdapters
    $adaptersNode = $xmlDoc.CreateElement('NetworkAdapters')
    foreach ($adapter in $server.NetworkAdapters) {
        $adapterNode = $xmlDoc.CreateElement('NetworkAdapter')

        foreach ($prop in @('Name','MacAddress','IPAddress','VLAN','DhcpEnabled')) {
            $node = $xmlDoc.CreateElement($prop)
            $node.InnerText = $adapter.$prop.ToString()
            $adapterNode.AppendChild($node) | Out-Null
        }

        $adaptersNode.AppendChild($adapterNode) | Out-Null
    }
    $serverNode.AppendChild($adaptersNode) | Out-Null

    $root.AppendChild($serverNode) | Out-Null
}

# Save XML
$xmlDoc.Save('.\servers.xml') 

# Reimport data back to PowerShell
[xml]$xmlData = Get-Content '.\servers.xml'

# Display imported data
$xmlData.Servers
$xmlData.Servers.Server
$xmlData.Servers.Server.NetworkAdapters.NetworkAdapter
$xmlData.Servers.Server.Tags.Tag

# Get Data Types
$xmlData.Servers | Get-Member

# 6. CLIXML
# Export to CLIXML
$serverRecords | Export-Clixml '.\servers.cli.xml'

# Reimport data back to PowerShell
$clixmlData = Import-Clixml '.\servers.cli.xml'

# Display imported data
$clixmlData

# Get Data Types
$clixmlData | Get-Member

# 7. SQLite (MySQLite)
# Requires the MySQLite module
# Install-Module MySQLite -Repository PSGallery

# Set database file path
$dbPath = '.\servers.db'

# Export to SQLite
$serverRecords | ConvertTo-MySQLiteDB -Path $dbPath -TableName ServerRecords -TypeName ServerRecord -Force

# View database info
Get-MySQLiteDB -Path $dbPath | Format-List

# View table details
Get-MySQLiteTable -Path $dbPath -Detail

# Query the raw table data
$sqliteRaw = Invoke-MySQLiteQuery -Path $dbPath -Query 'SELECT * FROM ServerRecords'

# Display raw imported data
$sqliteRaw
$sqliteRaw.NetworkAdapters | Select-Object -First 100
$sqliteRaw | Get-Member

# Query the generated property map table
$sqlitePropertyMap = Invoke-MySQLiteQuery -Path $dbPath -Query 'SELECT * FROM propertymap_serverrecord'

# Display property map
$sqlitePropertyMap

# Restore data back to PowerShell objects
$sqliteData = ConvertFrom-MySQLiteDB -Path $dbPath -TableName ServerRecords -PropertyTable propertymap_serverrecord

# Display restored data
$sqliteData

# Get Data Types
$sqliteData | Get-Member