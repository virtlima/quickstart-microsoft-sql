[CmdletBinding()]
param(

    [Parameter(Mandatory=$true)]
    [string]$WSFCNode2NetBIOSName

    [Parameter(Mandatory=$true)]
    [string]$WSFCNode1NetBIOSName

    [Parameter(Mandatory=$true)]
    [string]$WSFCNode1PrivateIP2

    [Parameter(Mandatory=$true)]
    [string]$WSFCNode2PrivateIP2

)
try {
    Start-Transcript -Path C:\cfn\log\Configure-WSFC.ps1.txt -Append
    $ErrorActionPreference = "Stop"

    New-Cluster -Name WSFCluster1 -Node $WSFCNode1NetBIOSName, $WSFCNode2NetBIOSName -StaticAddress $WSFCNode1PrivateIP2, $WSFCNode2PrivateIP2
    }
catch {
    $_ | Write-AWSQuickStartException
}
