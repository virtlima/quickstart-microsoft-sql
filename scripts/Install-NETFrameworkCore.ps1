[CmdletBinding()]
param(

)

try {
    Start-Transcript -Path C:\cfn\log\Install-NetFrameworkCore.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    Install-WindowsFeature NET-Framework-Core
}
catch {
    $_ | Write-AWSQuickStartException
}