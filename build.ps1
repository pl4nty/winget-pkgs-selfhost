param(
    [Switch]$Release
)

. $PSScriptRoot\_common.ps1

$ValidationErrors = @()
if(-not $Release) {
    if (-not (Test-Path env:PFX_THUMBPRINT)) { $ValidationErrors += @("PFX_THUMBPRINT envvar not set") }
    if (-not (Test-Path env:PFX_PASSPHRASE)) { $ValidationErrors += @("PFX_PASSPHRASE envvar not set") }
}
if ($ValidationErrors.Count -gt 0) { throw "Validation Failed!`n" + ($ValidationErrors -join "`n") }

$majorVersion = "1"
$buildVersion = "0"

if(-not (Test-Path -Path "version.txt")) {
    $t = [UInt32]((New-TimeSpan -Start (Get-Date -Date "01/01/1970") -End (Get-Date)).TotalSeconds)
    $version = "$majorVersion.$($t -shr 16).$($t -band 0x0000FFFF).$buildVersion"
    $version | Out-File -FilePath "version.txt"
}

$version = (Get-Content "version.txt").Trim()

"Version: $version" | Out-Host

Remove-Item -Recurse -Force -Path .\.tmp\ -ErrorAction SilentlyContinue
New-Item -Path ".tmp" -Force -ItemType Directory | Out-Null
Copy-Item -Recurse -Path .\source -Destination .\.tmp\source

function Set-ManifestAttribute($AttributeName, $Value) {
    ((Get-Content -path .\.tmp\source\AppxManifest.xml -Raw) -replace "  $AttributeName=`".+?`"","  $AttributeName=`"$Value`"") | Set-Content -Encoding Default -Path .\.tmp\source\AppxManifest.xml
}

Set-ManifestAttribute -AttributeName "Version" -Value "$version"
Set-ManifestAttribute -AttributeName "Publisher" -Value "CN=WingetPkgsSelfhost"

.\01-generate-manifests.ps1
Check-LastCommand "generate failed"

python .\02-build-index-db.py
Check-LastCommand "index-db build failed"

.\03-build-index-package.ps1

if($Release) {
    .\04-sign-index-package-release.ps1
} else {
    .\04-sign-index-package-test.ps1
}
