[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]$DomainNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$DomainDNSName,

    [Parameter(Mandatory=$true)]
    [string]$DomainAdminUser,

    [Parameter(Mandatory=$true)]
    [string]$DomainAdminPassword,

    [Parameter(Mandatory=$true)]
    [string]$WSFCNode1NetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$WSFCNode2NetBIOSName,

    [Parameter(Mandatory=$false)]
    [string]$WSFCNode3NetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$SQLServiceAccount,

    [Parameter(Mandatory=$true)]
    [string]$SQLServiceAccountPassword,

    [Parameter(Mandatory=$true)]
    [string]$AGListener1PrivateIP1,

    [Parameter(Mandatory=$true)]
    [string]$AGListener1PrivateIP2,

    [Parameter(Mandatory=$false)]
    [string]$AGListener1PrivateIP3,

    [Parameter(Mandatory=$false)]
    [string] $ManagedAD

)

Function Get-Domain {
	
	#Retrieve the Fully Qualified Domain Name if one is not supplied
	# division.domain.root
	if ($DomainDNSName -eq "") {
		[String]$DomainDNSName = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()
	}

	# Create an Array 'Item' for each item in between the '.' characters
	$FQDNArray = $DomainDNSName.split(".")
	
	# Add A Separator of ','
	$Separator = ","

	# For Each Item in the Array
	# for (CreateVar; Condition; RepeatAction)
	# for ($x is now equal to 0; while $x is less than total array length; add 1 to X
	for ($x = 0; $x -lt $FQDNArray.Length ; $x++)
		{ 

		#If it's the last item in the array don't append a ','
		if ($x -eq ($FQDNArray.Length - 1)) { $Separator = "" }
		
		# Append to $DN DC= plus the array item with a separator after
		[string]$DN += "DC=" + $FQDNArray[$x] + $Separator
		
		# continue to next item in the array
		}
	
	#return the Distinguished Name
	return $DN
}

Function Convert-CidrtoSubnetMask { 
    Param ( 
        [String] $SubnetMaskCidr
    ) 

    Function Convert-Int64ToIpAddress() { 
      Param 
      ( 
          [int64] 
          $Int64 
      ) 
   
      # Return 
      '{0}.{1}.{2}.{3}' -f ([math]::Truncate($Int64 / 16777216)).ToString(), 
          ([math]::Truncate(($Int64 % 16777216) / 65536)).ToString(), 
          ([math]::Truncate(($Int64 % 65536)/256)).ToString(), 
          ([math]::Truncate($Int64 % 256)).ToString() 
    } 
 
    # Return
    Convert-Int64ToIpAddress -Int64 ([convert]::ToInt64(('1' * $SubnetMaskCidr + '0' * (32 - $SubnetMaskCidr)), 2)) 
}

Function Get-CIDR {
    Param ( 
        [String] $Target
    ) 
    Invoke-Command -ComputerName $Target -Credential $Credentials -Scriptblock {(Get-NetIPConfiguration).IPv4Address.PrefixLength[0]}
}

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName     = '*'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
            InstanceName         = 'MSSQLSERVER'
            AvailabilityGroupName = 'SQLAG1'
            ProcessOnlyOnActiveNode = $true
        },
        @{
            NodeName = $WSFCNode1NetBIOSName
            Role = 'PrimaryReplica'
        }
        @{
            NodeName = $WSFCNode2NetBIOSName
            Role = 'SecondaryReplica'
        }
        if ($WSFCNode3NetBIOSName) {
            @{
                NodeName = $WSFCNode3NetBIOSName
                Role = 'TertiaryReplica'
            }
        }
    )
}

Configuration AddAG {
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]$SQLCredentials,

        [Parameter(Mandatory = $true)]
        [PSCredential]$Credentials
    )

    Import-Module -Name PSDesiredStateConfiguration
    Import-Module -Name xActiveDirectory
    Import-Module -Name SqlServerDsc
    
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xActiveDirectory
    Import-DscResource -Module SqlServerDsc

    Node $AllNodes.NodeName {
        SqlServerLogin AddNTServiceClusSvc {
            Ensure               = 'Present'
            Name                 = 'NT SERVICE\ClusSvc'
            LoginType            = 'WindowsUser'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.InstanceName
            PsDscRunAsCredential = $SQLCredentials
        }

        SqlServerPermission AddNTServiceClusSvcPermissions {
            DependsOn            = '[SqlServerLogin]AddNTServiceClusSvc'
            Ensure               = 'Present'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.InstanceName
            Principal            = 'NT SERVICE\ClusSvc'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'
            PsDscRunAsCredential = $SQLCredentials
        }

        SqlServerEndpoint HADREndpoint {
            EndPointName         = 'HADR'
            Ensure               = 'Present'
            Port                 = 5022
            ServerName           = $Node.NodeName
            InstanceName         = $Node.InstanceName
            PsDscRunAsCredential = $SQLCredentials
        }

        SqlAlwaysOnService EnableHADR {
            Ensure               = 'Present'
            InstanceName         = $Node.InstanceName
            ServerName           = $Node.NodeName
            PsDscRunAsCredential = $SQLCredentials
        }
        
        if ( $Node.Role -eq 'PrimaryReplica' ) {
            if ($ManagedAD -eq 'Yes'){
                
                WindowsFeature RSAT-ADDS-Tools {
                    Name = 'RSAT-ADDS-Tools'
                    Ensure = 'Present'
                }
    
                xADObjectPermissionEntry ADObjectPermissionEntry {
                    Ensure                             = 'Present'
                    Path                               = $OUPath
                    IdentityReference                  = $IdentityReference
                    ActiveDirectoryRights              = 'GenericAll'
                    AccessControlType                  = 'Allow'
                    ObjectType                         = '00000000-0000-0000-0000-000000000000'
                    ActiveDirectorySecurityInheritance = 'All'
                    InheritedObjectType                = '00000000-0000-0000-0000-000000000000'
                    PsDscRunAsCredential               = $Credentials
                }
            }

            SqlAG AddSQLAG1 {
                Ensure               = 'Present'
                Name                 = $Node.AvailabilityGroupName
                InstanceName         = $Node.InstanceName
                ServerName           = $Node.NodeName
                DependsOn = '[SqlAlwaysOnService]EnableHADR', '[SqlServerEndpoint]HADREndpoint', '[SqlServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential = $SQLCredentials
            }

            if ($AGListener1PrivateIP3) {
                SqlAGListener AGListener1 {
                    Ensure               = 'Present'
                    ServerName           = $Node.NodeName
                    InstanceName         = $Node.InstanceName
                    AvailabilityGroup    = $Node.AvailabilityGroupName
                    Name                 = $Node.AvailabilityGroupName
                    IpAddress            = $IPADDR,$IPADDR2,$IPADDR3
                    Port                 = 5301
                    DependsOn            = '[SqlAG]AddSQLAG1'
                    PsDscRunAsCredential = $SQLCredentials
                }
            } else {
                SqlAGListener AGListener1 {
                    Ensure               = 'Present'
                    ServerName           = $Node.NodeName
                    InstanceName         = $Node.InstanceName
                    AvailabilityGroup    = $Node.AvailabilityGroupName
                    Name                 = $Node.AvailabilityGroupName
                    IpAddress            = $IPADDR,$IPADDR2
                    Port                 = 5301
                    DependsOn            = '[SqlAG]AddSQLAG1'
                    PsDscRunAsCredential = $SQLCredentials
                }
            }
        }

        if ( $Node.Role -eq 'SecondaryReplica' -Or $Node.Role -eq 'TertiaryReplica') {
            SqlAGReplica AddReplica {
                Ensure                     = 'Present'
                Name                       = $Node.NodeName
                AvailabilityGroupName      = $Node.AvailabilityGroupName
                ServerName                 = $Node.NodeName
                InstanceName               = $Node.InstanceName
                PrimaryReplicaServerName   = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).NodeName
                PrimaryReplicaInstanceName = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).InstanceName
                DependsOn                  = '[SqlAlwaysOnService]EnableHADR' 
                ProcessOnlyOnActiveNode    = $Node.ProcessOnlyOnActiveNode
                PsDscRunAsCredential       = $SQLCredentials
            }
        }
    }
}

try {
    Start-Transcript -Path C:\cfn\log\Create-AG.ps1.txt -Append
    $ErrorActionPreference = "Stop"
    
    $SQLCredentials = (New-Object System.Management.Automation.PSCredential($SQLServiceAccount,(ConvertTo-SecureString $SQLServiceAccountPassword -AsPlainText -Force)))
    $Credentials = (New-Object System.Management.Automation.PSCredential($DomainAdminUser,(ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force)))
    
    $DN = Get-Domain
    $IdentityReference = $DomainNetBIOSName + "\WSFCluster1$"
    $OUPath = 'OU=Computers,OU=' + $DomainNetBIOSName + "," + $DN

    $IPADDR = 'IP/CIDR' -replace 'IP',$AGListener1PrivateIP1 -replace 'CIDR',(Convert-CidrtoSubnetMask -SubnetMaskCidr (Get-CIDR -Target $WSFCNode1NetBIOSName))
    $IPADDR2 = 'IP/CIDR' -replace 'IP',$AGListener1PrivateIP2 -replace 'CIDR',(Convert-CidrtoSubnetMask -SubnetMaskCidr (Get-CIDR -Target $WSFCNode2NetBIOSName))
    $WSFCNode1Session = New-CimSession -Credential $Credentials -ComputerName $WSFCNode1NetBIOSName -Verbose
    $WSFCNode2Session = New-CimSession -Credential $Credentials -ComputerName $WSFCNode2NetBIOSName -Verbose
    
    if ($AGListener1PrivateIP3) {
        $IPADDR3 = 'IP/CIDR' -replace 'IP',$AGListener1PrivateIP3 -replace 'CIDR',(Convert-CidrtoSubnetMask -SubnetMaskCidr (Get-CIDR -Target $WSFCNode3NetBIOSName))  
    }
    
    AddAG -OutputPath 'C:\cfn\scripts\AddAG' -Credentials $Credentials -SQLCredentials $SQLCredentials -ConfigurationData $ConfigurationData

    Start-DscConfiguration -Path 'C:\cfn\scripts\AddAG' -CimSession $WSFCNode1Session -Wait -Verbose -Force
    Start-DscConfiguration -Path 'C:\cfn\scripts\AddAG' -CimSession $WSFCNode2Session -Wait -Verbose -Force

    if ($WSFCNode3NetBIOSName){
        $WSFCNode3Session = New-CimSession -Credential $Credentials -ComputerName $WSFCNode3NetBIOSName -Verbose
        Start-DscConfiguration -Path 'C:\cfn\scripts\AddAG' -CimSession $WSFCNode3Session -Wait -Verbose -Force
    }
    
}
catch {
    $_ | Write-AWSQuickStartException
}