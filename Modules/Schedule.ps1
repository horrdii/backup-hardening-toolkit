function Schedule-Backup {
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
}

function Remove-ScheduledBackup {
    $taskName = "ToolkitScheduledBackup"
    schtasks /delete /tn $taskName /f | Out-Null
    Write-Log "Removed scheduled backup task"
    [System.Windows.Forms.MessageBox]::Show("Scheduled backup task removed.", "Task Removed")
}
