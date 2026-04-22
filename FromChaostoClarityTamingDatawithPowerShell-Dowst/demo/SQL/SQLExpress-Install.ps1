# Install SQL Server Express with Chocolatey.
# The -y switch automatically accepts the package prompts so the install can run unattended.
choco install sql-server-express -y

# Search the SQL Server installation folders for the sqlps module manifest file.
# We take the last match so we import the most recent version that was found.
Get-ChildItem -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server" -Recurse -Filter 'sqlps.psd1' | 
    Select-Object -ExpandProperty FullName -Last 1 |
    Foreach-Object {
        # Import the discovered SQL Server module so SMO and related commands are available.
        Import-Module $_ -ErrorAction Stop
    }

# Create a SQL Server WMI management object.
# This object gives us access to SQL Server network settings such as enabled protocols.
$wmi = New-Object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'

# Build the WMI path to the TCP protocol settings for the SQLEXPRESS instance.
$uri = "ManagedComputer[@Name='$($env:COMPUTERNAME)']/ ServerInstance[@Name='SQLEXPRESS']/ServerProtocol[@Name='Tcp']"  

# Retrieve the TCP protocol object, enable it, and save the change back to SQL Server.
# This is required to allow remote clients to connect to SQL Express using TCP/IP.
$Tcp = $wmi.GetSmoObject($uri)  
$Tcp.IsEnabled = $true  
$Tcp.Alter()

# Build the WMI path to the Named Pipes protocol settings.
$uri = "ManagedComputer[@Name='$($env:COMPUTERNAME)']/ ServerInstance[@Name='SQLEXPRESS']/ServerProtocol[@Name='Np']"  

# Retrieve the Named Pipes protocol object, enable it, and save the change.
# This is required to allow remote clients to connect to SQL Express using Named Pipes.
$Np = $wmi.GetSmoObject($uri)  
$Np.IsEnabled = $true  
$Np.Alter() 

# The TCP and Named Pipes protocol are required for remote connections, like those used by dbatools.

# Set SQL Agent and SQL Browser to start automatically with Windows.
Set-Service -Name 'SQLAgent$SQLEXPRESS' -StartupType Automatic -PassThru
Set-Service -Name 'SQLBrowser' -StartupType Automatic -PassThru

# Start SQL Browser so clients can discover named SQL instances on the machine.
Start-Service -Name 'SQLBrowser' -PassThru

# Restart the SQL Express database engine so the protocol changes take effect.
Restart-Service -Name 'MSSQL$SQLEXPRESS' -PassThru