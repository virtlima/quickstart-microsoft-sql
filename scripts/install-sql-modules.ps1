[CmdletBinding()]
param()

try {
    Start-Transcript -Path C:\cfn\log\install-sql-modules.txt -Append
    $ErrorActionPreference = "Stop"
    
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name SqlServerDsc
    Install-Module -Name "xActiveDirectory"
    Install-Module SqlServer -Force -AllowClobber

}
catch {
    $_ | Write-AWSQuickStartException
}