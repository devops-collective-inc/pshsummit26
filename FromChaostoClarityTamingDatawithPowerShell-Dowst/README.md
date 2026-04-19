# From Chaos to Clarity: Taming Data with PowerShell

**Speaker**: Matthew Dowst

Code examples and slides from the presentation **"From Chaos to Clarity: Taming Data with PowerShell"**.

## Overview

PowerShell is more than just a scripting language; it's a robust platform for working with data from a wide range of sources. In this session, we explored how you can harness PowerShell to import, transform, analyze, and persist data effectively, empowering your automation and reporting workflows.


---

## Demo Scripts Folder Structure

### `Data-File-Types/`

Covers importing and exporting PowerShell objects across the most common data formats: **CSV, JSON, YAML, XML, CLIXML**, and **SQLite**.

| File | Description |
|------|-------------|
| `DataTypes.ps1` | Hands-on examples for each format. Exporting, reimporting, and inspecting how each format handles nested objects and type fidelity |
| `DataTypes.md` | Narrative walkthrough of every example in `DataTypes.ps1` |
| `ServerRecord.Class.ps1` | Defines the `ServerRecord` PowerShell class used as sample data throughout the examples |
| `servers.csv` / `servers.json` / `servers.xml` / `servers.yml` / `servers.cli.xml` | Pre-generated sample output files for each format |

Key takeaway: CSV flattens nested objects to strings; JSON and XML preserve structure; CLIXML round-trips full .NET types.

---

### `Shaping-Data/`

Demonstrates how to transform raw PowerShell objects into meaningful **operational views, compliance reports, and console dashboards** without leaving the shell.

| File | Description |
|------|-------------|
| `ShapingData.ps1` | Examples using `Sort-Object`, `Select-Object`, `Group-Object`, `Measure-Object`, `Format-Table`, and `Export-Csv` to produce sorted tables, environment summaries, and audit snapshots |
| `ShapingData.md` | Step-by-step guide to every shaping technique in the script |

Key takeaway: Shaping data is often about giving teams a better *view* of data, not just exporting it.

---

### `Normalize-Data/`

Shows how to use **AI (via the PSAI module)** to automatically normalize inconsistent, real-world data. Demonstrated through messy job title standardization.

| File | Description |
|------|-------------|
| `Normalize-JobTitles.ps1` | Creates an AI agent with detailed normalization instructions and pipes inconsistent titles through it to produce clean, fully-expanded equivalents |
| `Normalize-JobTitles.md` | Walkthrough covering prerequisites, agent instruction design, and result inspection |

**Prerequisites:** `PSAI` module (`Install-Module PSAI`) and an OpenAI API key set as `$env:OpenAIKey`.

Key takeaway: Prompt engineering inside PowerShell lets you apply AI normalization to any tabular dataset in a pipeline.

---

### `Data-Parser/`

A rules-driven **log normalization pipeline** that reads multi-version syslog CSVs, applies JSON-defined field mappings and severity translations, and writes a single normalized output CSV.

| File/Folder | Description |
|-------------|-------------|
| `Invoke-LogPipeline.ps1` | Orchestrates the full pipeline: discovers input files, selects the correct version mapping, applies field transforms, and writes normalized output |
| `ProcessLog.ps1` | Core log processing logic; field mapping, severity normalization, and row transformation |
| `pipeline-rules.json` | Defines which input files map to which version schema |
| `Input/` | Sample syslog files in two schema versions (`syslog_v1_sample.csv`, `syslog_v2_sample.csv`) |
| `Mappings/` | Per-version field mapping files (`syslog-v1.json`, `syslog-v2.json`) and a shared severity map (`severity-map.json`) |
| `Output/` | Destination folder for `normalized-logs.csv` |

Key takeaway: Externalizing mapping rules into JSON makes the pipeline reusable across schema versions without changing code.

---

### `SQL/`

Demonstrates writing PowerShell objects directly into **SQL Server** using the `dbatools` module, including automatic table creation.

| File | Description |
|------|-------------|
| `Import-DataIntoSQL.ps1` | Creates a demo database, builds an in-memory object collection, and uses `Write-DbaDbTableData` with `-AutoCreateTable` to import data, then queries it back with `Invoke-DbaQuery` |
| `SQLExpress-Install.ps1` | Helper script to install SQL Server Express for demo/lab environments |

**Prerequisites:** `dbatools` module (`Install-Module dbatools`) and a SQL Server Express instance at `localhost\SQLEXPRESS`.

Key takeaway: `Write-DbaDbTableData -AutoCreateTable` maps object properties to columns automatically...no schema DDL required.

---

### `Atomic-Writes/`

Provides a safe, **atomic file-write pattern** that prevents data corruption when multiple processes may write to the same file.

| File | Description |
|------|-------------|
| `Out-AtomicSave.ps1` | Writes content to a temp file in the target directory, acquires a file-based lock, then atomically moves it into place, replacing the previous file and saving it as `.bak` |
| `Out-AtomicSaveWithBackup.ps1` | Extended version that retains a timestamped backup chain |
| `MyImportantData.txt` | Sample target file used in the demos |

Key takeaway: Writing to a temp file and renaming is the safest way to avoid partial writes and file corruption in automation scripts.

---