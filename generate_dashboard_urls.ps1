#!/bin/pwsh
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force

function Generate-DashboardUrls {
    [CmdletBinding()]
    param (
        [string]$ComposeProjectName,
        [string]$DeviceName,
        [string]$EnvFile = ".env"
    )

    # Validate parameters
    if (-not $ComposeProjectName -or -not $DeviceName) {
        Write-Error "Error: COMPOSE_PROJECT_NAME and DEVICE_NAME must be provided."
        return 1
    }

    $EnvFilePath = Join-Path $PWD $EnvFile

    # If parameters are not provided, try to read from .env file
    if (-not $ComposeProjectName -or -not $DeviceName) {
        if (Test-Path $EnvFilePath) {
            Write-Host "Reading COMPOSE_PROJECT_NAME and DEVICE_NAME from $EnvFile..."
            try {
                $EnvContent = Get-Content $EnvFilePath -Raw
                $ComposeProjectName = [Regex]::Match($EnvContent, '(?<=COMPOSE_PROJECT_NAME=)[^\r\n#]+').Value
                $DeviceName = [Regex]::Match($EnvContent, '(?<=DEVICE_NAME=)[^\r\n#]+').Value
            } catch {
                Write-Error "Error occurred while reading $EnvFile: $_"
                return 1
            }
        } else {
            Write-Error "Error: Parameters not provided and $EnvFile not found."
            return 1
        }
    }

    $DashboardFile = "dashboards_URLs_${ComposeProjectName}-${DeviceName}.txt"

    try {
        "------ Dashboards ${ComposeProjectName}-${DeviceName} ------" | Out-File $DashboardFile -Encoding utf8
        $DockerOutput = docker ps --format "{{.Ports}} {{.Names}}"
        foreach ($Line in $DockerOutput) {
            if ($Line -match '0.0.0.0:(\d+)->\d+/tcp\s+(.*)') {
                $Port = $matches[1]
                $Name = $matches[2]
                "If enabled you can visit the $Name web dashboard on http://localhost:$Port" | Out-File $DashboardFile -Append -Encoding utf8
            }
        }
        Write-Host "Dashboard URLs have been written to $DashboardFile"
    } catch {
        Write-Error "Error occurred while generating dashboard URLs: $_"
        return 1
    }
}

# Call the function with arguments or read from .env
Generate-DashboardUrls -ComposeProjectName $args[0] -DeviceName $args[1]
