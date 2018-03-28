[CmdletBinding()]
 
$timeoutInSeconds = 600
$elapsedSeconds = 0
$intervalSeconds = 1
$startTime = Get-Date
$running = $false

try {
    $ErrorActionPreference = "Stop"
    Start-Transcript -Path C:\cfn\log\$($MyInvocation.MyCommand.Name).log -Append
    While (($elapsedSeconds -lt $timeoutInSeconds )) {
        try {
            if (Test-Connection -computer www.microsoft.com -count 3 -quiet) {
                echo "Network is now available..."
                break
            } 
            else {
                echo "Waiting for network..."
                Start-Sleep -Seconds $intervalSeconds
                $elapsedSeconds = ($(Get-Date) - $startTime).TotalSeconds
                echo "Elapse Seconds" $elapsedSeconds 
            }          
        }
        catch {
            echo "Got here"
            Start-Sleep -Seconds $intervalSeconds
            $elapsedSeconds = ($(Get-Date) - $startTime).TotalSeconds
            echo "Elapse Seconds" $elapsedSeconds            
        }
        if ($elapsedSeconds -ge $timeoutInSeconds) {
            Throw "The internet is unreachable in $timeoutInSeconds seconds..."
        }
    }
}
catch {
    $_ | Write-AWSQuickStartException
}