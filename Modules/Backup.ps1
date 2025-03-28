function Backup-CustomFolder {
    param (
        [string]$source,
        [string]$destination,
        [System.Windows.Forms.ProgressBar]$progressBar,
        [System.Windows.Forms.Form]$form
    )

    if (!(Test-Path $destination)) {
        New-Item -ItemType Directory -Path $destination | Out-Null
    }

    $files = Get-ChildItem -Path $source -Recurse -File
    $total = $files.Count
    $count = 0

    foreach ($file in $files) {
        $relPath = $file.FullName.Substring($source.Length)
        $destFile = Join-Path $destination $relPath
        $destDir = Split-Path $destFile -Parent

        if (!(Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        Copy-Item -Path $file.FullName -Destination $destFile -Force
        $count++
        $progress = [math]::Round(($count / $total) * 100)
        $progressBar.Value = $progress
        $form.Refresh()
    }

    [System.Windows.Forms.MessageBox]::Show("Backup completed successfully.", "Backup")
    $progressBar.Value = 0
}
