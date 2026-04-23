# gui.ps1
# GUI for managing AD users (CRUD operations)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module ActiveDirectory

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "AD User Management Tool"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"

# Search section
$searchLabel = New-Object System.Windows.Forms.Label
$searchLabel.Location = New-Object System.Drawing.Point(10, 20)
$searchLabel.Size = New-Object System.Drawing.Size(100, 20)
$searchLabel.Text = "Search Filter:"
$form.Controls.Add($searchLabel)

$searchTextBox = New-Object System.Windows.Forms.TextBox
$searchTextBox.Location = New-Object System.Drawing.Point(120, 20)
$searchTextBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($searchTextBox)

$searchButton = New-Object System.Windows.Forms.Button
$searchButton.Location = New-Object System.Drawing.Point(330, 20)
$searchButton.Size = New-Object System.Drawing.Size(75, 23)
$searchButton.Text = "Search"
$form.Controls.Add($searchButton)

# DataGridView for results
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Location = New-Object System.Drawing.Point(10, 60)
$dataGridView.Size = New-Object System.Drawing.Size(760, 200)
$dataGridView.AutoSizeColumnsMode = "Fill"
$dataGridView.ReadOnly = $true
$form.Controls.Add($dataGridView)

# User details section
$userDetailsLabel = New-Object System.Windows.Forms.Label
$userDetailsLabel.Location = New-Object System.Drawing.Point(10, 280)
$userDetailsLabel.Size = New-Object System.Drawing.Size(100, 20)
$userDetailsLabel.Text = "User Details:"
$form.Controls.Add($userDetailsLabel)

$nameLabel = New-Object System.Windows.Forms.Label
$nameLabel.Location = New-Object System.Drawing.Point(10, 310)
$nameLabel.Size = New-Object System.Drawing.Size(80, 20)
$nameLabel.Text = "Name:"
$form.Controls.Add($nameLabel)

$nameTextBox = New-Object System.Windows.Forms.TextBox
$nameTextBox.Location = New-Object System.Drawing.Point(100, 310)
$nameTextBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($nameTextBox)

$samLabel = New-Object System.Windows.Forms.Label
$samLabel.Location = New-Object System.Drawing.Point(10, 340)
$samLabel.Size = New-Object System.Drawing.Size(80, 20)
$samLabel.Text = "Username:"
$form.Controls.Add($samLabel)

$samTextBox = New-Object System.Windows.Forms.TextBox
$samTextBox.Location = New-Object System.Drawing.Point(100, 340)
$samTextBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($samTextBox)

$upnLabel = New-Object System.Windows.Forms.Label
$upnLabel.Location = New-Object System.Drawing.Point(10, 370)
$upnLabel.Size = New-Object System.Drawing.Size(80, 20)
$upnLabel.Text = "UPN:"
$form.Controls.Add($upnLabel)

$upnTextBox = New-Object System.Windows.Forms.TextBox
$upnTextBox.Location = New-Object System.Drawing.Point(100, 370)
$upnTextBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($upnTextBox)

$passwordLabel = New-Object System.Windows.Forms.Label
$passwordLabel.Location = New-Object System.Drawing.Point(10, 400)
$passwordLabel.Size = New-Object System.Drawing.Size(80, 20)
$passwordLabel.Text = "Password:"
$form.Controls.Add($passwordLabel)

$passwordTextBox = New-Object System.Windows.Forms.TextBox
$passwordTextBox.Location = New-Object System.Drawing.Point(100, 400)
$passwordTextBox.Size = New-Object System.Drawing.Size(200, 20)
$passwordTextBox.PasswordChar = '*'
$form.Controls.Add($passwordTextBox)

# Buttons
$getButton = New-Object System.Windows.Forms.Button
$getButton.Location = New-Object System.Drawing.Point(350, 310)
$getButton.Size = New-Object System.Drawing.Size(75, 23)
$getButton.Text = "Get"
$form.Controls.Add($getButton)

$createButton = New-Object System.Windows.Forms.Button
$createButton.Location = New-Object System.Drawing.Point(350, 340)
$createButton.Size = New-Object System.Drawing.Size(75, 23)
$createButton.Text = "Create"
$form.Controls.Add($createButton)

$updateButton = New-Object System.Windows.Forms.Button
$updateButton.Location = New-Object System.Drawing.Point(350, 370)
$updateButton.Size = New-Object System.Drawing.Size(75, 23)
$updateButton.Text = "Update"
$form.Controls.Add($updateButton)

$deleteButton = New-Object System.Windows.Forms.Button
$deleteButton.Location = New-Object System.Drawing.Point(350, 400)
$deleteButton.Size = New-Object System.Drawing.Size(75, 23)
$deleteButton.Text = "Delete"
$form.Controls.Add($deleteButton)

# Clear button
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Location = New-Object System.Drawing.Point(450, 310)
$clearButton.Size = New-Object System.Drawing.Size(75, 23)
$clearButton.Text = "Clear"
$form.Controls.Add($clearButton)

# Event handlers

# Search button click event
$searchButton.Add_Click({
    $filter = $searchTextBox.Text
    if ($filter -eq "") {
        $filter = "*"
    }
    try {
        $users = Get-ADUser -Filter { Name -like $filter } -SearchBase "OU=summit-users,DC=home,DC=lab" -Properties Name, SamAccountName, UserPrincipalName, Enabled
        $dataGridView.DataSource = $null
        $dataGridView.DataSource = $users | Select-Object Name, SamAccountName, UserPrincipalName, Enabled
        $dataGridView.Refresh()
        if ($users.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No users found matching '$filter'", "No Results")
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error querying AD: $($_.Exception.Message)", "Error")
    }
})

# DataGridView selection changed event
$dataGridView.Add_SelectionChanged({
    if ($dataGridView.SelectedRows.Count -gt 0) {
        $selectedUser = $dataGridView.SelectedRows[0].DataBoundItem
        $nameTextBox.Text = $selectedUser.Name
        $samTextBox.Text = $selectedUser.SamAccountName
        $upnTextBox.Text = $selectedUser.UserPrincipalName
        $passwordTextBox.Text = ""  # Don't populate password
    }
})

# Get button click event
$getButton.Add_Click({
    $sam = $samTextBox.Text
    if ($sam -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Please enter a username to get user details.", "Input Required")
        return
    }
    try {
        $user = Get-ADUser -Identity $sam -Properties Name, SamAccountName, UserPrincipalName, Enabled
        $nameTextBox.Text = $user.Name
        $samTextBox.Text = $user.SamAccountName
        $upnTextBox.Text = $user.UserPrincipalName
        $passwordTextBox.Text = ""
        [System.Windows.Forms.MessageBox]::Show("User details loaded.", "Success")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error getting user: $($_.Exception.Message)", "Error")
    }
})

# Create button click event
$createButton.Add_Click({
    $name = $nameTextBox.Text
    $sam = $samTextBox.Text
    $upn = $upnTextBox.Text
    $password = $passwordTextBox.Text

    if ($name -eq "" -or $sam -eq "" -or $upn -eq "" -or $password -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Please fill in all fields to create a user.", "Input Required")
        return
    }

    try {
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        New-ADUser -Name $name -SamAccountName $sam -UserPrincipalName $upn -AccountPassword $securePassword -Enabled $true -Path "OU=summit-users,DC=home,DC=lab"
        [System.Windows.Forms.MessageBox]::Show("User '$sam' created successfully.", "Success")
        # Refresh the grid
        $searchButton.PerformClick()
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error creating user: $($_.Exception.Message)", "Error")
    }
})

# Update button click event
$updateButton.Add_Click({
    $sam = $samTextBox.Text
    $name = $nameTextBox.Text
    $upn = $upnTextBox.Text

    if ($sam -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Please enter a username to update.", "Input Required")
        return
    }

    try {
        $params = @{}
        if ($name -ne "") { $params.Name = $name }
        if ($upn -ne "") { $params.UserPrincipalName = $upn }

        if ($params.Count -gt 0) {
            Set-ADUser -Identity $sam @params
            [System.Windows.Forms.MessageBox]::Show("User '$sam' updated successfully.", "Success")
            # Refresh the grid
            $searchButton.PerformClick()
        } else {
            [System.Windows.Forms.MessageBox]::Show("No changes to update.", "No Changes")
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error updating user: $($_.Exception.Message)", "Error")
    }
})

# Delete button click event
$deleteButton.Add_Click({
    $sam = $samTextBox.Text
    if ($sam -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Please enter a username to delete.", "Input Required")
        return
    }

    $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to delete user '$sam'?", "Confirm Delete", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            Remove-ADUser -Identity $sam -Confirm:$false
            [System.Windows.Forms.MessageBox]::Show("User '$sam' deleted successfully.", "Success")
            # Clear fields and refresh grid
            $clearButton.PerformClick()
            $searchButton.PerformClick()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error deleting user: $($_.Exception.Message)", "Error")
        }
    }
})

# Clear button click event
$clearButton.Add_Click({
    $nameTextBox.Text = ""
    $samTextBox.Text = ""
    $upnTextBox.Text = ""
    $passwordTextBox.Text = ""
})

# Show form
$form.ShowDialog()
