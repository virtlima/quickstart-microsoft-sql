[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]$DomainNetBIOSName,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainAdminUser,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainAdminPassword,

    [Parameter(Mandatory=$false)]
    [string]$ServerName='localhost',

    [Parameter(Mandatory=$true)]
    [string]$WSFCNode2NetBIOSName
    
    [Parameter(Mandatory=$true)]
    [string]$ADServer1NetBIOSName

)
try {
    Start-Transcript -Path C:\cfn\log\Set-ClusterQuorum.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    $DomainAdminFullUser = $DomainNetBIOSName + '\' + $DomainAdminUser
    $DomainAdminSecurePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
    $DomainAdminCreds = New-Object System.Management.Automation.PSCredential($DomainAdminFullUser, $DomainAdminSecurePassword)

$Set-ClusterQuorum={
        $ErrorActionPreference = "Stop"
        Set-ClusterQuorum -NodeAndFileShareMajority \\$ADServer1NetBIOSName\witness
    }

    Invoke-Command -Scriptblock $Set-ClusterQuorum -ComputerName $WSFCNode2NetBIOSName -Credential $DomainAdminCreds

}
catch {
    $_ | Write-AWSQuickStartException
}
                                            
                                         