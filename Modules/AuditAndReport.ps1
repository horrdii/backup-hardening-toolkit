function Run-SecurityAudit {
    $report = @()

    $defender = Get-MpComputerStatus | Select-Object -ExpandProperty AMServiceEnabled
    $firewall = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq 'True' }

    try {
        $rdpStatus = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections"
        $rdpEnabled = [bool]!( $rdpStatus.fDenyTSConnections )
    } catch {
        $rdpEnabled = "Unknown"
    }

    try {
        $bitlockerStatus = (Get-BitLockerVolume -MountPoint 'C:' -ErrorAction Stop).ProtectionStatus
    } catch {
        $bitlockerStatus = "Not Configured"
    }

    $report += "Security Audit Report"
    $report += "--------------------------"
    $report += "Windows Defender: $defender"
    $report += "Firewall Profiles Enabled: $($firewall.Count)"
    $report += "Remote Desktop: $rdpEnabled"
    $report += "BitLocker Status: $bitlockerStatus"
    $report += "Results are saved as $env:USERPROFILE\Documents\Security_Audit_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"

    $reportText = $report -join "`n"
    $reportText | Out-File "$env:USERPROFILE\Documents\Security_Audit_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
    [System.Windows.Forms.MessageBox]::Show($reportText, "Security Audit")
}
