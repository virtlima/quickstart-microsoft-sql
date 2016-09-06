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
    Enable-WSManCredSSP Client -DelegateComputer * -Force
    Enable-WSManCredSSP Server -Force

    $InstallSqlPs={
        Install-WindowsFeature NET-Framework-Core
        $ErrorActionPreference = "Stop"
        Enable-WSManCredSSP Server -Force
        $share= "//" + $args[0] + "/sqlinstall/"
        $fname= $share + (dir -File -Path $share)
        echo $fname
        Mount-DiskImage -ImagePath $fname
        $installer = "G:\SETUP.EXE"
        $arguments =  '/Q /Action=Install /UpdateEnabled=False /Features=SQLEngine,Replication,FullText,Conn,BOL,ADV_SSMS /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT="' + $args[1] + '\' + $args[2] + '" /SQLSVCPASSWORD="' + $args[3] + '" /AGTSVCACCOUNT="' + $args[4] + '\' + $args[5] + '" /AGTSVCPASSWORD="' + $args[6] + '" /SQLSYSADMINACCOUNTS="' + $args[7] + '\' + $args[8] + '" /SQLUSERDBDIR="D:\MSSQL\DATA" /SQLUSERDBLOGDIR="E:\MSSQL\LOG" /SQLBACKUPDIR="F:\MSSQL\Backup" /SQLTEMPDBDIR="F:\MSSQL\TempDB" /SQLTEMPDBLOGDIR="F:\MSSQL\TempDB" /IACCEPTSQLSERVERLICENSETERMS'
        echo $installer $arguments
        Start-Process $installer $arguments -Wait -RedirectStandardOutput "C:\cfn\log\SQLInstallerOutput.txt" -RedirectStandardError "C:\cfn\log\SQLInstallerErrors.txt"    
        C:\PROGRA~1\MICROS~1\CLIENT~1\ODBC\110\Tools\Binn\SQLCMD.EXE -i c:\cfn\scripts\MaxDOP.sql
    }

    Invoke-Command -Authentication Credssp -Scriptblock $InstallSqlPs -ComputerName WSFCNode11 -Credential $DomainAdminCreds -ArgumentList $ADServerNetBIOSName,$DomainNetBIOSName,$SQLServiceAccount,$SQLServiceAccountPassword,$DomainNetBIOSName,$SQLServiceAccount,$SQLServiceAccountPassword,$DomainNetBIOSName,$DomainAdminUser

}
catch {
    $_ | Write-AWSQuickStartException
}
