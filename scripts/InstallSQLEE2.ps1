[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]
    $ADServerNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]    
    $DomainNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]
    $SQLServiceAccount,

    [Parameter(Mandatory=$true)]
    [string]
    $SQLServiceAccountPassword,

    [Parameter(Mandatory=$true)]
    [string]
    $DomainAdminUser,

    [Parameter(Mandatory=$true)]
    [string]
    $DomainAdminPassword

)

try {
    Start-Transcript -Path C:\cfn\log\InstallSQLEE.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    $DomainAdminFullUser = $DomainNetBIOSName + '\' + $DomainAdminUser
    $DomainAdminSecurePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
    $DomainAdminCreds = New-Object System.Management.Automation.PSCredential($DomainAdminFullUser, $DomainAdminSecurePassword)
    $InstallSqlPs={
        $ErrorActionPreference = "Stop"
        Install-WindowsFeature NET-Framework-Core
        dir \\$args[0]\sqlinstall\*.iso | Mount-DiskImage
        g:\SETUP.EXE /QS /Action=Install /Features=SQLEngine,Replication,FullText,Conn,BOL,ADV_SSMS /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT=$args[1]\$args[2] /SQLSVCPASSWORD=$args[3] /AGTSVCACCOUNT=$args[4]\$args[5] /AGTSVCPASSWORD=$args[6] /SQLSYSADMINACCOUNTS=$args[7]\$args[8] /SQLUSERDBDIR='D:\MSSQL\DATA' /SQLUSERDBLOGDIR='E:\MSSQL\LOG' /SQLBACKUPDIR='f:\MSSQL\Backup' /SQLTEMPDBDIR='f:\MSSQL\TempDB' /SQLTEMPDBLOGDIR='f:\MSSQL\TempDB' /IACCEPTSQLSERVERLICENSETERMS
        C:\PROGRA~1\MICROS~1\CLIENT~1\ODBC\110\Tools\Binn\SQLCMD.EXE -i c:\cfn\scripts\MaxDOP.sql
    }
    Invoke-Command -Scriptblock $InstallSqlPs -ComputerName localhost -Credential $DomainAdminCreds -ArgumentList $ADServerNetBIOSName,$DomainNetBIOSName,$SQLServiceAccount,$SQLServiceAccountPassword,$DomainNetBIOSName,$SQLServiceAccount,$SQLServiceAccountPassword,$DomainNetBIOSName,$DomainAdminUser

}
catch {
    $_ | Write-AWSQuickStartException
}