function Create-RestorePoint {
    $restoreStatus = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    if ($restoreStatus -eq $null) {
        $ask = [System.Windows.Forms.MessageBox]::Show("System Restore is disabled. Would you like to enable it?", "System Restore Disabled", "YesNo")
        if ($ask -eq "Yes") {
            Enable-ComputerRestore -Drive "C:\"
            Set-Service -Name 'vss' -StartupType Manual
            Start-Service -Name 'vss'
            [System.Windows.Forms.MessageBox]::Show("System Restore has been enabled. You can now create restore points.", "Enabled")
        } else {
            return
        }
    }
    try {
        Checkpoint-Computer -Description "Toolkit Restore Point" -RestorePointType "MODIFY_SETTINGS"
        [System.Windows.Forms.MessageBox]::Show("Restore point created.", "System Restore")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to create restore point: $_", "Error")
    }
}
