# The setup
# Requires the PSAI module and an OpenAI API or other supported AI service key
# Install-Module PSAI -Repository PSGallery
# $env:OpenAIKey = 'sk-...'

# 1. The Problem
# Inconsistent job titles are a common issue for organizations. 
$users = @'
Name,Title
Sarah Mitchell,Sr Software Eng
James Thurston,Sr. Software Eng
Linda Okafor,Sr. Software Engneer
Marcus Webb,Snr Software Engr
'@ | ConvertFrom-Csv

# 2. PSAI to the rescue
# Normalize Job Titles Agent

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

# Create Agent
$titleAgent = New-Agent -Instructions $instructions

# Test Agent
$testTitles = 'Sr Software Eng','VP of Mktg','Assoc Dir, HR Ops','Prin Arch'
$testTitles | ForEach-Object {
    $title = Get-AgentResponse -Agent $titleAgent -Prompt $_
    Write-Output "Original   : $($_)`nNormalized : $title`n"
}

# 2. Bulk normalize data
$users

# Zero matches
$users | Group-Object -Property Title -NoElement

# Lets call our agent
$users | ForEach-Object {
    $title = Get-AgentResponse -Agent $titleAgent -Prompt $_.Title
    Write-Output "Original   : $($_.Title)`nNormalized : $title`n"
    $_.Title = $title
}

# Oh yeah
$users | Group-Object -Property Title -NoElement