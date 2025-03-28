function Enable-SecurityFeatures {
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    [System.Windows.Forms.MessageBox]::Show("Security features enabled.", "Security")
}
