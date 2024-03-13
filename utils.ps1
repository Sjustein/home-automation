function Write-Message(
    [string] $message
)
{
    Write-Host $(Get-Date -Format "HH:mm:ss") $message
}