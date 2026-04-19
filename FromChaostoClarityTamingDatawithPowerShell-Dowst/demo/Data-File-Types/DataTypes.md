# PowerShell Data Types and File Formats

A non-comprehensive guide to importing and exporting PowerShell objects in various data formats: CSV, JSON, YAML, XML, CLIXML, and SQLite.

---

## Prerequisites

Before running the examples, ensure the ServerRecord class is defined by running the ServerRecord.Class.ps1 file.

---

## 1. Initial Data Display

Display the raw PowerShell objects stored in the `$serverRecords` variable to see what we're working with before conversion.

- **`$serverRecords`** - Displays the collection of ServerRecord objects with all properties in the custom formatted view.

```powershell
$serverRecords
```

---

## 2. CSV Format

CSV (Comma-Separated Values) is the most universal data format. It's simple, readable, and compatible with Excel and most data tools.

### Export to CSV

The `Export-Csv` cmdlet converts PowerShell objects into comma-separated text, with headers as the first row. The `-NoTypeInformation` flag removes PowerShell metadata, making the file compatible with other tools.

- **`Export-Csv '.\servers.csv' -NoTypeInformation`** - Exports objects to a CSV file without PowerShell type metadata headers.

```powershell
$serverRecords | Export-Csv '.\servers.csv' -NoTypeInformation
```

### Reimport CSV Data

When you import CSV data back into PowerShell, each row becomes a custom object with string properties. Complex objects like arrays are converted to comma-separated strings.

- **`Import-Csv '.\servers.csv'`** - Reads the CSV file and converts each row into a PSCustomObject with properties matching the column headers.

```powershell
$csvData = Import-Csv '.\servers.csv'
```

### Inspect CSV Data

CSV imports flatten nested structures into strings. Note that complex properties like `NetworkAdapters` and `Tags` become plain text representations, losing their original structure.

- **`$csvData`** - Displays all imported records as custom objects.
- **`$csvData.NetworkAdapters`** - Shows the flattened NetworkAdapters property (now a string, not an array of objects).
- **`$csvData.Tags`** - Shows the flattened Tags property (now a string, not an array).
- **`Get-Member`** - Lists all properties and their types; all CSV properties are strings.

```powershell
$csvData
$csvData.NetworkAdapters
$csvData.Tags
$csvData | Get-Member
```

---

## 3. JSON Format

JSON (JavaScript Object Notation) preserves the structure of nested objects and arrays. It's the modern standard for APIs and data interchange.

### Export to JSON

The `-Depth` parameter controls how many levels of nested objects are included. A depth of 5 is usually sufficient for complex nested structures.

- **`ConvertTo-Json -Depth 5`** - Converts PowerShell objects to JSON format, preserving nested object and array structures up to 5 levels deep.
- **`Set-Content '.\servers.json'`** - Writes the JSON output to a file.

```powershell
$serverRecords | ConvertTo-Json -Depth 5 | Set-Content '.\servers.json'
```

### Reimport JSON Data

JSON files can be read back into PowerShell with full object structure intact. Nested objects and arrays are restored as PSCustomObjects and arrays.

- **`Get-Content '.\servers.json' -Raw`** - Reads the entire JSON file as a single string (without `-Raw`, it would split into lines).
- **`ConvertFrom-Json`** - Converts JSON text back into PowerShell objects.

```powershell
$jsonData = Get-Content '.\servers.json' -Raw | ConvertFrom-Json
```

### Inspect JSON Data

JSON preserves nested structures, so complex properties remain as objects and arrays rather than strings.

- **`$jsonData`** - Displays all imported records as custom objects with nested structures intact.
- **`$jsonData.NetworkAdapters`** - Shows NetworkAdapters as an array of objects (not strings).
- **`$jsonData.Tags`** - Shows Tags as an array (not a string).
- **`Get-Member`** - Lists properties; nested properties retain their object types.

```powershell
$jsonData
$jsonData.NetworkAdapters
$jsonData.Tags
$jsonData | Get-Member
```

---

## 4. YAML Format

YAML (YAML Ain't Markup Language) is a human-readable data format popular in configuration management and Infrastructure as Code. It requires the `powershell-yaml` module.

### Module Installation

Install the required module from the PowerShell Gallery if not already present.

- **`Install-Module powershell-yaml -Repository PSGallery`** - Installs the YAML conversion module from PSGallery.

```powershell
# Only needed once
Install-Module powershell-yaml -Repository PSGallery
```

### Export to YAML

YAML format is highly readable and is commonly used for configuration files, Ansible playbooks, and Kubernetes definitions.

- **`ConvertTo-Yaml`** - Converts PowerShell objects to YAML format, preserving nested structures and arrays.
- **`Set-Content '.\servers.yml'`** - Writes the YAML output to a file.

```powershell
$serverRecords | ConvertTo-Yaml | Set-Content '.\servers.yml'
```

### Reimport YAML Data

YAML files can be converted back to PowerShell objects with structure preserved.

- **`Get-Content '.\servers.yml' -Raw`** - Reads the entire YAML file as a single string.
- **`ConvertFrom-Yaml`** - Converts YAML text back into PowerShell objects.

```powershell
$yamlData = Get-Content '.\servers.yml' -Raw | ConvertFrom-Yaml
```

### Inspect YAML Data

YAML preserves nested structures similar to JSON, but everything is imported as a hashtable.

- **`$yamlData`** - Displays imported records with nested structures intact.
- **`Get-Member`** - Lists properties and their types.

```powershell
$yamlData
$yamlData | Get-Member
```

---

## 5. XML Format

XML (eXtensible Markup Language) is a structured, hierarchical format suitable for complex nested data. Unlike the simple converters above, XML requires manual element creation and tree building.

### Create XML Document Structure

Building XML manually allows fine-grained control over the document structure. Each element is explicitly created and appended to the hierarchy.

- **`New-Object System.Xml.XmlDocument`** - Creates a new XML document object for building the XML tree.
- **`CreateElement('Servers')`** - Creates the root XML element named "Servers".
- **`AppendChild($root)`** - Adds the root element to the document.

```powershell
$xmlDoc = New-Object System.Xml.XmlDocument
$root = $xmlDoc.CreateElement('Servers')
$xmlDoc.AppendChild($root) | Out-Null
```

### Build XML Elements for Simple Properties

For each server, create a Server element and populate it with simple string properties.

- **`CreateElement($prop)`** - Creates an XML element with the property name.
- **`InnerText = $server.$prop.ToString()`** - Sets the element's text content to the property value.
- **`AppendChild($node)`** - Adds the element to its parent in the hierarchy.

```powershell
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
```

### Build XML Elements for Array Properties (Tags)

Array properties like Tags require special handling. Each array item becomes a child element.

- **`CreateElement('Tags')`** - Creates a parent element to group all tags.
- **`CreateElement('Tag')`** - Creates an element for each individual tag value.

```powershell
    # Tags
    $tagsNode = $xmlDoc.CreateElement('Tags')
    foreach ($tag in $server.Tags) {
        $tagNode = $xmlDoc.CreateElement('Tag')
        $tagNode.InnerText = $tag
        $tagsNode.AppendChild($tagNode) | Out-Null
    }
    $serverNode.AppendChild($tagsNode) | Out-Null
```

### Build XML Elements for Complex Objects (NetworkAdapters)

Complex nested objects like NetworkAdapters require a parent container and elements for each nested object.

- **`CreateElement('NetworkAdapters')`** - Creates a container for all network adapters.
- **`CreateElement('NetworkAdapter')`** - Creates an element for each adapter object with all its properties as child elements.

```powershell
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
```

### Save XML Document

Persist the built XML tree to a file.

- **`$xmlDoc.Save('.\servers.xml')`** - Writes the complete XML document to a file.

```powershell
$xmlDoc.Save('.\servers.xml')
```

### Reimport XML Data

XML files are read as XML document objects, allowing navigation via the document hierarchy.

- **`Get-Content '.\servers.xml'`** - Reads the XML file.
- **`[xml]`** - Casts it to an XmlDocument type for structured access via dot notation.

```powershell
[xml]$xmlData = Get-Content '.\servers.xml'
```

### Inspect XML Data

XML data is accessed through its hierarchical structure using dot notation. Properties reflect the element hierarchy.

- **`$xmlData.Servers`** - Accesses the root Servers element.
- **`$xmlData.Servers.Server`** - Lists all Server child elements.
- **`$xmlData.Servers.Server.NetworkAdapters.NetworkAdapter`** - Navigates the nested hierarchy to access individual network adapter elements.
- **`$xmlData.Servers.Server.Tags.Tag`** - Accesses all Tag child elements.
- **`Get-Member`** - Shows XML element structure and member types.

```powershell
$xmlData.Servers
$xmlData.Servers.Server
$xmlData.Servers.Server.NetworkAdapters.NetworkAdapter
$xmlData.Servers.Server.Tags.Tag
$xmlData.Servers | Get-Member
```

---

## 6. CLIXML Format

CLIXML (CLI eXtensible Markup Language) is a PowerShell-specific format that preserves the complete type information and object structure. Unlike generic XML, it can perfectly restore any PowerShell object.

### Export to CLIXML

CLIXML captures all type information, allowing complete round-trip conversion without data loss.

- **`Export-Clixml '.\servers.cli.xml'`** - Serializes PowerShell objects to CLIXML format, preserving all type information and nested structures.

```powershell
$serverRecords | Export-Clixml '.\servers.cli.xml'
```

### Reimport CLIXML Data

CLIXML can be imported back as exact copies of the original objects, with all types and nested structures intact.

- **`Import-Clixml '.\servers.cli.xml'`** - Deserializes CLIXML back into PowerShell objects with complete type fidelity.

```powershell
$clixmlData = Import-Clixml '.\servers.cli.xml'
```

### Inspect CLIXML Data

CLIXML data is restored with the same structure and types as the original, making round-trip conversions loss-free.

- **`$clixmlData`** - Displays imported records with complete object structure restored.
- **`Get-Member`** - Shows the ServerRecord type and all properties with their original types.

```powershell
$clixmlData
$clixmlData | Get-Member
```

---

## 7. SQLite Format (MySQLite)

SQLite is a lightweight, embedded relational database. The `MySQLite` module allows PowerShell objects to be stored in and queried from SQLite databases.

### Module Installation

Install the MySQLite module from the PowerShell Gallery for database functionality.

- **`Install-Module MySQLite -Repository PSGallery`** - Installs the MySQLite module for database operations.

```powershell
# Only needed once
Install-Module MySQLite -Repository PSGallery
```

### Export to SQLite

Export PowerShell objects directly to a SQLite database table with automatic schema generation.

- **`ConvertTo-MySQLiteDB -Path $dbPath -TableName ServerRecords -TypeName ServerRecord -Force`** - Creates or overwrites a SQLite table from PowerShell objects, with automatic column creation based on properties.

```powershell
$dbPath = '.\servers.db'
$serverRecords | ConvertTo-MySQLiteDB -Path $dbPath -TableName ServerRecords -TypeName ServerRecord -Force
```

### View Database Information

Inspect the SQLite database to understand its structure and contents.

- **`Get-MySQLiteDB -Path $dbPath | Format-List`** - Displays metadata about the SQLite database file and its tables.
- **`Get-MySQLiteTable -Path $dbPath -Detail`** - Lists all tables with detailed information about columns, types, and row counts.

```powershell
Get-MySQLiteDB -Path $dbPath | Format-List
Get-MySQLiteTable -Path $dbPath -Detail
```

### Query Raw Table Data

Execute SQL queries against the database to retrieve raw data without object restoration.

- **`Invoke-MySQLiteQuery -Path $dbPath -Query 'SELECT * FROM ServerRecords'`** - Executes a SQL query and returns flat table data.

```powershell
$sqliteRaw = Invoke-MySQLiteQuery -Path $dbPath -Query 'SELECT * FROM ServerRecords'
```

### Inspect Raw Data

Raw database data is flattened into simple objects with string and numeric properties.

- **`$sqliteRaw`** - Displays all records as flat objects with basic properties.
- **`$sqliteRaw.NetworkAdapters | Select-Object -First 100`** - Shows how nested properties are stored (typically as serialized JSON or strings in the database).
- **`Get-Member`** - Shows the basic property types returned from the database query.

```powershell
$sqliteRaw
$sqliteRaw.NetworkAdapters | Select-Object -First 100
$sqliteRaw | Get-Member
```

### Query Property Map

MySQLite creates a property map table to store information about original PowerShell type properties and how they were serialized.

- **`Invoke-MySQLiteQuery -Path $dbPath -Query 'SELECT * FROM propertymap_serverrecord'`** - Retrieves the metadata table that maps database columns back to original PowerShell properties.

```powershell
$sqlitePropertyMap = Invoke-MySQLiteQuery -Path $dbPath -Query 'SELECT * FROM propertymap_serverrecord'
$sqlitePropertyMap
```

### Restore Objects from SQLite

Convert the raw database data back into fully-typed PowerShell objects using the property map.

- **`ConvertFrom-MySQLiteDB -Path $dbPath -TableName ServerRecords -PropertyTable propertymap_serverrecord`** - Deserializes database data back into original PowerShell objects with correct types, recreating nested objects and arrays.

```powershell
$sqliteData = ConvertFrom-MySQLiteDB -Path $dbPath -TableName ServerRecords -PropertyTable propertymap_serverrecord
```

### Inspect Restored Data

Restored data should match the original object structure with all types and nested objects intact.

- **`$sqliteData`** - Displays records fully restored as ServerRecord objects.
- **`Get-Member`** - Shows the ServerRecord type with all original properties and types.

```powershell
$sqliteData
$sqliteData | Get-Member
```

---

## Format Comparison Summary

| Format | Use Case | Nested Objects | Human Readable | Database Query |
|--------|----------|----------------|-----------------|---|
| **CSV** | Excel, reports, simple data | ❌ Flattened | ✅ Yes | ❌ No |
| **JSON** | APIs, modern tools, web | ✅ Preserved | ✅ Yes | ❌ No |
| **YAML** | Config files, IaC, Ansible | ✅ Preserved | ✅ Very readable | ❌ No |
| **XML** | Enterprise systems, SOAP | ✅ Preserved | ✅ Yes | ❌ No |
| **CLIXML** | PowerShell pipelines, backup | ✅ Perfect | ❌ No | ❌ No |
| **SQLite** | Relational queries, storage | ✅ Restored | ❌ No | ✅ Yes |

---

## Key Takeaways

- **CSV** is best for simple data and universal compatibility (but loses structure)
- **JSON** is ideal for APIs and modern web applications
- **YAML** excels for human-readable configuration and Infrastructure as Code
- **XML** is suitable for enterprise integrations
- **CLIXML** ensures perfect round-trip PowerShell object preservation. No use outside of PowerShell.
- **SQLite** enables relational queries and efficient data storage with full restoration capability
