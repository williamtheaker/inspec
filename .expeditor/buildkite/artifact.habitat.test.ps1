#!/usr/bin/env powershell

#Requires -Version 5
# https://stackoverflow.com/questions/9948517
# TODO: Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction']='Stop'
$ErrorActionPreference = 'Stop'
$env:HAB_ORIGIN = 'ci'
$env:CHEF_LICENSE = 'accept-no-persist'
$env:HAB_LICENSE = 'accept-no-persist'
$Plan = 'inspec'

Write-Host "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

Write-Host "--- Installing the version of Habitat required"
try {
  hab --version
}
catch {
  Set-ExecutionPolicy Bypass -Scope Process -Force
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'))
}
finally {
  Write-Host ":habicat: I think I have the version I need to build."
}


Write-Host "--- Generating fake origin key"
hab origin key generate $env:HAB_ORIGIN

# Find the key file
$HAB_CI_KEY = Get-ChildItem -Path C:\hab\cache\keys\$env:HAB_ORIGIN*.pub | Select-Object -ExpandProperty FullName

# Export the HAB_CI_KEY environment variable
$Env:HAB_CI_KEY = $HAB_CI_KEY

if (Test-Path -Path $HAB_CI_KEY) {
    # Import the key if it exists
    $keyContents = Get-Content -Path $HAB_CI_KEY
    $keyContents | ForEach-Object { hab origin key import - }  # Use '-' to accept input from the pipeline
}
else {
    Write-Host "$HAB_CI_KEY not found"
    Get-ChildItem -Path $env:USERPROFILE\.hab\cache\keys
    Get-ChildItem -Path $project_root\hab\cache\keys
    Get-ChildItem -Path C:\hab
    Exit 1
}

Write-Host "--- Building $Plan"
$project_root = "$(git rev-parse --show-toplevel)"
Set-Location $project_root

$env:DO_CHECK = $true
hab pkg build .

if ($LASTEXITCODE -ne 0) {
  Write-Host "Package build failed."
}

try {
  . $project_root/results/last_build.ps1
} catch {
  Write-Host "Error running last_build.ps1: $_"
}

Write-Host "--- Installing $pkg_ident/$pkg_artifact"
hab pkg install -b $project_root/results/$pkg_artifact

Write-Host "--- Downloading Ruby + DevKit"
aws s3 cp s3://core-buildkite-cache-chef-prod/rubyinstaller-devkit-2.6.6-1-x64.exe c:/rubyinstaller-devkit-2.6.6-1-x64.exe

Write-Host "--- Installing Ruby + DevKit"
Start-Process c:\rubyinstaller-devkit-2.6.6-1-x64.exe -ArgumentList '/verysilent /dir=C:\\ruby26' -Wait

Write-Host "--- Cleaning up installation"
Remove-Item c:\rubyinstaller-devkit-2.6.6-1-x64.exe -Force

$Env:Path += ";C:\ruby26\bin;C:\hab\bin"

Write-Host "+++ Testing $Plan"

Push-Location $project_root/test/artifact
rake

# Check the test result and handle any errors
if ($LASTEXITCODE -ne 0) {
  Write-Host "Tests failed. Exit code: $LASTEXITCODE"
}

Write-Host "--- Script completed successfully."
