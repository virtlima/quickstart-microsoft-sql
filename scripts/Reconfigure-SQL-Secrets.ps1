[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]$DomainNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$AdminSecret,

    [Parameter(Mandatory=$true)]
    [string]$SQLSecret

)

# Getting Password from Secrets Manager for AD Admin User
$AdminUser = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $AdminSecret).SecretString
$SQLUser = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $SQLSecret).SecretString
# Getting the Name Tag of the Instance
$NameTag = (Get-EC2Tag -Filter @{ Name="resource-id";Values=(Invoke-RestMethod -Method Get -Uri http://169.254.169.254/latest/meta-data/instance-id)}| Where-Object { $_.Key -eq "Name" })
$NetBIOSName = $NameTag.Value

try {
    Start-Transcript -Path C:\AWSQuickstart\Reconfigure-SQL.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    [array]$paths = "D:\MSSQL\DATA","E:\MSSQL\LOG","F:\MSSQL\Backup","F:\MSSQL\TempDB"
    $sqlpath = (Resolve-Path 'C:\Program Files\Microsoft SQL Server\MSSQL*.MSSQLSERVER\').Path
    $params = "-dD:\MSSQL\DATA\master.mdf;-e$sqlpath\MSSQL\Log\ERRORLOG;-lE:\MSSQL\LOG\mastlog.ldf"

    $DomainAdminFullUser = $DomainNetBIOSName + '\' + $DomainAdminUser
    $DomainAdminUser = $AdminUser.UserName
    $DomainAdminSecurePassword = ConvertTo-SecureString $AdminUser.Password -AsPlainText -Force
    $SQLAdminSecurePassword = $SQLUser.Password
    $DomainAdminCreds = New-Object System.Management.Automation.PSCredential($DomainAdminFullUser, $DomainAdminSecurePassword)

    $SQLFullUser = $DomainNetBIOSName + '\' + $SQLAdminUser
    $SQLAdminUser = $SQLUser.UserName

    $ConfigureSqlPs={
        $ErrorActionPreference = "Stop"

        # Update Startup settings with new master db path
        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement')| Out-Null
        $smowmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer localhost
        $SQLService = $smowmi.Services | where {$_.name -eq 'MSSQLSERVER'}
        $SQLService.StartupParameters = $params
        $SQLService.Alter()

        # Update paths for tempdb,model and MSDB
        Invoke-Sqlcmd -Query "USE master; ALTER DATABASE tempdb MODIFY FILE (NAME = tempdev, FILENAME = 'F:\MSSQL\TempDB\tempdb.mdf'); ALTER DATABASE tempdb MODIFY FILE (NAME = templog, FILENAME = 'F:\MSSQL\TempDB\templog.ldf');"
        Invoke-Sqlcmd -Query "USE master; ALTER DATABASE model MODIFY FILE (NAME = modeldev, FILENAME = 'D:\MSSQL\DATA\model.mdf'); ALTER DATABASE model MODIFY FILE (NAME = modellog, FILENAME = 'E:\MSSQL\LOG\modellog.ldf');"
        Invoke-Sqlcmd -Query "USE master; ALTER DATABASE MSDB MODIFY FILE (NAME = MSDBData, FILENAME = 'D:\MSSQL\DATA\MSDBData.mdf'); ALTER DATABASE MSDB MODIFY FILE (NAME = MSDBLog, FILENAME = 'E:\MSSQL\LOG\MSDBLog.ldf');"

        # Move files to new locations
        Move-Item "C:\Program Files\Microsoft SQL Server\MSSQL*.MSSQLSERVER\MSSQL\DATA\tempdb.mdf" "F:\MSSQL\TempDB\tempdb.mdf"
        Move-Item "C:\Program Files\Microsoft SQL Server\MSSQL*.MSSQLSERVER\MSSQL\DATA\templog.ldf" "F:\MSSQL\TempDB\templog.ldf"
        Move-Item "C:\Program Files\Microsoft SQL Server\MSSQL*.MSSQLSERVER\MSSQL\DATA\model.mdf" "D:\MSSQL\DATA\model.mdf"
        Move-Item "C:\Program Files\Microsoft SQL Server\MSSQL*.MSSQLSERVER\MSSQL\DATA\modellog.ldf" "E:\MSSQL\LOG\modellog.ldf"
        Move-Item "C:\Program Files\Microsoft SQL Server\MSSQL*.MSSQLSERVER\MSSQL\DATA\MSDBData.mdf" "D:\MSSQL\DATA\MSDBData.mdf"
        Move-Item "C:\Program Files\Microsoft SQL Server\MSSQL*.MSSQLSERVER\MSSQL\DATA\MSDBLog.ldf" "E:\MSSQL\LOG\MSDBLog.ldf"
        Move-Item "C:\Program Files\Microsoft SQL Server\MSSQL*.MSSQLSERVER\MSSQL\DATA\master.mdf" "D:\MSSQL\DATA\master.mdf"
        Move-Item "C:\Program Files\Microsoft SQL Server\MSSQL*.MSSQLSERVER\MSSQL\DATA\mastlog.ldf" "E:\MSSQL\LOG\mastlog.ldf"

}
catch {
    $raw = Get-Content -Path C:\AWSQuickstart\Reconfigure-SQL.ps1.txt -Raw
    Write-Host $raw
}
