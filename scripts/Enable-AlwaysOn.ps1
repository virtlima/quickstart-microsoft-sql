[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]$DomainNetBIOSName,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainAdminUser,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainAdminPassword,

    [Parameter(Mandatory=$true)]
    [string]$ShareName,

    [Parameter(Mandatory=$true)]
    [string]$Path,

    [Parameter(Mandatory=$false)]
    [string]$ServerName='localhost',

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

$Enable-AlwaysOn-WFCNode1={
        $ErrorActionPreference = "Stop"
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned;Enable-SqlAlwaysOn -ServerInstance $WSFCNode1NetBIOSName -Force 
    }

$Enable-AlwaysOn-WFCNode2={
        $ErrorActionPreference = "Stop"
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned;Enable-SqlAlwaysOn -ServerInstance $WSFCNode2NetBIOSName -Force 
    }

Invoke-Command -Scriptblock $Enable-AlwaysOn-WFCNode1 -ComputerName $WSFCNode1NetBIOSName -Credential $DomainAdminCreds
Invoke-Command -Scriptblock $Enable-AlwaysOn-WFCNode2 -ComputerName $WSFCNode2NetBIOSName -Credential $DomainAdminCreds

catch {
    $_ | Write-AWSQuickStartException
}