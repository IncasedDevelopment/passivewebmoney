Write-Output "First, ensure that you have run the runme.ps1 script and registered to the various apps using the provided links."
Read-Host -prompt "If you have completed these actions, press Enter to continue."

Write-Output "To configure this app, we need to start an interactive container in a new terminal. Ensure Docker is installed."
Write-Output "Then, when prompted, enter your Bitping email and password. Close the terminal afterward."

Read-Host -prompt "When ready to start, press Enter to continue."

docker run --rm -it -v ${PWD}/.data/.bitping/:/root/.bitping bitping/bitping-node:latest ;

if ($LASTEXITCODE -eq 0) {
    Write-Output "Bitping configuration completed."
} else {
    Write-Output "Error occurred during Bitping configuration."
}

Start-Sleep -Seconds 3
