[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]
    $ADServerNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]
    $NetBIOSName,

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
        $share= "//" + $args[0] + "/sqlinstall/"
        $fname= $share + (dir -File -Path $share)
        Mount-DiskImage -ImagePath $fname
        $installer = "G:\SETUP.EXE"
        if ((get-volume -DriveLetter G).FileSystemLabel -eq "SQL2016_x64_ENU") {
            $arguments =  '/Q /Action=Install /UpdateEnabled=False /Features=SQLEngine,Replication,FullText,Conn,BOL /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT="' + $args[1] + '\' + $args[2] + '" /SQLSVCPASSWORD="' + $args[3] + '" /AGTSVCACCOUNT="' + $args[4] + '\' + $args[5] + '" /AGTSVCPASSWORD="' + $args[6] + '" /SQLSYSADMINACCOUNTS="' + $args[7] + '\' + $args[8] + '" /SQLUSERDBDIR="D:\MSSQL\DATA" /SQLUSERDBLOGDIR="E:\MSSQL\LOG" /SQLBACKUPDIR="F:\MSSQL\Backup" /SQLTEMPDBDIR="F:\MSSQL\TempDB" /SQLTEMPDBLOGDIR="F:\MSSQL\TempDB" /IACCEPTSQLSERVERLICENSETERMS'
        }else{
            $arguments =  '/Q /Action=Install /UpdateEnabled=False /Features=SQLEngine,Replication,FullText,Conn,BOL,ADV_SSMS /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT="' + $args[1] + '\' + $args[2] + '" /SQLSVCPASSWORD="' + $args[3] + '" /AGTSVCACCOUNT="' + $args[4] + '\' + $args[5] + '" /AGTSVCPASSWORD="' + $args[6] + '" /SQLSYSADMINACCOUNTS="' + $args[7] + '\' + $args[8] + '" /SQLUSERDBDIR="D:\MSSQL\DATA" /SQLUSERDBLOGDIR="E:\MSSQL\LOG" /SQLBACKUPDIR="F:\MSSQL\Backup" /SQLTEMPDBDIR="F:\MSSQL\TempDB" /SQLTEMPDBLOGDIR="F:\MSSQL\TempDB" /IACCEPTSQLSERVERLICENSETERMS'
        }
        Start-Process $installer $arguments -Wait -RedirectStandardOutput "C:\cfn\log\SQLInstallerOutput.txt" -RedirectStandardError "C:\cfn\log\SQLInstallerErrors.txt"
    }

    Invoke-Command -Authentication Credssp -Scriptblock $InstallSqlPs -ComputerName $NetBIOSName -Credential $DomainAdminCreds -ArgumentList $ADServerNetBIOSName,$DomainNetBIOSName,$SQLServiceAccount,$SQLServiceAccountPassword,$DomainNetBIOSName,$SQLServiceAccount,$SQLServiceAccountPassword,$DomainNetBIOSName,$DomainAdminUser

}
catch {
    $_ | Write-AWSQuickStartException
}
