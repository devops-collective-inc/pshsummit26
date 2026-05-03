#region ---- Example 1: ValidateJsonSchema - Static Inline Schema ----

# The simplest case: hardcode the schema right into the class
# Great when the schema is small and never changes

class ValidatePotionRecipeAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $json = [string]$arguments

        $schema = @'
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "properties": {
        "name":        { "type": "string", "minLength": 1 },
        "brewer":      { "type": "string" },
        "effect":      { "type": "string" },
        "ingredients":  { "type": "array", "items": { "type": "string" }, "minItems": 1 },
        "potency":     { "type": "integer", "minimum": 1, "maximum": 10 },
        "dangerous":   { "type": "boolean" }
    },
    "required": ["name", "effect", "ingredients", "potency"],
    "additionalProperties": false
}
'@

        try {
            $isValid = $json | Test-Json -Schema $schema -ErrorAction Stop
        }
        catch {
            throw "Invalid potion recipe! $($_.Exception.Message)"
        }
    }
}

function Brew-Potion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePotionRecipe()]
        [string]$Recipe
    )
    $potion = $Recipe | ConvertFrom-Json
    "Brewing '$($potion.name)' with $($potion.ingredients.Count) ingredients... Potency: $($potion.potency)/10"
}

# Valid potion
$goodPotion = @'
{
    "name": "Felix Felicis",
    "brewer": "Horace Slughorn",
    "effect": "Liquid Luck - everything goes your way",
    "ingredients": ["Ashwinder egg", "Squill bulb", "Murtlap tentacle", "Tincture of thyme", "Occamy eggshell"],
    "potency": 9,
    "dangerous": false
}
'@

# Brew-Potion -Recipe $goodPotion  # Works!

# Missing required field 'potency'
$badPotion = @'
{
    "name": "Polyjuice Potion",
    "effect": "Transform into another person",
    "ingredients": ["Lacewing flies", "Leeches", "Powdered bicorn horn"]
}
'@

# Brew-Potion -Recipe $badPotion  # Fails! Missing 'potency'

# Wrong type for potency (string instead of integer)
$wrongType = @'
{
    "name": "Amortentia",
    "effect": "Love potion",
    "ingredients": ["Pearl dust", "Rose thorns"],
    "potency": "very strong"
}
'@

# Brew-Potion -Recipe $wrongType  # Fails! potency must be integer

# Potency out of range
$tooStrong = @'
{
    "name": "Draught of Living Death",
    "effect": "Extremely powerful sleeping potion",
    "ingredients": ["Asphodel", "Wormwood", "Valerian root", "Sopophorous bean"],
    "potency": 42
}
'@

# Brew-Potion -Recipe $tooStrong  # Fails! potency max is 10

#endregion

#region ---- Example 2: ValidateDeployConfig - Real-World Static Schema ----

class ValidateDeployConfigAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $json = [string]$arguments

        $schema = @'
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "properties": {
        "appName":     { "type": "string", "pattern": "^[a-zA-Z][a-zA-Z0-9-]{1,62}$" },
        "environment": { "type": "string", "enum": ["Dev", "Test", "Staging", "Prod"] },
        "version":     { "type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+$" },
        "replicas":    { "type": "integer", "minimum": 1, "maximum": 50 },
        "healthCheck": {
            "type": "object",
            "properties": {
                "endpoint":      { "type": "string", "pattern": "^/" },
                "intervalSec":   { "type": "integer", "minimum": 5, "maximum": 300 },
                "timeoutSec":    { "type": "integer", "minimum": 1, "maximum": 60 }
            },
            "required": ["endpoint", "intervalSec"]
        },
        "tags": {
            "type": "array",
            "items": { "type": "string" },
            "uniqueItems": true
        }
    },
    "required": ["appName", "environment", "version", "replicas"],
    "additionalProperties": false
}
'@

        try {
            $json | Test-Json -Schema $schema -ErrorAction Stop | Out-Null
        }
        catch {
            throw "Invalid deployment config! $($_.Exception.Message)"
        }
    }
}

function Start-AppDeployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateDeployConfig()]
        [string]$Config
    )
    $cfg = $Config | ConvertFrom-Json
    "Deploying $($cfg.appName) v$($cfg.version) to $($cfg.environment) with $($cfg.replicas) replicas"
}

# Valid config
$goodConfig = @'
{
    "appName": "my-web-api",
    "environment": "Prod",
    "version": "2.1.0",
    "replicas": 3,
    "healthCheck": {
        "endpoint": "/health",
        "intervalSec": 30,
        "timeoutSec": 5
    },
    "tags": ["backend", "critical"]
}
'@

# Start-AppDeployment -Config $goodConfig  # Works!

# Invalid environment
$badEnv = @'
{
    "appName": "my-web-api",
    "environment": "YOLO",
    "version": "1.0.0",
    "replicas": 2
}
'@

# Start-AppDeployment -Config $badEnv  # Fails! 'YOLO' not in enum

# Bad app name (starts with number)
$badName = @'
{
    "appName": "123-bad-name",
    "environment": "Dev",
    "version": "1.0.0",
    "replicas": 1
}
'@

# Start-AppDeployment -Config $badName  # Fails! Pattern doesn't match

# Too many replicas
$tooMany = @'
{
    "appName": "my-app",
    "environment": "Dev",
    "version": "1.0.0",
    "replicas": 9001
}
'@

# Start-AppDeployment -Config $tooMany  # Fails! Max replicas is 50

#endregion

#region ---- Example 3: ValidateJsonSchemaFile - Point to a Schema File ----

# Now the schema lives in an external file!
# Much cleaner for large schemas, and you can version them in git

class ValidateJsonSchemaFileAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [string]$SchemaPath

    ValidateJsonSchemaFileAttribute([string]$schemaPath) {
        $this.SchemaPath = $schemaPath
    }

    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $json = [string]$arguments

        if (-not (Test-Path -Path $this.SchemaPath)) {
            throw "Schema file not found: '$($this.SchemaPath)'. Cannot validate."
        }

        try {
            $json | Test-Json -SchemaFile $this.SchemaPath -ErrorAction Stop | Out-Null
        }
        catch {
            $schemaName = [System.IO.Path]::GetFileNameWithoutExtension($this.SchemaPath)
            throw "JSON does not match '$schemaName' schema! $($_.Exception.Message)"
        }
    }
}

# First, let's create some schema files to use
$characterSchema = @'
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "D&D Character",
    "type": "object",
    "properties": {
        "name":     { "type": "string", "minLength": 2 },
        "class":    { "type": "string", "enum": ["Barbarian", "Bard", "Cleric", "Druid", "Fighter", "Monk", "Paladin", "Ranger", "Rogue", "Sorcerer", "Warlock", "Wizard"] },
        "level":    { "type": "integer", "minimum": 1, "maximum": 20 },
        "race":     { "type": "string" },
        "stats": {
            "type": "object",
            "properties": {
                "strength":     { "type": "integer", "minimum": 1, "maximum": 30 },
                "dexterity":    { "type": "integer", "minimum": 1, "maximum": 30 },
                "constitution": { "type": "integer", "minimum": 1, "maximum": 30 },
                "intelligence": { "type": "integer", "minimum": 1, "maximum": 30 },
                "wisdom":       { "type": "integer", "minimum": 1, "maximum": 30 },
                "charisma":     { "type": "integer", "minimum": 1, "maximum": 30 }
            },
            "required": ["strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma"]
        }
    },
    "required": ["name", "class", "level", "race", "stats"]
}
'@

# Save schema to file (run this first!)
# $characterSchema | Set-Content -Path ".\character.schema.json" -Force

function Register-Character {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateJsonSchemaFile(".\character.schema.json")]
        [string]$CharacterJson
    )
    $char = $CharacterJson | ConvertFrom-Json
    "Registered: $($char.name) the Level $($char.level) $($char.race) $($char.class)"
}

$validCharacter = @'
{
    "name": "Drizzt Do'Urden",
    "class": "Ranger",
    "level": 15,
    "race": "Drow Elf",
    "stats": {
        "strength": 13,
        "dexterity": 20,
        "constitution": 15,
        "intelligence": 17,
        "wisdom": 17,
        "charisma": 14
    }
}
'@

# Register-Character -CharacterJson $validCharacter  # Works!

$invalidCharacter = @'
{
    "name": "Steve",
    "class": "Accountant",
    "level": 999,
    "race": "Human",
    "stats": {
        "strength": 6,
        "dexterity": 8,
        "constitution": 7,
        "intelligence": 14,
        "wisdom": 10,
        "charisma": 5
    }
}
'@

# Register-Character -CharacterJson $invalidCharacter  # Fails! 'Accountant' not a valid class, level max 20

#endregion

#region ---- Example 4: ValidateJsonSchemaUri - Load Schema from a URL ----

# Schema lives on the web! Great for shared schemas across teams,
# API contract validation, or industry-standard schemas

class ValidateJsonSchemaUriAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [string]$SchemaUri
    [int]$TimeoutSec = 10

    ValidateJsonSchemaUriAttribute([string]$schemaUri) {
        $this.SchemaUri = $schemaUri
    }

    ValidateJsonSchemaUriAttribute([string]$schemaUri, [int]$timeoutSec) {
        $this.SchemaUri = $schemaUri
        $this.TimeoutSec = $timeoutSec
    }

    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $json = [string]$arguments

        try {
            $schema = (Invoke-WebRequest -Uri $this.SchemaUri -TimeoutSec $this.TimeoutSec -ErrorAction Stop).Content
        }
        catch {
            throw "Failed to fetch schema from '$($this.SchemaUri)': $($_.Exception.Message)"
        }

        try {
            $json | Test-Json -Schema $schema -ErrorAction Stop | Out-Null
        }
        catch {
            throw "JSON does not match remote schema! $($_.Exception.Message)"
        }
    }
}

# Example: Validate against a GeoJSON schema
function Import-MapData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateJsonSchemaUri('https://geojson.org/schema/Point.json')]
        [string]$GeoJson
    )
    $geo = $GeoJson | ConvertFrom-Json
    "Imported map point: [$($geo.coordinates[1]), $($geo.coordinates[0])]"
}

$validGeoJson = @'
{
    "type": "Point",
    "coordinates": [-122.1955, 47.6101]
}
'@

# Import-MapData -GeoJson $validGeoJson  # Works! (Bellevue, WA coordinates)

$invalidGeoJson = @'
{
    "type": "Polygon",
    "coordinates": "not an array"
}
'@

# Import-MapData -GeoJson $invalidGeoJson  # Fails!

#endregion

#region ---- Example 5: ValidateJsonSchema - The Swiss Army Knife ----

# The ultimate flexible validator:
# - Inline schema string
# - File path to a .json schema
# - URL to a remote schema
# Figures out which one you gave it automatically!

class ValidateJsonSchemaAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [string]$SchemaSource

    ValidateJsonSchemaAttribute([string]$schemaSource) {
        $this.SchemaSource = $schemaSource
    }

    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $json = [string]$arguments
        $schema = $null

        # Determine the source type
        if ($this.SchemaSource -match '^https?://') {
            # It's a URL - fetch it
            try {
                $schema = (Invoke-WebRequest -Uri $this.SchemaSource -TimeoutSec 10 -ErrorAction Stop).Content
            }
            catch {
                throw "Failed to fetch schema from '$($this.SchemaSource)': $($_.Exception.Message)"
            }
        }
        elseif (Test-Path -Path $this.SchemaSource -ErrorAction SilentlyContinue) {
            # It's a file path - read it
            $schema = Get-Content -Path $this.SchemaSource -Raw -ErrorAction Stop
        }
        else {
            # Assume it's an inline schema string
            $schema = $this.SchemaSource
        }

        try {
            $json | Test-Json -Schema $schema -ErrorAction Stop | Out-Null
        }
        catch {
            throw "JSON schema validation failed! $($_.Exception.Message)"
        }
    }
}

# --- Use with inline schema ---
$pizzaOrderSchema = @'
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "properties": {
        "size":     { "type": "string", "enum": ["Small", "Medium", "Large", "Family"] },
        "crust":    { "type": "string", "enum": ["Thin", "Thick", "Stuffed", "Cauliflower"] },
        "toppings": { "type": "array", "items": { "type": "string" }, "minItems": 1, "maxItems": 8 },
        "quantity": { "type": "integer", "minimum": 1, "maximum": 20 },
        "notes":    { "type": "string", "maxLength": 200 }
    },
    "required": ["size", "crust", "toppings", "quantity"]
}
'@

function Submit-PizzaOrder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateJsonSchema('{ "$schema": "http://json-schema.org/draft-07/schema#", "type": "object", "properties": { "size": { "type": "string", "enum": ["Small", "Medium", "Large", "Family"] }, "crust": { "type": "string", "enum": ["Thin", "Thick", "Stuffed", "Cauliflower"] }, "toppings": { "type": "array", "items": { "type": "string" }, "minItems": 1, "maxItems": 8 }, "quantity": { "type": "integer", "minimum": 1, "maximum": 20 }, "notes": { "type": "string", "maxLength": 200 } }, "required": ["size", "crust", "toppings", "quantity"] }')]
        [string]$OrderJson
    )
    $order = $OrderJson | ConvertFrom-Json
    $toppingList = $order.toppings -join ', '
    "Order placed: $($order.quantity)x $($order.size) $($order.crust) crust with $toppingList"
}

$goodPizza = @'
{
    "size": "Large",
    "crust": "Thin",
    "toppings": ["Mozzarella", "Pepperoni", "Mushrooms", "Olives"],
    "quantity": 2,
    "notes": "Extra crispy please"
}
'@

# Submit-PizzaOrder -OrderJson $goodPizza  # Works!

$badPizza = @'
{
    "size": "XXXL",
    "crust": "Cardboard",
    "toppings": [],
    "quantity": 0
}
'@

# Submit-PizzaOrder -OrderJson $badPizza  # Fails! Multiple violations

# --- Use with file path ---
function Import-ServerConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateJsonSchema("$PSScriptRoot\schemas\server-config.schema.json")]
        [string]$ConfigJson
    )
    $cfg = $ConfigJson | ConvertFrom-Json
    "Loaded config for server: $($cfg.hostname)"
}

# --- Use with URL ---
function Import-GeoPoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateJsonSchema('https://geojson.org/schema/Point.json')]
        [string]$GeoJson
    )
    $point = $GeoJson | ConvertFrom-Json
    "Point imported: $($point.coordinates -join ', ')"
}

#endregion

#region ---- Example 6: ValidateJsonFile - Validate a File Path, Not a String ----

# Sometimes you don't pass JSON as a string - you pass a FILE PATH
# This validator reads the file AND validates it against a schema

class ValidateJsonFileAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [string]$SchemaSource

    ValidateJsonFileAttribute([string]$schemaSource) {
        $this.SchemaSource = $schemaSource
    }

    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $filePath = [string]$arguments

        # First, check the file exists
        if (-not (Test-Path -Path $filePath)) {
            throw "JSON file not found: '$filePath'"
        }

        # Check it's actually a .json file
        if ([System.IO.Path]::GetExtension($filePath) -ne '.json') {
            throw "Expected a .json file, got: '$([System.IO.Path]::GetExtension($filePath))'"
        }

        # Read the file
        $json = Get-Content -Path $filePath -Raw -ErrorAction Stop

        # Resolve the schema
        $schema = $null
        if ($this.SchemaSource -match '^https?://') {
            try {
                $schema = (Invoke-WebRequest -Uri $this.SchemaSource -TimeoutSec 10 -ErrorAction Stop).Content
            }
            catch {
                throw "Failed to fetch schema from '$($this.SchemaSource)': $($_.Exception.Message)"
            }
        }
        elseif (Test-Path -Path $this.SchemaSource -ErrorAction SilentlyContinue) {
            $schema = Get-Content -Path $this.SchemaSource -Raw -ErrorAction Stop
        }
        else {
            $schema = $this.SchemaSource
        }

        try {
            $json | Test-Json -Schema $schema -ErrorAction Stop | Out-Null
        }
        catch {
            throw "File '$([System.IO.Path]::GetFileName($filePath))' does not match schema! $($_.Exception.Message)"
        }
    }
}

# Validate a CI/CD pipeline config file
$pipelineSchema = @'
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "properties": {
        "pipeline":    { "type": "string" },
        "trigger":     { "type": "string", "enum": ["push", "pull_request", "schedule", "manual"] },
        "stages": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name":    { "type": "string" },
                    "image":   { "type": "string" },
                    "script":  { "type": "array", "items": { "type": "string" }, "minItems": 1 }
                },
                "required": ["name", "script"]
            },
            "minItems": 1
        }
    },
    "required": ["pipeline", "trigger", "stages"]
}
'@

function Import-PipelineConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateJsonFile('{ "$schema": "http://json-schema.org/draft-07/schema#", "type": "object", "properties": { "pipeline": { "type": "string" }, "trigger": { "type": "string", "enum": ["push", "pull_request", "schedule", "manual"] }, "stages": { "type": "array", "items": { "type": "object", "properties": { "name": { "type": "string" }, "image": { "type": "string" }, "script": { "type": "array", "items": { "type": "string" }, "minItems": 1 } }, "required": ["name", "script"] }, "minItems": 1 } }, "required": ["pipeline", "trigger", "stages"] }')]
        [string]$ConfigPath
    )
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    "Pipeline '$($config.pipeline)' loaded with $($config.stages.Count) stages (trigger: $($config.trigger))"
}

# Create a test file to try it
# @'
# {
#     "pipeline": "deploy-web-app",
#     "trigger": "push",
#     "stages": [
#         { "name": "build", "image": "mcr.microsoft.com/dotnet/sdk:8.0", "script": ["dotnet build", "dotnet test"] },
#         { "name": "deploy", "script": ["./deploy.ps1 -Environment Prod"] }
#     ]
# }
# '@ | Set-Content -Path "$PSScriptRoot\pipeline.json"

# Import-PipelineConfig -ConfigPath "$PSScriptRoot\pipeline.json"  # Works!
# Import-PipelineConfig -ConfigPath "$PSScriptRoot\demo.ps1"       # Fails! Not a .json file!
# Import-PipelineConfig -ConfigPath "$PSScriptRoot\nope.json"      # Fails! File not found!

#endregion

#region ---- Setup: Create Schema Files for File-Based Examples ----

# Run this region first to set up the schema files needed for Examples 3 and 5

$schemasDir = "$PSScriptRoot\schemas"
if (-not (Test-Path $schemasDir)) {
    New-Item -Path $schemasDir -ItemType Directory -Force | Out-Null
}

# D&D Character schema (for Example 3)
@'
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "D&D Character",
    "type": "object",
    "properties": {
        "name":     { "type": "string", "minLength": 2 },
        "class":    { "type": "string", "enum": ["Barbarian", "Bard", "Cleric", "Druid", "Fighter", "Monk", "Paladin", "Ranger", "Rogue", "Sorcerer", "Warlock", "Wizard"] },
        "level":    { "type": "integer", "minimum": 1, "maximum": 20 },
        "race":     { "type": "string" },
        "stats": {
            "type": "object",
            "properties": {
                "strength":     { "type": "integer", "minimum": 1, "maximum": 30 },
                "dexterity":    { "type": "integer", "minimum": 1, "maximum": 30 },
                "constitution": { "type": "integer", "minimum": 1, "maximum": 30 },
                "intelligence": { "type": "integer", "minimum": 1, "maximum": 30 },
                "wisdom":       { "type": "integer", "minimum": 1, "maximum": 30 },
                "charisma":     { "type": "integer", "minimum": 1, "maximum": 30 }
            },
            "required": ["strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma"]
        }
    },
    "required": ["name", "class", "level", "race", "stats"]
}
'@ | Set-Content -Path "$schemasDir\character.schema.json" -Force

# Server config schema (for Example 5)
@'
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "Server Configuration",
    "type": "object",
    "properties": {
        "hostname":    { "type": "string", "pattern": "^[a-zA-Z][a-zA-Z0-9.-]+$" },
        "ip":          { "type": "string", "format": "ipv4" },
        "port":        { "type": "integer", "minimum": 1, "maximum": 65535 },
        "environment": { "type": "string", "enum": ["Dev", "Test", "Staging", "Prod"] },
        "services":    { "type": "array", "items": { "type": "string" } },
        "monitoring":  { "type": "boolean" }
    },
    "required": ["hostname", "ip", "port", "environment"]
}
'@ | Set-Content -Path "$schemasDir\server-config.schema.json" -Force

Write-Host "Schema files created in $schemasDir" -ForegroundColor Green

#endregion
