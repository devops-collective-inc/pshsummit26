#region ---- Built-in Validation Attributes (Quick Recap) ----

# ValidateNotNullOrEmpty - the basics
function Get-User {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Username
    )
    "Looking up user: $Username"
}

Get-User -Username ''
Get-User -Username 'emrys'

# ValidateSet - static list
function Set-Environment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Dev', 'Test', 'Staging', 'Prod')]
        [string]$Environment
    )
    "Deploying to: $Environment"
}

Set-Environment -Environment 'Dev'
Set-Environment -Environment 'QA'  # Fails

# ValidatePattern - regex
function Get-Server {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^SRV-\d{3,5}$')]
        [string]$ServerName
    )
    "Connecting to: $ServerName"
}

Get-Server -ServerName 'SRV-001'
Get-Server -ServerName 'whatever'  # Ugly error message!

# ValidateScript - flexible but messy
function Get-Config {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
                if ($_ -match '^[A-Z]+-\d+$') { $true }
                else { throw "'$_' is not a valid ticket ID. Expected format: PROJ-1234" }
            })]
        [string]$TicketId
    )
    "Loading config for ticket: $TicketId"
}

Get-Config -TicketId 'PROJ-1234'
Get-Config -TicketId 'bad'  # Works but... copy-paste this to 10 functions?

#endregion

#region ---- The Problem: Why Custom Validation Classes? ----

# Imagine you have 15 functions that all need to validate a ticket ID...
# Copy-paste ValidateScript everywhere? No thanks.
# What if the format changes? Update 15 functions?
# What about friendly error messages?

# Enter: Custom Validation Attributes!

#endregion

#region ---- Anatomy of a Custom Validation Attribute ----

# The skeleton - this is ALL you need to know:

class ValidateIsNotFridayAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        # If something is wrong: throw an exception
        # If everything is fine: do nothing (return void)
        if ([datetime]$arguments -is [datetime] -and ([datetime]$arguments).DayOfWeek -eq 'Friday') {
            throw "No deployments on Fridays! '$arguments' falls on a Friday. Go home."
        }
    }
}

function New-Deployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateIsNotFriday()]
        [datetime]$ScheduledDate
    )
    "Deployment scheduled for: $ScheduledDate"
}

New-Deployment -ScheduledDate '2026-03-20'  # A Friday - DENIED!
New-Deployment -ScheduledDate '2026-03-23'  # A Monday - Welcome!

#endregion

#region ---- Example 1: ValidateTicketId (JIRA-style) ----

class ValidateTicketIdAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $ticketId = [string]$arguments

        if ([string]::IsNullOrWhiteSpace($ticketId)) {
            throw [System.ArgumentNullException]::new('TicketId', 'Ticket ID cannot be null or empty.')
        }

        # Pattern: 2-5 uppercase letters, dash, 1-6 digits (e.g., PROJ-1234, DEV-56789)
        if ($ticketId -notmatch '^[A-Z]{2,5}-\d{1,6}$') {
            throw "Invalid ticket ID: '$ticketId'. Expected format like PROJ-1234 (2-5 uppercase letters, dash, 1-6 digits)."
        }
    }
}

function Get-TicketInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateTicketId()]
        [string]$TicketId
    )
    "Fetching details for ticket: $TicketId"
}

function Close-Ticket {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateTicketId()]
        [string]$TicketId,

        [Parameter(Mandatory)]
        [string]$Reason
    )
    "Closing ticket $TicketId - Reason: $Reason"
}

Get-TicketInfo -TicketId 'PROJ-1234'
Get-TicketInfo -TicketId 'DEV-567'
Get-TicketInfo -TicketId 'nope'          # Friendly error!
Get-TicketInfo -TicketId 'toolong-1234'  # Friendly error!
Close-Ticket -TicketId 'PROJ-1234' -Reason 'Fixed'
Close-Ticket -TicketId 'garbage' -Reason 'Fixed'  # Same validation, zero duplication!

#endregion

#region ---- Example 2: ValidateSemVer (Semantic Versioning) ----

class ValidateSemVerAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $version = [string]$arguments

        if ([string]::IsNullOrWhiteSpace($version)) {
            throw [System.ArgumentNullException]::new('Version', 'Version string cannot be null or empty.')
        }

        # Remove leading 'v' if present (v1.2.3 -> 1.2.3)
        $version = $version.TrimStart('v', 'V')

        # Match semantic versioning: Major.Minor.Patch with optional pre-release
        if ($version -notmatch '^\d+\.\d+\.\d+(-[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)*)?$') {
            throw "Invalid semantic version: '$arguments'. Expected format: Major.Minor.Patch (e.g., 1.2.3, v2.0.0, 1.0.0-beta.1)"
        }

        # Extract parts and validate ranges
        $parts = $version.Split('-')[0].Split('.')
        $major = [int]$parts[0]
        $minor = [int]$parts[1]
        $patch = [int]$parts[2]

        if ($major -gt 999 -or $minor -gt 999 -or $patch -gt 999) {
            throw "Version numbers cannot exceed 999. Got: $major.$minor.$patch"
        }
    }
}

function Deploy-Module {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [ValidateSemVer()]
        [string]$Version
    )
    "Deploying $ModuleName version $Version"
}

Deploy-Module -ModuleName 'MyModule' -Version '1.2.3'
Deploy-Module -ModuleName 'MyModule' -Version 'v2.0.0'
Deploy-Module -ModuleName 'MyModule' -Version '1.0.0-beta.1'
Deploy-Module -ModuleName 'MyModule' -Version '1.0.0-rc.2'
Deploy-Module -ModuleName 'MyModule' -Version 'not.a.version'  # Fails
Deploy-Module -ModuleName 'MyModule' -Version '1.2'            # Fails - missing patch

#endregion

#region ---- Example 3: ValidateHogwartsHouse (Fun + Constructor Parameters!) ----

# What if you want the SAME validator class but with DIFFERENT allowed values?
# Constructor parameters to the rescue!

class ValidateIsOneOfAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [string[]]$AllowedValues
    [string]$ErrorContext

    ValidateIsOneOfAttribute([string[]]$allowedValues) {
        $this.AllowedValues = $allowedValues
        $this.ErrorContext = 'value'
    }

    ValidateIsOneOfAttribute([string[]]$allowedValues, [string]$errorContext) {
        $this.AllowedValues = $allowedValues
        $this.ErrorContext = $errorContext
    }

    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        if ($arguments -notin $this.AllowedValues) {
            $allowed = $this.AllowedValues -join ', '
            throw "Invalid $($this.ErrorContext): '$arguments'. Allowed values: $allowed"
        }
    }
}

function Get-HogwartsStudent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateIsOneOf(('Gryffindor', 'Hufflepuff', 'Ravenclaw', 'Slytherin'), 'Hogwarts House')]
        [string]$House
    )
    "Fetching students from $House..."
}

function Get-PizzaOrder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateIsOneOf(('Small', 'Medium', 'Large', 'Family'), 'pizza size')]
        [string]$Size,

        [Parameter(Mandatory)]
        [ValidateIsOneOf(('Margherita', 'Pepperoni', 'Hawaiian', 'Quattro Formaggi'), 'pizza type')]
        [string]$Type
    )
    "Order placed: $Size $Type pizza"
}

Get-HogwartsStudent -House 'Gryffindor'
Get-HogwartsStudent -House 'Durmstrang'  # "Invalid Hogwarts House: 'Durmstrang'"

Get-PizzaOrder -Size 'Large' -Type 'Pepperoni'
Get-PizzaOrder -Size 'Huge' -Type 'Pepperoni'   # "Invalid pizza size: 'Huge'"
Get-PizzaOrder -Size 'Large' -Type 'Anchovy'    # "Invalid pizza type: 'Anchovy'"
Get-PizzaOrder -Size 'Huge' -Type 'Anchovy'     # "Order matters: only the first parameter validation error is shown. Fix size first, then type. This keeps error messages focused and actionable."
Get-PizzaOrder -Type 'Anchovy' -Size 'Huge'     # "Order matters: only Type is validated first here, so the error is about pizza type"

# Same class, different contexts! That's the power of constructor parameters.

#endregion

#region ---- Example 4: ValidateSafeFilePath (Security!) ----

class ValidateSafeFilePathAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [string]$AllowedRoot

    ValidateSafeFilePathAttribute() {
        $this.AllowedRoot = $null  # Any path, just safety checks
    }

    ValidateSafeFilePathAttribute([string]$allowedRoot) {
        $this.AllowedRoot = $allowedRoot
    }

    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $path = [string]$arguments

        if ([string]::IsNullOrWhiteSpace($path)) {
            throw [System.ArgumentNullException]::new('Path', 'File path cannot be null or empty.')
        }

        # Block path traversal attacks
        if ($path -match '\.\.[\\/]') {
            throw "Path traversal detected in '$path'. Nice try! Relative parent paths (..) are not allowed."
        }

        # Block UNC paths (network shares)
        if ($path -match '^\\\\') {
            throw "UNC paths are not allowed: '$path'. Only local paths are permitted."
        }

        # If AllowedRoot is set, enforce it
        if ($this.AllowedRoot) {
            $resolvedPath = $engineIntrinsics.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
            $resolvedRoot = $engineIntrinsics.SessionState.Path.GetUnresolvedProviderPathFromPSPath($this.AllowedRoot)

            if (-not $resolvedPath.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Path '$path' is outside the allowed directory '$($this.AllowedRoot)'. Access denied."
            }
        }
    }
}

function Export-Report {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSafeFilePath('C:\Reports')]
        [string]$OutputPath,

        [Parameter()]
        [string]$Content = 'Sample report content'
    )
    "Exporting report to: $OutputPath"
}

function Read-ConfigFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSafeFilePath()]
        [string]$Path
    )
    "Reading config from: $Path"
}

Export-Report -OutputPath 'C:\Reports\monthly.csv'
Export-Report -OutputPath 'C:\Reports\2026\q1.csv'
Export-Report -OutputPath 'C:\Temp\sneaky.csv'             # Outside allowed root!
Export-Report -OutputPath 'C:\Reports\..\Windows\evil.exe' # Path traversal blocked!
Read-ConfigFile -Path '..\..\etc\passwd'                    # Traversal blocked!
Read-ConfigFile -Path '\\server\share\config.json'         # UNC blocked!

#endregion

#region ---- Example 5: ValidatePort (Numeric Range with Context) ----

class ValidatePortAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [bool]$AllowWellKnown = $false
    [bool]$AllowRegistered = $true
    [bool]$AllowDynamic = $true

    ValidatePortAttribute() {}

    ValidatePortAttribute([bool]$allowWellKnown) {
        $this.AllowWellKnown = $allowWellKnown
    }

    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $port = [int]$arguments

        if ($port -lt 0 -or $port -gt 65535) {
            throw "Port $port is out of range. Valid ports: 0-65535."
        }

        if ($port -le 1023 -and -not $this.AllowWellKnown) {
            throw "Port $port is a well-known port (0-1023). Use ports 1024-65535 or explicitly allow well-known ports."
        }

        if ($port -ge 1024 -and $port -le 49151 -and -not $this.AllowRegistered) {
            throw "Port $port is a registered port (1024-49151). This range is not allowed."
        }

        if ($port -ge 49152 -and -not $this.AllowDynamic) {
            throw "Port $port is a dynamic/ephemeral port (49152-65535). This range is not allowed."
        }
    }
}

function Start-WebServer {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidatePort()]  # No well-known ports by default
        [int]$Port = 8080
    )
    "Starting web server on port $Port..."
}

function Test-Connection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Hostname,

        [Parameter()]
        [ValidatePort($true)]  # Allow well-known ports (80, 443, etc.)
        [int]$Port = 443
    )
    "Testing connection to ${Hostname}:${Port}..."
}

Start-WebServer -Port 8080
Start-WebServer -Port 80       # Blocked! Well-known port
Start-WebServer -Port 70000    # Out of range!
Test-Connection -Hostname 'google.com' -Port 443   # Allowed - well-known OK here
Test-Connection -Hostname 'google.com' -Port 80    # Also allowed

#endregion

#region ---- The Trilogy: Completers + Transformers + Validators = Magic ----

# Let's combine ALL THREE from the "Pimp Your Parameters" series!
# Argument Completer: suggests valid values (tab completion)
# Transformation Attribute: converts input to the right format
# Validation Attribute: rejects bad data before the function runs

# Step 1: The Validator - ensures the environment is valid
class ValidateDeployEnvironmentAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $validEnvironments = @('Dev', 'Test', 'Staging', 'Prod')
        if ($arguments -notin $validEnvironments) {
            throw "Invalid environment: '$arguments'. Must be one of: $($validEnvironments -join ', ')"
        }
    }
}

# Step 2: The Transformer - normalizes input (dev -> Dev, PROD -> Prod)
class EnvironmentTransformationAttribute : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object]$inputData) {
        $envMap = @{
            'dev' = 'Dev'; 'development' = 'Dev'
            'test' = 'Test'; 'testing' = 'Test'; 'qa' = 'Test'
            'staging' = 'Staging'; 'stage' = 'Staging'; 'uat' = 'Staging'
            'prod' = 'Prod'; 'production' = 'Prod'; 'live' = 'Prod'
        }

        $key = ([string]$inputData).ToLower()
        if ($envMap.ContainsKey($key)) {
            return $envMap[$key]
        }
        # Return as-is and let the validator catch it
        return $inputData
    }
}

# Step 3: The Completer - tab completion for environments
$environmentCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    @('Dev', 'Test', 'Staging', 'Prod') | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Deploy to $_ environment")
    }
}

# Step 4: The Function - all three working together!
function Start-Deploy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Application,

        [Parameter(Mandatory)]
        [EnvironmentTransformation()]
        [ValidateDeployEnvironment()]
        [string]$Environment,

        [Parameter(Mandatory)]
        [ValidateSemVer()]
        [string]$Version,

        [Parameter(Mandatory)]
        [ValidateTicketId()]
        [string]$TicketId
    )
    "Deploying $Application v$Version to $Environment (Ticket: $TicketId)"
}
Register-ArgumentCompleter -CommandName Start-Deploy -ParameterName Environment -ScriptBlock $environmentCompleter

# The full trilogy in action:
# Start-Deploy -Application 'WebApp' -Version '2.1.0' -TicketId 'PROJ-4567' -Environment 'production'
# ↑ Tab completes! ↑ 'production' transforms to 'Prod'! ↑ Validated! ↑ Validated!

# Start-Deploy -Application 'WebApp' -Environment 'qa' -Version '1.0.0' -TicketId 'DEV-123'
# ↑ 'qa' transforms to 'Test'!

# Start-Deploy -Application 'WebApp' -Environment 'yolo' -Version 'nope' -TicketId 'bad'
# ↑ Everything fails with friendly messages!

#endregion

#region ---- Bonus: Using Validation Attributes on Variables ----

# You can use validation attributes on regular variables too!
# The validation runs on EVERY assignment!

[ValidateSemVer()][string]$appVersion = '1.0.0'
$appVersion  # 1.0.0

# $appVersion = '2.0.0'      # Works!
# $appVersion = 'banana'     # Fails! Validation runs on assignment!

[ValidateTicketId()][string]$currentTicket = 'PROJ-001'
$currentTicket  # PROJ-001

# $currentTicket = 'DEV-999'   # Works!
# $currentTicket = 'nope'      # Fails!

#endregion
