powershell.exe -command Install-WindowsFeature NET-Framework-Core

powershell.exe -command "dir \\$ADServerNetBIOSName\sqlinstall\*.iso | Mount-DiskImage"

g:\SETUP.EXE /QS /Action=Install /Features=SQLEngine,Replication,FullText,Conn,BOL,ADV_SSMS /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT=$DomainNetBIOSName\$SQLServiceAccount /SQLSVCPASSWORD=$SQLServiceAccountPassword /AGTSVCACCOUNT=$DomainNetBIOSName\$SQLServiceAccount /AGTSVCPASSWORD=$SQLServiceAccountPassword /SQLSYSADMINACCOUNTS=$DomainNetBIOSName\$DomainAdminUser /SQLUSERDBDIR="D:\MSSQL\DATA" /SQLUSERDBLOGDIR="E:\MSSQL\LOG" /SQLBACKUPDIR="f:\MSSQL\Backup" /SQLTEMPDBDIR="f:\MSSQL\TempDB" /SQLTEMPDBLOGDIR="f:\MSSQL\TempDB" /IACCEPTSQLSERVERLICENSETERMS

C:\PROGRA~1\MICROS~1\CLIENT~1\ODBC\110\Tools\Binn\SQLCMD.EXE -i c:\cfn\scripts\MaxDOP.sql