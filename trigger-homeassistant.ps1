. $PSScriptRoot/utils.ps1

function Get-Token {
    # Load token from a encrypted location, secured with the user session so only the user who created it can read the data

    Begin {
        $scriptLocation = Get-Location
        $CredDirectory = "$scriptLocation\Credentials"
        $CredFile = [System.IO.Path]::Combine($CredDirectory, "Home_Assistant_cred.xml")

        # Create the credentials directory if itt doesn't already exist
        if (-Not(Test-Path $CredDirectory)) {
            New-Item -Path $CredDirectory -ItemType Directory
        }
    }

    Process {
        if (-Not(Test-Path $CredFile)) {
            # Get the token and store it securely
            $CredentialParams = @{
                Message  = "Enter Home Assistant Token:"
                Username = "token"
            }
            $Credential = Get-Credential @CredentialParams

            $Credential | Export-Clixml -Path $CredFile
        }

        $credential = [PSCredential] (Import-Clixml -Path $CredFile)
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        Write-Message "Found a token with length [$($token.Length)]"
        return $token
    }        
}

$localHomeAssistant = "http://homeassistant.local:8123"

<#
    $command options: toggle, turn_on, turn_off
#>
function getEntityState{
    param (
        [string]$entityId = $env:entity,
        [string]$token,
        [string]$homeAssistant = $env:homeAssistant
    )

    if ($token -eq "") {
        Write-Message "Loading token from disk"
        try {
            $token = Get-Token
        } catch {
            Write-Message "Could not load token from disk. Please set the token as environment variable or in the script."
            Write-Message $_
            throw
        }
    }

    if ($homeAssistant -eq "") {
        Write-Warning "Parameter 'homeAssistant' is missing. You can set this as environment value with the url to your home assistant instance."
        # overwrite with hardcode value for now
        $homeAssistant = $localHomeAssistant
    }
    $url = "$homeAssistant/api/states/$entityId"
    Write-Message "We are using this url for the command: [$url]"

    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $token"
    }
    Write-Message "Calling the url"
    Invoke-RestMethod -Uri $url -Headers $headers -Method GET
    Write-Message "Call made successfully"
}

function setState {
    param (
        [boolean]$state,
        [string]$entityId = $env:entity,
        [string]$token,
        [string]$homeAssistant = $env:homeAssistant
    )

    if ($token -eq "") {
        Write-Message "Loading token from disk"
        try {
            $token = Get-Token
        } catch {
            Write-Message "Could not load token from disk. Please set the token as environment variable or in the script."
            Write-Message $_
            throw
        }
    }

    if ($homeAssistant -eq "") {
        Write-Warning "Parameter 'homeAssistant' is missing. You can set this as environment value with the url to your home assistant instance."
        # overwrite with hardcode value for now
        $homeAssistant = $localHomeAssistant
    }
    $url = "$homeAssistant/api/states/$entityId"
    Write-Message "We are using this url for setting the entity state: [$url]"

    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $token"
    }
    Write-Message "Calling the url"
    $stateString = (&{ If ($state) {"on"} Else {"off"} })
    Invoke-RestMethod -Uri $url -Body "{""state"": ""$stateString""}" -Headers $headers -Method POST
    Write-Message "Call made successfully"
}
