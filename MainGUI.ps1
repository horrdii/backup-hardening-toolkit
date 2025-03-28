# backup/hardening toolkit

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# modules
. "$PSScriptRoot\modules\Backup.ps1"
. "$PSScriptRoot\modules\Hardening.ps1"
. "$PSScriptRoot\modules\Restore.ps1"
. "$PSScriptRoot\modules\AuditAndReport.ps1"
. "$PSScriptRoot\modules\Schedule.ps1"

# window itself
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Backup & Hardening Toolkit'
$form.Size = New-Object System.Drawing.Size(400, 470)
$form.StartPosition = 'CenterScreen'

# progress bar
$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(50, 370)
$ProgressBar.Size = New-Object System.Drawing.Size(300, 20)
$ProgressBar.Minimum = 0
$ProgressBar.Maximum = 100
$ProgressBar.Value = 0
$form.Controls.Add($ProgressBar)

# Log file path
$LogFile = "$env:USERPROFILE\Documents\Toolkit_Log.txt"

function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

# backup
$btnBackup = New-Object System.Windows.Forms.Button
$btnBackup.Location = New-Object System.Drawing.Point(50, 30)
$btnBackup.Size = New-Object System.Drawing.Size(300, 30)
$btnBackup.Text = 'Backup Documents'
$btnBackup.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") {
        $source = $dialog.SelectedPath
        $destination = "$env:USERPROFILE\Backup_Custom"
        Backup-CustomFolder -source $source -destination $destination -progressBar $ProgressBar -form $form
        $zipPath = "$destination.zip"
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        Compress-Archive -Path $destination -DestinationPath $zipPath
        Write-Log "Backed up and zipped $source to $zipPath"
        [System.Windows.Forms.MessageBox]::Show("Backup zipped to $zipPath", "Zip Complete")
    }
})
$form.Controls.Add($btnBackup)

# security
$btnSecurity = New-Object System.Windows.Forms.Button
$btnSecurity.Location = New-Object System.Drawing.Point(50, 80)
$btnSecurity.Size = New-Object System.Drawing.Size(300, 30)
$btnSecurity.Text = 'Enable Security Features'
$btnSecurity.Add_Click({
    Enable-SecurityFeatures
    Write-Log "Enabled security features (Firewall, Defender)"
})
$form.Controls.Add($btnSecurity)

# restore point
$btnRestore = New-Object System.Windows.Forms.Button
$btnRestore.Location = New-Object System.Drawing.Point(50, 130)
$btnRestore.Size = New-Object System.Drawing.Size(300, 30)
$btnRestore.Text = 'Create Restore Point'
$btnRestore.Add_Click({
    Create-RestorePoint
    Write-Log "Attempted to create restore point"
})
$form.Controls.Add($btnRestore)

# audit
$btnAudit = New-Object System.Windows.Forms.Button
$btnAudit.Location = New-Object System.Drawing.Point(50, 180)
$btnAudit.Size = New-Object System.Drawing.Size(300, 30)
$btnAudit.Text = 'Run Security Audit'
$btnAudit.Add_Click({
    Run-SecurityAudit
    Write-Log "Ran security audit and saved report"
})
$form.Controls.Add($btnAudit)

# schedule backup
$btnSchedule = New-Object System.Windows.Forms.Button
$btnSchedule.Location = New-Object System.Drawing.Point(50, 230)
$btnSchedule.Size = New-Object System.Drawing.Size(300, 30)
$btnSchedule.Text = 'Schedule Backup'
$btnSchedule.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderDialog.ShowDialog() -eq "OK") {
        $selectedPath = $folderDialog.SelectedPath

        $timeForm = New-Object System.Windows.Forms.Form
        $timeForm.Text = "Select Backup Time"
        $timeForm.Size = New-Object System.Drawing.Size(250, 150)
        $timeForm.StartPosition = "CenterScreen"
        $timeForm.TopMost = $true

        $hourLabel = New-Object System.Windows.Forms.Label
        $hourLabel.Text = "Hour (00-23):"
        $hourLabel.Location = '10,10'
        $timeForm.Controls.Add($hourLabel)

        $hourBox = New-Object System.Windows.Forms.NumericUpDown
        $hourBox.Location = '110,10'
        $hourBox.Minimum = 0
        $hourBox.Maximum = 23
        $timeForm.Controls.Add($hourBox)

        $minuteLabel = New-Object System.Windows.Forms.Label
        $minuteLabel.Text = "Minute (00-59):"
        $minuteLabel.Location = '10,40'
        $timeForm.Controls.Add($minuteLabel)

        $minuteBox = New-Object System.Windows.Forms.NumericUpDown
        $minuteBox.Location = '110,40'
        $minuteBox.Minimum = 0
        $minuteBox.Maximum = 59
        $timeForm.Controls.Add($minuteBox)

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "OK"
        $okButton.Location = '75,70'
        $okButton.Add_Click({ $timeForm.DialogResult = 'OK'; $timeForm.Close() })
        $timeForm.Controls.Add($okButton)

        if ($timeForm.ShowDialog() -eq "OK") {
            $hour = $hourBox.Value.ToString().PadLeft(2,'0')
            $minute = $minuteBox.Value.ToString().PadLeft(2,'0')
            $time = "$hour`:$minute"
            $taskName = "ToolkitScheduledBackup"
            $scheduledScript = "$env:USERPROFILE\Documents\ScheduledBackup.ps1"
            $backupDestination = "$env:USERPROFILE\Backup_Scheduled"

            @"
`$source = '$selectedPath'
`$destination = '$backupDestination'
if (!(Test-Path `$destination)) {
    New-Item -ItemType Directory -Path `$destination | Out-Null
}
Copy-Item -Path `$source -Destination `$destination -Recurse -Force
Compress-Archive -Path `$destination -DestinationPath '${backupDestination}.zip' -Force
"@ | Out-File -FilePath $scheduledScript -Encoding utf8

            $action = "powershell.exe -ExecutionPolicy Bypass -File `"$scheduledScript`""
            schtasks /create /tn $taskName /tr $action /sc daily /st $time /f | Out-Null
            Write-Log "Scheduled backup of $selectedPath daily at $time"
            [System.Windows.Forms.MessageBox]::Show("Backup scheduled at $time for folder: $selectedPath", "Scheduled")
        }
    }
})
$form.Controls.Add($btnSchedule)

# remove scheduled backup 
$btnRemoveSchedule = New-Object System.Windows.Forms.Button
$btnRemoveSchedule.Location = New-Object System.Drawing.Point(50, 280)
$btnRemoveSchedule.Size = New-Object System.Drawing.Size(300, 30)
$btnRemoveSchedule.Text = 'Remove Scheduled Backup'
$btnRemoveSchedule.Add_Click({
    $taskName = "ToolkitScheduledBackup"
    schtasks /delete /tn $taskName /f | Out-Null
    Write-Log "Removed scheduled backup task"
    [System.Windows.Forms.MessageBox]::Show("Scheduled backup task removed.", "Task Removed")
})
$form.Controls.Add($btnRemoveSchedule)

# exit
$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Location = New-Object System.Drawing.Point(50, 320)
$btnExit.Size = New-Object System.Drawing.Size(300, 30)
$btnExit.Text = 'Exit'
$btnExit.Add_Click({
    Write-Log "User exited application"
    $form.Close()
})
$form.Controls.Add($btnExit)

# show app
$form.TopMost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
