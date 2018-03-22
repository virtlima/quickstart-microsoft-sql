[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]
    $NetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]
    $DomainNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]
    $DomainAdminUser,

    [Parameter(Mandatory=$true)]
    [string]
    $DomainAdminPassword,

    [Parameter(Mandatory=$true)]
    [string]
    $SQLServiceAccount
)

try {
    Start-Transcript -Path C:\cfn\log\$($MyInvocation.MyCommand.Name).log -Append
    $ErrorActionPreference = "Stop"

    $DomainAdminFullUser = $DomainNetBIOSName + '\' + $DomainAdminUser
    $DomainAdminSecurePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
    $DomainAdminCreds = New-Object System.Management.Automation.PSCredential($DomainAdminFullUser, $DomainAdminSecurePassword)
    $SetupSAAccount={
        $sql1 = "USE [master]; CREATE LOGIN [$Using:DomainNetBIOSName\$Using:SQLServiceAccount] FROM WINDOWs;"
        $sql2 = "GO"
        $sql3 = "EXEC master..sp_addsrvrolemember @loginame = [$Using:DomainNetBIOSName\$Using:SQLServiceAccount], @rolename = 'sysadmin'; "
        Invoke-Sqlcmd -AbortOnError -ErrorAction Stop -Query $sql1
        Invoke-Sqlcmd -AbortOnError -ErrorAction Stop -Query $sql2
        Invoke-Sqlcmd -AbortOnError -ErrorAction Stop -Query $sql3
    }
    Invoke-Command -Authentication Credssp -Scriptblock $SetupSAAccount -ComputerName $NetBIOSName -Credential $DomainAdminCreds

}
catch {
    $_ | Write-AWSQuickStartException
}