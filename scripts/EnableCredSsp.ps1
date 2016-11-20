[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]$DomainDNSName,

    [Parameter(Mandatory=$true)]
    [string]$ServerName
)

try {
    Start-Transcript -Path C:\cfn\log\EnableCredSsp.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    Enable-WSManCredSSP Client -DelegateComputer $ServerName -Force
    Enable-WSManCredSSP Client -DelegateComputer *.$DomainDNSName -Force
    Enable-WSManCredSSP Server -Force

    $key = 'hklm:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation'
    New-ItemProperty -Path $key -Name AllowFreshCredentialsWhenNTLMOnly -Value 1 -PropertyType Dword -Force
    New-Item -Path $key -Name 'AllowFreshCredentialsWhenNTLMOnly' -Force
    $key = Join-Path $key 'AllowFreshCredentialsWhenNTLMOnly'
    New-ItemProperty -Path $key -Name 1 -Value "WSMAN/*.$DomainDNSName" -PropertyType String -Force
    New-ItemProperty -Path $key -Name 2 -Value "WSMAN/$ServerName" -PropertyType String -Force

}
catch {
    $_ | Write-AWSQuickStartException
}
