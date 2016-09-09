[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]$DomainNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$DomainAdminUser,

    [Parameter(Mandatory=$true)]
    [string]$DomainAdminPassword,

    [Parameter(Mandatory=$true)]
    [string]$ADServer1NetBIOSName,

    [Parameter(Mandatory=$false)]
    [string]
    $WSFCNode2NetBIOSName,

    [Parameter(Mandatory=$false)]
    [string]
    $WSFCNode1NetBIOSName,

    [Parameter(Mandatory=$false)]
    [string]
    $WSFCNode1PrivateIP2,

    [Parameter(Mandatory=$false)]
    [string]
    $WSFCNode2PrivateIP2,

    [Parameter(Mandatory=$false)]
    [string]
    $NetBIOSName

)

try {
    Start-Transcript -Path C:\cfn\log\Configure-WSFC.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    $DomainAdminFullUser = $DomainNetBIOSName + '\' + $DomainAdminUser
    $DomainAdminSecurePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
    $DomainAdminCreds = New-Object System.Management.Automation.PSCredential($DomainAdminFullUser, $DomainAdminSecurePassword)

    $ConfigWSFCPs={
        New-Cluster -Name WSFCluster1 -Node $args[0], $args[1] -StaticAddress $args[2], $args[3]
    }

    Invoke-Command -Authentication Credssp -Scriptblock $ConfigWSFCPs -ComputerName $NetBIOSName -Credential $DomainAdminCreds -ArgumentList $WSFCNode1NetBIOSName,$WSFCNode2NetBIOSName,$WSFCNode1PrivateIP2,$WSFCNode2PrivateIP2
}
catch {
    $_ | Write-AWSQuickStartException
}
