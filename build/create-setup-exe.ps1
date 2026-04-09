param(
  [string]$Workspace = $env:GITHUB_WORKSPACE
)

$outExe      = "$Workspace\cloudbox-setup.exe"
$archivePath = "$Workspace\cloudbox-setup.7z"
$sfxCfgPath  = "$Workspace\sfx.cfg"
$sevenZip    = "C:\Program Files\7-Zip\7z.exe"
$sfxModule   = "C:\Program Files\7-Zip\7z.sfx"

if (-not (Test-Path $sevenZip)) { throw "7-Zip not found at $sevenZip" }
if (-not (Test-Path $sfxModule)) { throw "7-Zip SFX module not found at $sfxModule" }

# SFX configuration — tells the extractor what to run after unpacking
$sfxConfig = @'
;!@Install@!UTF-8!
Title="CloudBox Setup"
BeginPrompt="This will set up Amazon Linux 2023 in WSL.\nRun as Administrator."
RunProgram="cmd /c setup-wsl-al2023.bat"
;!@InstallEnd@!
'@
[IO.File]::WriteAllText($sfxCfgPath, $sfxConfig, [Text.Encoding]::UTF8)

# Bundle the batch script into a 7z archive
Push-Location $Workspace
& $sevenZip a $archivePath setup-wsl-al2023.bat
if ($LASTEXITCODE -ne 0) { throw "7-Zip archive creation failed (exit $LASTEXITCODE)." }
Pop-Location

# Combine: SFX module + config + archive = self-extracting EXE
$combined = [IO.File]::ReadAllBytes($sfxModule) +
            [IO.File]::ReadAllBytes($sfxCfgPath) +
            [IO.File]::ReadAllBytes($archivePath)
[IO.File]::WriteAllBytes($outExe, $combined)

if (-not (Test-Path $outExe)) {
  throw "EXE was not created at $outExe."
}
Write-Host "EXE built: $outExe"
