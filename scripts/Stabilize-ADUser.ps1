[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [int]$TimeoutMinutes=30,

    [Parameter(Mandatory=$false)]
    [int]$IntervalMinutes=1,

    [Parameter(Mandatory=$true)]
    [string]$UserName
)

$elapsedMinutes = 0.0
$startTime = Get-Date
$stabilized = $false

While (($elapsedMinutes -lt $TimeoutMinutes)) {
    if (Get-ADUser -Filter {sAMAccountName -eq $Username}){
        $stabilized = $true
        break
    }
    Start-Sleep -Seconds $($IntervalMinutes * 60)
    $elapsedMinutes = ($(Get-Date) - $startTime).TotalMinutes
}

if ($stabilized -eq $false) {
    Throw "Item did not propgate within the timeout of $Timeout minutes"
}
