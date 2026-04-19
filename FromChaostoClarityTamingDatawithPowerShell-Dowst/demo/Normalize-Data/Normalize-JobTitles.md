# Normalize Data with AI

A practical guide to using the PSAI module with AI services to automatically normalize inconsistent data. This approach uses an AI agent to intelligently expand abbreviations and standardize job title formatting.

---

## Prerequisites

This script requires the PSAI module and credentials for an OpenAI API or other supported AI service.

### Module Installation

Install the required PSAI module from the PowerShell Gallery.

- **`Install-Module PSAI -Repository PSGallery`** - Installs the PSAI module, which provides PowerShell cmdlets for AI interactions.

```powershell
Install-Module PSAI -Repository PSGallery
```

### API Key Setup

Configure your AI service credentials as an environment variable. The script expects an OpenAI API key, but PSAI supports other providers.

- **`$env:OpenAIKey = 'sk-...'`** - Sets the OpenAI API key as an environment variable for authentication with OpenAI's services.

```powershell
$env:OpenAIKey = 'sk-...'
```

---

## 1. The Problem: Inconsistent Job Titles

Real-world data often contains inconsistent job title formatting due to manual entry, abbreviations, and regional variations. This section demonstrates the problem.

### Sample Data with Variations

Create a dataset of employees with inconsistently formatted job titles. The same role is represented multiple ways (Sr vs Sr. vs Snr, Eng vs Engneer).

- **`@'...`@ | ConvertFrom-Csv`** - Defines a CSV string with headers and rows, then converts it to PowerShell objects. Each row becomes an object with Name and Title properties.

```powershell
$users = @'
Name,Title
Sarah Mitchell,Sr Software Eng
James Thurston,Sr. Software Eng
Linda Okafor,Sr. Software Engneer
Marcus Webb,Snr Software Engr
'@ | ConvertFrom-Csv
```

---

## 2. Create AI Agent Instructions

Define detailed instructions for the AI agent to follow when normalizing job titles. Clear instructions are critical for consistent, predictable AI behavior.

### Job Title Normalization Instructions

Create a comprehensive instruction set that tells the AI agent exactly how to normalize job titles-what abbreviations mean, how to handle ambiguity, and formatting rules.

- **`$instructions = @"..."`** - Defines a here-string containing the complete system instructions for the AI agent. These instructions specify:
  - The agent's role and purpose (job title normalization)
  - Specific rules (expand abbreviations, preserve capitalization, return only the title)
  - A reference list of common abbreviation mappings (Sr → Senior, Mgr → Manager, etc.)

```powershell
$instructions = @"
You are a job title normalization assistant. Your sole purpose is to expand abbreviations
and standardize formatting in job titles. You do not provide explanations or commentary -
only return the normalized job title.

Rules:
- Expand ALL recognizable abbreviations to their full words, using the reference list below as a guide.
- Apply your general knowledge of professional job title conventions to expand any abbreviation not in the list.
- When an abbreviation is ambiguous, use the surrounding words in the title for context (e.g., "Eng" in an IT title = "Engineer"; in a construction title = "Engineering").
- Preserve capitalization conventions (title case).
- Do not add or remove words beyond expanding abbreviations.
- If the title is already fully spelled out, return it unchanged.
- Return only the normalized title, nothing else.

Common abbreviations to expand (not exhaustive - use your knowledge for others):
  Sr        -> Senior
  Jr        -> Junior
  Mgr       -> Manager
  Dir       -> Director
  VP        -> Vice President
  SVP       -> Senior Vice President
  EVP       -> Executive Vice President
  AVP       -> Assistant Vice President
  Exec      -> Executive
  Asst      -> Assistant
  Admin     -> Administrator
  Assoc     -> Associate
  Spec      -> Specialist
  Coord     -> Coordinator
  Rep       -> Representative
  Eng       -> Engineer
  Dev       -> Developer
  Arch      -> Architect
  Tech      -> Technician
  Ops       -> Operations
  Prin      -> Principal
  BA        -> Business Analyst
  PM        -> Project Manager
  SM        -> Scrum Master
  QA        -> Quality Assurance
  HR        -> Human Resources
  IT        -> Information Technology
  Dept      -> Department
  Intl      -> International
  Natl      -> National
  Reg       -> Regional
  Acct      -> Account
  Mktg      -> Marketing
  Svc       -> Service
  Svcs      -> Services
"@
```

---

## 3. Create and Initialize the AI Agent

Instantiate an AI agent with the defined instructions. This agent will handle all normalization requests.

### Initialize the Agent

Create an agent object that encapsulates the instructions and manages interactions with the AI service.

- **`$titleAgent = New-Agent -Instructions $instructions`** - Creates a new agent with the specified instructions. The agent will use these instructions to guide all subsequent responses.

```powershell
$titleAgent = New-Agent -Instructions $instructions
```

---

## 4. Test the Agent

Before applying the agent to the entire dataset, test it with sample titles to verify correct behavior.

### Test with Sample Titles

Provide the agent with a variety of abbreviated and malformed job titles to ensure it normalizes them correctly.

- **`$testTitles = '...'`** - Defines an array of test job titles with various abbreviations and formats.
- **`ForEach-Object { ... }`** - Iterates through each test title.
- **`Get-AgentResponse -Agent $titleAgent -Prompt $_`** - Sends the job title to the AI agent and returns the normalized response.
- **`Write-Output`** - Displays the original and normalized titles side-by-side for comparison.

```powershell
$testTitles = 'Sr Software Eng','VP of Mktg','Assoc Dir, HR Ops','Prin Arch'
$testTitles | ForEach-Object {
    $title = Get-AgentResponse -Agent $titleAgent -Prompt $_
    Write-Output "Original   : $($_)`nNormalized : $title`n"
}
```

---

## 5. Apply Normalization to All Users

After verifying the agent works correctly, apply it to the entire user dataset.

### Display Original Data

First, display the original data with inconsistent titles.

- **`$users`** - Displays all user records showing the inconsistent job titles before normalization.

```powershell
$users
```

### Check Title Variations

Identify how many different title variations exist in the dataset. This shows the extent of the inconsistency problem.

- **`Group-Object -Property Title -NoElement`** - Groups users by their Title property and displays count for each unique title. The `-NoElement` switch suppresses showing group members, showing only the title and count.

```powershell
$users | Group-Object -Property Title -NoElement
```

### Normalize All Titles

Iterate through all users and call the agent to normalize each title, updating the Title property in place.

- **`ForEach-Object { ... }`** - Processes each user object.
- **`Get-AgentResponse -Agent $titleAgent -Prompt $_.Title`** - Sends the user's current job title to the agent for normalization.
- **`$_.Title = $title`** - Updates the user's Title property with the normalized version returned by the agent.
- **`Write-Output`** - Displays before/after pairs so you can verify each normalization.

```powershell
$users | ForEach-Object {
    $title = Get-AgentResponse -Agent $titleAgent -Prompt $_.Title
    Write-Output "Original   : $($_.Title)`nNormalized : $title`n"
    $_.Title = $title
}
```

---

## 6. Verify Results

After normalization, verify that all users now have consistent, standardized job titles.

### Check Normalized Titles

Group the data again by title to confirm that the previously inconsistent titles are now consolidated into a single normalized form.

- **`Group-Object -Property Title -NoElement`** - Shows the unique normalized titles and how many users have each title. You should now see one entry (all four users with "Senior Software Engineer") instead of four different variations.

```powershell
$users | Group-Object -Property Title -NoElement
```

---

## Key Concepts

### Why Use an AI Agent?

- **Intelligent abbreviation expansion** - The AI understands context and can expand abbreviations correctly (e.g., "Eng" → "Engineer" in tech vs "Engineering" in construction)
- **Consistency** - All titles are normalized to the same standard format
- **Flexibility** - Instructions can be easily modified to match your organization's specific title conventions
- **Scalability** - Handles datasets of any size, applying the same rules uniformly

### PSAI Module Benefits

- **Natural language instructions** - Describe rules in plain English rather than complex code
- **Multiple AI providers** - Works with OpenAI, Azure OpenAI, and other supported providers
- **Pipeline-friendly** - Integrates seamlessly with PowerShell pipelines
- **Stateful agents** - Agents maintain context across multiple requests

---

## Next Steps

After normalizing job titles, you can:

- **Export to CSV** for distribution to HR or other teams
- **Update your database** with the normalized titles
- **Analyze role distribution** with consistent title grouping
- **Create reports** showing title standardization results
- **Extend the agent** with additional instructions for other data cleaning tasks
