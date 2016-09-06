[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]$DomainNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$DomainAdminUser,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainAdminPassword,
    
    [Parameter(Mandatory=$true)]
    [string]$ADServer1NetBIOSName,
    
    


)
Try{
    Start-Transcript -Path C:\cfn\log\Set-Folder-Permissions.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    $DomainAdminFullUser = $DomainNetBIOSName + '\' + $DomainAdminUser
    $DomainAdminSecurePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
    $DomainAdminCreds = New-Object System.Management.Automation.PSCredential($DomainAdminFullUser, $DomainAdminSecurePassword)

$SetPermissions={ $acl = Get-Acl C:\witness;
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule( $args[0]+'\WSFCluster1$','FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'); 
$acl.AddAccessRule($rule);
Set-Acl C:\witness $acl
}


Invoke-Command -ScriptBlock $SetPermissions -ComputerName $ADServer1NetBIOSName -Credential $DomainAdminCreds -ArgumentList $DomainNetBIOSName
                                            
}
Catch{
     $_ | Write-AWSQuickStartException
     }
                                        