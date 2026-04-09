param(
  [string]$Workspace = $env:GITHUB_WORKSPACE
)

$outExe     = "$Workspace\cloudbox-setup.exe"
$launcher   = "$Workspace\build\_launcher.ps1"
$batSource  = "$Workspace\setup-wsl-al2023.bat"

# Install ps2exe from PSGallery if not already present
if (-not (Get-Command ps2exe -ErrorAction SilentlyContinue)) {
  Install-Module -Name ps2exe -Force -Scope CurrentUser -Repository PSGallery
}

# Encode the bat file as Base64 so it can be embedded as a string literal
$batBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($batSource))

# Generate a self-contained launcher script that decodes and runs the bat
$launcherContent = @"
`$batBytes = [Convert]::FromBase64String('$batBase64')
`$tempBat  = [IO.Path]::Combine(`$env:TEMP, 'cloudbox-setup.bat')
[IO.File]::WriteAllBytes(`$tempBat, `$batBytes)
try {
    `$proc = Start-Process cmd.exe -ArgumentList "/c `"`$tempBat`"" -Wait -PassThru
    exit `$proc.ExitCode
} finally {
    Remove-Item `$tempBat -ErrorAction SilentlyContinue
}
"@

[IO.File]::WriteAllText($launcher, $launcherContent, [Text.Encoding]::UTF8)

# Compile to a standalone EXE — requireAdmin triggers UAC on launch
ps2exe `
  -InputFile  $launcher `
  -OutputFile $outExe `
  -RequireAdmin `
  -NoConsole `
  -Title       'CloudBox Setup' `
  -Description 'Amazon Linux 2023 WSL Setup' `
  -Company     'CloudBox'

if (-not (Test-Path $outExe)) {
  throw "EXE was not created at $outExe."
}
Write-Host "EXE built: $outExe"
