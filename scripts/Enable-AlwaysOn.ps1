[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]$DomainNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$DomainAdminUser,

    [Parameter(Mandatory=$true)]
    [string]$DomainAdminPassword,

    [Parameter(Mandatory=$true)]
    [string]$WSFCNode1NetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$WSFCNode2NetBIOSName

)
try {
    Start-Transcript -Path C:\cfn\log\Enable-SqlAlwaysOn.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    $DomainAdminFullUser = $DomainNetBIOSName + '\' + $DomainAdminUser
    $DomainAdminSecurePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
    $DomainAdminCreds = New-Object System.Management.Automation.PSCredential($DomainAdminFullUser, $DomainAdminSecurePassword)

    $EnableAlwaysOnPs={
        $ErrorActionPreference = "Stop"
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
        Enable-SqlAlwaysOn -ServerInstance $Using:serverInstance -Force
    }
    
    $serverInstance = $WSFCNode1NetBIOSName
    Invoke-Command -Scriptblock $EnableAlwaysOnPs -ComputerName $WSFCNode1NetBIOSName -Credential $DomainAdminCreds
    $serverInstance = $WSFCNode2NetBIOSName
    Invoke-Command -Scriptblock $EnableAlwaysOnPs -ComputerName $WSFCNode2NetBIOSName -Credential $DomainAdminCreds
}
catch {
    $_ | Write-AWSQuickStartException
}
