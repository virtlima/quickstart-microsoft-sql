param(

	[Parameter(Mandatory=$True)]
	[string]
	$ServerName,

	[Parameter(Mandatory=$True)]
	[string]
	$GroupName,

	[Parameter(Mandatory=$True)]
	[string]
	$DomainNetBIOSName,

	[Parameter(Mandatory=$True)]
	[string]
	$UserName

)

try {
    Start-Transcript -Path C:\cfn\log\AddUserToGroup.ps1.txt -Append

    $ErrorActionPreference = "Stop"

	$de = [ADSI]"WinNT://$ServerName/$GroupName,group"
	$de.psbase.Invoke("Add",([ADSI]"WinNT://$DomainNetBIOSName/$UserName").path)

}
catch {
    Write-Verbose "$($_.exception.message)@ $(Get-Date)"
    $_ | Write-AWSQuickStartException
}