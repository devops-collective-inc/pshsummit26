<#
.SYNOPSIS
Atomically writes text content to a file.

.DESCRIPTION
Writes content to a temporary file in the target directory, acquires a file-based lock,
and then moves or replaces the target file in a single operation. If the target exists,
the previous file is saved as a .bak backup.

.PARAMETER Path
Destination file path to write.

.PARAMETER Content
Text content to write to the destination file.

.EXAMPLE
Out-AtomicSave -Path '.\output\MyImportantData.txt' -Content 'Hello world'

Writes UTF-8 (without BOM) text to the file using an atomic replace/move pattern.

.NOTES
Creates the destination directory if it does not exist.
Uses a temporary .tmp file and a .lock file during the write operation.
#>
function Out-AtomicSave {
    param(
        # Final destination path for the file we want to save.
        [string]$Path,
        # Text payload to write into the file.
        [string]$Content
    )

    # Split the destination path so we can work with the directory and file name separately.
    $directory  = Split-Path -Path $Path -Parent
    # Extract only the file name (without directory) from the target path.
    $fileName   = [System.IO.Path]::GetFileName($Path)
    # Build a temporary file path in the same directory so move/replace stays on the same volume.
    $tempPath   = Join-Path $directory "$fileName.tmp"
    # Build a lock file path to coordinate writes across multiple callers.
    $lockPath   = Join-Path $directory "$fileName.lock"
    # Holds the open lock file stream when lock acquisition succeeds.
    $lockStream = $null
    # Use UTF-8 without BOM for consistent output encoding.
    $utf8NoBom  = [System.Text.UTF8Encoding]::new($false)

    # Ensure the destination directory exists before any file operations.
    if (-not (Test-Path $directory)) {
        # Create the directory (and any missing parents) if needed.
        $null = New-Item -Path $directory -ItemType Directory -Force
    }

    try {
        # Write content to a temp file first so the destination file is not partially written.
        [System.IO.File]::WriteAllText($tempPath, $Content, $utf8NoBom)

        # Keep retrying until we can acquire an exclusive lock on the lock file.
        do {
            try {
                # Open or create the lock file with FileShare.None to block concurrent writers.
                $lockStream = [System.IO.File]::Open(
                    $lockPath,
                    [System.IO.FileMode]::OpenOrCreate,
                    [System.IO.FileAccess]::ReadWrite,
                    [System.IO.FileShare]::None
                )
            }
            catch [System.IO.IOException] {
                # Another process is likely holding the lock; wait briefly and retry.
                Start-Sleep -Milliseconds 50
            }
        } until ($lockStream)

        # If the destination exists, atomically replace it and keep a backup copy.
        if (Test-Path $Path) {
            [System.IO.File]::Replace($tempPath, $Path, "$Path.bak")
        }
        else {
            # If no destination exists yet, move temp file into place.
            [System.IO.File]::Move($tempPath, $Path)
        }
    }
    finally {
        # Release the lock handle so other writers can continue.
        if ($lockStream) { $lockStream.Dispose() }
        # Remove the lock file if present.
        if (Test-Path $lockPath) { Remove-Item $lockPath -Force -ErrorAction SilentlyContinue }
        # Remove leftover temp file if an error occurred before final move/replace.
        if (Test-Path $tempPath) { Remove-Item $tempPath -Force -ErrorAction SilentlyContinue }
    }
}