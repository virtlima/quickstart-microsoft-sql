try {
    Start-Transcript -Path C:\AWSQuickstart\log\FormatVolumes.ps1.txt -Append

    Format-Volume -DriveLetter D
    Format-Volume -DriveLetter E
    Format-Volume -DriveLetter F
}
catch {
    $_ | Write-AWSQuickStartException
}