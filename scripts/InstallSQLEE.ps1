[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]
    $FileServerNetBIOSName,

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
        $share= "//" + $Using:FileServerNetBIOSName + "/sqlinstall/"
        $fname= $share + (dir -File -Path $share *.iso)
        Mount-DiskImage -ImagePath $fname
        $driveLetter = Get-Volume | ?{$_.DriveType -eq 'CD-ROM'} | select -ExpandProperty DriveLetter
        if ($driveLetter.Count -gt 1) {
            throw "More than 1 mounted ISO found"
        }
        $installer = "$($driveLetter):\SETUP.EXE"
        if ((get-volume -DriveLetter $($driveLetter)).FileSystemLabel -eq "SQL2016_x64_ENU") {
            $ssms = $share + "SSMS-Setup-ENU.exe"
            $ssmsargs = "/quiet /norestart"
            Start-Process $ssms $ssmsargs -Wait -ErrorAction Stop -RedirectStandardOutput "C:\cfn\log\SSMSInstallerOutput.txt" -RedirectStandardError "C:\cfn\log\SSMSInstallerErrors.txt"
            $arguments =  '/Q /Action=Install /UpdateEnabled=False /Features=SQLEngine,Replication,FullText,Conn,BOL /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT="' + $Using:DomainNetBIOSName + '\' + $Using:SQLServiceAccount + '" /SQLSVCPASSWORD="' + $Using:SQLServiceAccountPassword + '" /AGTSVCACCOUNT="' + $Using:DomainNetBIOSName + '\' + $Using:SQLServiceAccount + '" /AGTSVCPASSWORD="' + $Using:SQLServiceAccountPassword + '" /SQLSYSADMINACCOUNTS="' + $Using:DomainNetBIOSName + '\' + $Using:DomainAdminUser + '" /SQLUSERDBDIR="D:\MSSQL\DATA" /SQLUSERDBLOGDIR="E:\MSSQL\LOG" /SQLBACKUPDIR="F:\MSSQL\Backup" /SQLTEMPDBDIR="F:\MSSQL\TempDB" /SQLTEMPDBLOGDIR="F:\MSSQL\TempDB" /IACCEPTSQLSERVERLICENSETERMS'
        }else{
            $arguments =  '/Q /Action=Install /UpdateEnabled=False /Features=SQLEngine,Replication,FullText,Conn,BOL,ADV_SSMS /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT="' + $Using:DomainNetBIOSName + '\' + $Using:SQLServiceAccount + '" /SQLSVCPASSWORD="' + $Using:SQLServiceAccountPassword + '" /AGTSVCACCOUNT="' + $Using:DomainNetBIOSName + '\' + $Using:SQLServiceAccount + '" /AGTSVCPASSWORD="' + $Using:SQLServiceAccountPassword + '" /SQLSYSADMINACCOUNTS="' + $Using:DomainNetBIOSName + '\' + $Using:DomainAdminUser + '" /SQLUSERDBDIR="D:\MSSQL\DATA" /SQLUSERDBLOGDIR="E:\MSSQL\LOG" /SQLBACKUPDIR="F:\MSSQL\Backup" /SQLTEMPDBDIR="F:\MSSQL\TempDB" /SQLTEMPDBLOGDIR="F:\MSSQL\TempDB" /IACCEPTSQLSERVERLICENSETERMS'
        }
        $installResult = Start-Process $installer $arguments -Wait -ErrorAction Stop -PassThru -RedirectStandardOutput "C:\cfn\log\SQLInstallerOutput.txt" -RedirectStandardError "C:\cfn\log\SQLInstallerErrors.txt"
        $exitcode=$installResult.ExitCode
        if ($exitcode -ne 0 -and $exitcode -ne 3010) {
            Throw "SQL Server install failed with exit code $exitcode, check the installer logs for more details."
        }
    }

    Invoke-Command -Authentication Credssp -Scriptblock $InstallSqlPs -ComputerName $NetBIOSName -Credential $DomainAdminCreds

}
catch {
    $_ | Write-AWSQuickStartException
}
