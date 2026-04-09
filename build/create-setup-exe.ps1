param(
  [string]$Workspace = $env:GITHUB_WORKSPACE
)

$outExe = "$Workspace\cloudbox-setup.exe"

$sed = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=$outExe
FriendlyName=CloudBox Setup
AppLaunched=cmd /c setup-wsl-al2023.bat
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
FILE0="setup-wsl-al2023.bat"
[SourceFiles]
SourceFiles0=$Workspace
[SourceFiles0]
%FILE0%=
"@

$sed | Out-File "$Workspace\cloudbox.sed" -Encoding ascii

& "$env:SystemRoot\System32\iexpress.exe" /N /Q "$Workspace\cloudbox.sed"

if (-not (Test-Path $outExe)) {
  throw "iexpress did not produce $outExe — check the SED file."
}
Write-Host "EXE built: $outExe"
