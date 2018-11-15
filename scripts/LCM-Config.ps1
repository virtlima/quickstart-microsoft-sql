[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node 'localhost' {
        Settings {
            RefreshMode = 'Push'
            ActionAfterReboot = 'StopConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $false  
        }
    }
}

try {
    
    Start-Transcript -Path C:\cfn\log\$($MyInvocation.MyCommand.Name).log -Append
    
    LCMConfig -OutputPath 'C:\cfn\scripts\LCMConfig'
    
    Set-DscLocalConfigurationManager -Path 'C:\cfn\scripts\LCMConfig'
}
catch {
    $_ | Write-AWSQuickStartException
}
