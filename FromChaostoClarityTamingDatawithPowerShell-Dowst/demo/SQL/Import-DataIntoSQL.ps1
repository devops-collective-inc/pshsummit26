# Load the dbatools module so we can use its SQL Server helper commands.
Import-Module dbatools

# Tell dbatools to trust the SQL Server certificate for this session.
# This is helpful in demos or labs where SQL Express may use a self-signed certificate.
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true

# Run a SQL statement against the master database to create our demo database.
# The master database is used here because the target database does not exist yet.
# You only need to run this once. If you run it again, it will fail because the database already exists.
Invoke-DbaQuery -SqlInstance 'localhost\SQLEXPRESS' -Database master -Query 'CREATE DATABASE PowerShellDemo;'

# Build an in-memory collection of PowerShell objects that we will import into SQL.
# Each object represents one inventory record.
$data = @(
    # Create the first sample row.
    [pscustomobject]@{ ServerName='WEB01'; Environment='Prod'; Owner='Operations'; LastSeen=Get-Date }

    # Create the second sample row.
    [pscustomobject]@{ ServerName='APP01'; Environment='Test'; Owner='Dev Team';  LastSeen=Get-Date }
)

# Send the PowerShell objects to SQL Server.
# Write-DbaDbTableData maps object properties to table columns.
# -AutoCreateTable tells dbatools to create dbo.Inventory automatically if it does not already exist.
$data | Write-DbaDbTableData -SqlInstance 'localhost\SQLEXPRESS' -Database 'PowerShellDemo' -Schema dbo -Table Inventory -AutoCreateTable

# Query the table we just populated so we can verify that the import worked.
Invoke-DbaQuery -SqlInstance 'localhost\SQLEXPRESS' -Database 'PowerShellDemo' -Query 'SELECT * FROM dbo.Inventory;'