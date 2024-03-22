#Requires -RunAsAdministrator

. $PSScriptRoot/import-env.ps1

# Utils provides Write-Host to prepends the log message with a date
Write-Host "Current PSScriptRoot [$PSScriptRoot]"
. $PSScriptRoot/utils.ps1
$location = Get-Location

# Provide handle yourself, by downloading it from: https://learn.microsoft.com/en-us/sysinternals/downloads/handle
$handleExe = "$location\Handle\handle64.exe"

# Verify that the device is connected to the pre-defined wifi network
function CheckNetworkName {
    $connectedNetwork = (Get-NetConnectionProfile).Name
    $predefinedNetworkName = $env:network_name

    return ($connectedNetwork -like "*$predefinedNetworkName*")
}

# Main script
if (-Not (CheckNetworkName)) {
    Write-Message "Device is connected not to the predefined network."
    exit
}


# Function to check whether a specified camera device is in use
function Check-Device {
    param(
        [object] $device
    )

    # load Physical Device Object Name
    $property = Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName "DEVPKEY_Device_PDOName"

    if ($property.Data.Length -eq 0) {
        Write-Message "No PDON found for [$($device.FriendlyName)] so skipping it"
        return
    }

    Write-Message "Checking handles in use for [$($device.FriendlyName)] and PDON [$($property.Data)]"
    $handles = $(& $handleExe -NoBanner -a "$($property.Data)")

    if ($handles -gt 0) {
        # Check if any handles for this device are found
        if ($handles -is [string] -and $handles.ToLower().StartsWith("no matching handles found")){
            Write-Message "  - No handles found for [$($device.FriendlyName)]"
        }
        else {
            # Print all processes using the camera to the standard out
            Write-Message "  - Found [$($handles.Length)] handles on $($device.FriendlyName)"
            $processes = @()
            foreach ($handle in $handles) {
                # remove all spaces
                $nospaceshandle = $handle.Replace(" ", "")
                if ($nospaceshandle.Length -gt 0) {
                    $splitted = $handle.Split(" ")
                    $process = $splitted[0]
                        if (!($processes.Contains($process))) {
                            $processes += $process
                        }
                    }
            }

            # Print the result of the handle check and return true if handles were found
            if ($processes.Length -eq 0) {
                Write-Message " -  No handles found for [$($device.FriendlyName)]"
            }
            else {
                foreach ($process in $processes) {
                    Write-Message "  - Found process [$($process)] that has a handle on [$($device.FriendlyName)]"
                    
                    Write-Host "$(Get-Date -Format "HH:mm:ss")    " $process -ForegroundColor Green
                    return $true
                }
            }
        }
    }
    return $false
}

# Find every camera device on the system and check whether it is in use
function Get-CameraActive {
    
    $deviceFilter = $env:webcam_filter

    Write-Message "Searching for camera devices..."
    $devices = Get-PnpDevice -Class Camera
    Write-Message "Found [$($devices.Count)] potential camera devices before wildcard filter"
    foreach ($device in $devices) {
        # If a filter for the name is specified, filter on it
        if ($device.FriendlyName -notlike "*$deviceFilter*") {
            continue
        }

        $result = Check-Device $device
        if ($result) {
            Write-Message "Found active camera device"
            return $true
        }
    }
    return $false
}

function LoopWithAction {
    while ($true) {
        $start = Get-Date

        $logonui = Get-Process logonui -ErrorAction SilentlyContinue
        if ($null -ne $logonui) {
            # if logonui is running, the user is not logged in at all, so if the lights are already off, we can stop the execution
            Write-Message "Found logonui process"
            $state = getEntityState -entityId $entityId
            Write-Message "Current entity state is [$($state.state)]"
            if ($state.state -ne "on") {
                Write-Message "The lights are off already and the user is not authenticated, skipping all checks"                
            }
        }

        $active = Get-CameraActive
        Run-Action $active

        # don't run again unless 30 seconds have passed
        $end = Get-Date
        $duration = $end - $start
        $sleep = $env:sleep
        $sleepTime = $sleep-$duration.TotalSeconds

        if ($duration.TotalSeconds -lt $sleep) {
            Write-Message "Sleeping for $(($sleepTime).ToString('#')) seconds"
            Start-Sleep ($sleepTime)
        }
    }
}

function Run-Action {
    param(
        [bool] $active = $false
    )
    Write-Message "Running action to make the state [$active]"

    . $PSScriptRoot/trigger-homeassistant.ps1
    
    $state = getEntityState    
    Write-Message "Current entity state is [$($state.state)]"

    if ($active) {
        if ($state.state -eq "on") {
            Write-Message "Already active, no need to do anything"
        } 
        else {            
            Write-Message "Turning on"
            setState -state $True
        }
    }
    else {
        if ($state.state -eq "off") {
            Write-Message "Already off, no need to do anything"
        } 
        else {            
            Write-Message "Turning off"
            setState -state $False
        }
    }
}

LoopWithAction