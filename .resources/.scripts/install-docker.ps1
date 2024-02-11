Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force

# Check if the script is run as administrator, if not, relaunch it as an elevated process
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

$RESOURCES_DIR = (Get-Item $PWD).Parent.FullName
$SCRIPTS_DIR = Join-Path -Path $RESOURCES_DIR -ChildPath ".scripts"
$FILES_DIR = Join-Path -Path $RESOURCES_DIR -ChildPath ".files"

function InstallDocker {
    Write-Output "Downloading Docker setup files..."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe" -OutFile "DockerInstaller.exe" -UseBasicParsing
    $ProgressPreference = 'Continue'
    Write-Output "Download completed."

    Write-Output "Installing Docker..."
    Start-Process .\DockerInstaller.exe -Wait -NoNewWindow -ArgumentList "install --accept-license --quiet"
    Copy-Item "$FILES_DIR\docker-default-settings.json" -Destination "$env:AppData\Docker\settings.json"
    Write-Output "Docker installed successfully."
    Read-Host "Please reboot the system to continue. After reboot, rerun the script and proceed with the next steps (e.g., .env setup and start stack)."
    Restart-Computer -Confirm
}

Write-Output "WARNING: You are using an old version of the Money4Band project. Download the latest version from https://github.com/IncasedDevelopment/passivewebmoney."
Write-Output "This script is now considered deprecated and is provided only for backward compatibility."

$wsl = Get-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online

if ($wsl.State -eq "Enabled") {
    Write-Output "WSL is enabled."
    if ([Environment]::Is64BitOperatingSystem) {
        Write-Output "System is x64. Updating Linux kernel..."
        if (-not (Test-Path wsl_update_x64.msi)) {
            Write-Output "Downloading Linux kernel update package..."
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -OutFile wsl_update_x64.msi "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
            $ProgressPreference = 'Continue'
        }
        Write-Output "Installing Linux kernel update package..."
        Start-Process msiexec.exe -Wait -ArgumentList "/I wsl_update_x64.msi /quiet"
        Write-Output "Linux kernel update package installed."
    }

    Write-Output "Setting WSL to version 2..."
    wsl --set-default-version 2

    if (Test-Path 'C:\Program Files\Docker\Docker\Docker Desktop.exe' -PathType Leaf) {
        $response = Read-Host -Prompt 'Docker is already installed. Do you want to reinstall/repair it? (Y/N)'
        if ($response -eq 'Y' -or $response -eq 'y' -or $response -eq 'Yes' -or $response -eq 'yes') {
            InstallDocker
        } else {
            Write-Output "Docker installation/repair canceled."
            Write-Output "You should be able to proceed with the next steps if Docker is correctly installed."
        }
    } else {
        Write-Output "Docker is not installed. Starting installation..."
        InstallDocker
    }
} else {
    Write-Output "WSL is disabled."
    Write-Output "Enabling WSL2 feature..."
    & cmd /c 'dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart'
    & cmd /c 'dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart'
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    Start-Sleep 30
    Write-Output "WSL is enabled. Reboot the system and rerun the script to continue Docker installation."
}
