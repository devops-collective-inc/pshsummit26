<#
.SYNOPSIS
Atomically saves text content to a file and keeps timestamped backups.

.DESCRIPTION
Writes content to a temporary file, acquires an exclusive lock on the target path,
and then moves or replaces the destination file as one operation. When replacing an
existing file, a timestamped backup is written to a backups folder next to the file.
After a successful save, only the 10 most recent backup files are retained.

.PARAMETER Path
The destination file path to write.

.PARAMETER Content
The text content to write to the destination file.

.EXAMPLE
Out-AtomicSaveWithBackup -Path '.\Atomic\MyImportantData.txt' -Content 'Updated value'

Saves the file using UTF-8 without BOM, creates a timestamped backup when replacing
an existing file, and trims older backups beyond the most recent 10.

.NOTES
Creates destination and backup directories when they do not exist.
Uses a 5-second lock acquisition timeout with 50ms retry intervals.
#>
function Out-AtomicSaveWithBackup {
    param(
        # Target file path to write or replace.
        [Parameter(Mandatory)]
        [string]$Path,

        # New text to persist to disk.
        [Parameter(Mandatory)]
        [string]$Content
    )

    # Use UTF-8 without BOM for predictable file output.
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    # Resolve the parent directory of the target file.
    $directory = Split-Path -Path $Path -Parent
    # Keep the file name separate so we can build temp and backup names.
    $fileName = [System.IO.Path]::GetFileName($Path)
    # Temp file path used for safe staged writes.
    $tempPath = Join-Path $directory "$fileName.tmp"
    # Backup folder lives beside the target file.
    $backupDir = Join-Path $directory 'backups'
    # Timestamp makes backup file names unique and sortable.
    $backupStamp = (Get-Date).ToString('yyyyMMdd_HHmmssfff')
    # Full path of the backup created during replace operations.
    $backupPath = Join-Path $backupDir "$fileName.$backupStamp.bak"
    # Stream handle used to hold an exclusive lock while replacing.
    $lockStream = $null

    # Ensure the destination directory exists.
    if (-not (Test-Path $directory)) {
        # -Force allows creation even if parts of the path already exist.
        $null = New-Item -Path $directory -ItemType Directory -Force
    }

    # Ensure the backup directory exists before any replace call.
    if (-not (Test-Path $backupDir)) {
        $null = New-Item -Path $backupDir -ItemType Directory -Force
    }

    try {
        # Stage the new content in a temp file so the target is never partially written.
        [System.IO.File]::WriteAllText($tempPath, $Content, $utf8NoBom)

        # Configure lock retry behavior for concurrent writers.
        $lockStream = $null
        # Give lock acquisition up to 5 seconds before failing.
        $timeoutMs = 5000
        # Wait 50ms between lock retries to reduce contention.
        $retryMs = 50
        # Stopwatch tracks elapsed retry time.
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        # Retry lock acquisition until timeout.
        while ($sw.ElapsedMilliseconds -lt $timeoutMs) {
            try {
                # Open target with FileShare.None for exclusive access.
                $lockStream = [System.IO.File]::Open(
                    $Path,
                    [System.IO.FileMode]::OpenOrCreate,
                    [System.IO.FileAccess]::ReadWrite,
                    [System.IO.FileShare]::None
                )
                # Lock acquired, exit retry loop.
                break
            }
            catch [System.IO.IOException] {
                # Another process is using the file, wait and try again.
                Start-Sleep -Milliseconds $retryMs
            }
        }

        # Stop if we never acquired the lock within timeout.
        if (-not $lockStream) {
            throw "Failed to acquire lock on file: $Path"
        }

        # Replace existing file atomically when present.
        if (Test-Path $Path) {
            # Replace also writes a backup of the previous file version.
            [System.IO.File]::Replace($tempPath, $Path, $backupPath)
        }
        else {
            # First write has no original file, so move temp into place.
            [System.IO.File]::Move($tempPath, $Path)
        }

        # Build pattern to find only backups for this target file.
        $backupPattern = "$fileName.*.bak"
        # Keep newest 10 backups and mark the rest for deletion.
        $oldBackups = Get-ChildItem -Path $backupDir -Filter $backupPattern -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip 10

        # Delete old backups one by one; warn instead of failing the whole save.
        foreach ($old in $oldBackups) {
            try {
                [System.IO.File]::Delete($old.FullName)
            }
            catch {
                # Non-fatal cleanup issue; warn for visibility.
                Write-Warning "Failed to delete old backup file '$($old.FullName)': $($_.Exception.Message)"
            }
        }
    }
    catch {
        # Re-throw with function context while preserving original message.
        throw "Failed to save file atomically: $($_.Exception.Message)"
    }
    finally {
        # Always release the lock handle if it was acquired.
        if ($null -ne $lockStream) {
            try {
                $lockStream.Dispose()
            }
            catch {
                # Disposal failures should be visible but not crash callers.
                Write-Warning "Failed to dispose lock stream: $($_.Exception.Message)"
            }
        }

        # Best-effort cleanup of leftover temp file.
        if (Test-Path $tempPath) {
            try {
                [System.IO.File]::Delete($tempPath)
            }
            catch {
                # Temp cleanup failure is non-fatal but useful to report.
                Write-Warning "Failed to delete temp file '$tempPath': $($_.Exception.Message)"
            }
        }
    }
}