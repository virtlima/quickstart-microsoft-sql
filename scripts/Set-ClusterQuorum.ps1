[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]$DomainNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$DomainAdminUser,

    [Parameter(Mandatory=$true)]
    [string]$DomainAdminPassword,

    [Parameter(Mandatory=$true)]
    [string]$WSFCNode2NetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$FileServerNetBIOSName

)
try {
    Start-Transcript -Path C:\cfn\log\Set-ClusterQuorum.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    $DomainAdminFullUser = $DomainNetBIOSName + '\' + $DomainAdminUser
    $DomainAdminSecurePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
    $DomainAdminCreds = New-Object System.Management.Automation.PSCredential($DomainAdminFullUser, $DomainAdminSecurePassword)

    $SetClusterQuorum={
        $ErrorActionPreference = "Stop"
        $ShareName = "\\" + $Using:FileServerNetBIOSName + "\witness"
        Set-ClusterQuorum -NodeAndFileShareMajority $ShareName
    }

    Invoke-Command -Scriptblock $SetClusterQuorum -ComputerName $WSFCNode2NetBIOSName -Credential $DomainAdminCreds

}
catch {
    $_ | Write-AWSQuickStartException
}
