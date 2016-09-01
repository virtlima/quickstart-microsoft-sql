[CmdletBinding()]
param(

    [Parameter(Mandatory=$false)]
    [string]
    $Source = 'C:\cfn\scripts\OpenWSFCPorts.bat',
    
)

try {
    Start-Transcript -Path C:\cfn\log\OpenWSFCPorts.ps1.txt -Append

    $ErrorActionPreference = "Stop"

	Start-Process -FilePath $Source -NoNewWindow -Wait
}
catch {
    $_ | Write-AWSQuickStartException
}