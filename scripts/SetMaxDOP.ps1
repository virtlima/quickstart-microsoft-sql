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
    $DomainAdminPassword

)

try {
    Start-Transcript -Path C:\cfn\log\SetMaxDOP.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    $DomainAdminFullUser = $DomainNetBIOSName + '\' + $DomainAdminUser
    $DomainAdminSecurePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
    $DomainAdminCreds = New-Object System.Management.Automation.PSCredential($DomainAdminFullUser, $DomainAdminSecurePassword)

    $SetupMaxDOPPs={
        $ErrorActionPreference = "Stop"
        $sqlver = (dir -Path "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\").Name
        $maxdop = "C:\PROGRA~1\MICROS~1\CLIENT~1\ODBC\" + $sqlver + "\Tools\Binn\SQLCMD.EXE"
        $arguments = "-i c:\cfn\scripts\MaxDOP.sql"
        Start-Process $maxdop $arguments -Wait -RedirectStandardOutput "C:\cfn\log\MaxDOPOutput.txt" -RedirectStandardError "C:\cfn\log\MaxDOPErrors.txt"
    }

    Invoke-Command -Authentication Credssp -Scriptblock $SetupMaxDOPPs -ComputerName $NetBIOSName -Credential $DomainAdminCreds

}
catch {
    $_ | Write-AWSQuickStartException
}
