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
    
    [Parameter(Mandatory=$true)]
    [string]$SQLServiceAccount,
    


)
Try{
    Start-Transcript -Path C:\cfn\log\Set-Folder-Permissions.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    $DomainAdminFullUser = $DomainNetBIOSName + '\' + $DomainAdminUser
    $DomainAdminSecurePassword = ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force
    $DomainAdminCreds = New-Object System.Management.Automation.PSCredential($DomainAdminFullUser, $DomainAdminSecurePassword)

$SetPermissions={ 
    $ErrorActionPreference = "Stop"
    $acl = Get-Acl C:\witness;
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule( $args[0]+'\WSFCluster1$','FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'); 
    $acl.AddAccessRule($rule);
    Set-Acl C:\witness $acl
}

Invoke-Command -ScriptBlock $SetPermissions -ComputerName $ADServer1NetBIOSName -Credential $DomainAdminCreds -ArgumentList $DomainNetBIOSName

$SetPermissions2={ 
$ErrorActionPreference = "Stop"
$acl = Get-Acl C:\replica;
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule( $args[0]+'\$SQLServiceAccount','FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'); 
$acl.AddAccessRule($rule);
Set-Acl C:\replica $acl
}

Invoke-Command -ScriptBlock $SetPermissions -ComputerName $ADServer1NetBIOSName -Credential $DomainAdminCreds -ArgumentList $DomainNetBIOSName, $SQLServiceAccount
                                            
}
Catch{
     $_ | Write-AWSQuickStartException
     }
                                        