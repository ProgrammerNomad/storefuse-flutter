# Run StoreFuse on Android emulator from the repo root (avoids D: shortcut / Gradle path issues).
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

flutter run `
  --dart-define=BRIDGE_BASE_URL=http://10.0.2.2 `
  --dart-define=APP_FLAVOR=dev `
  @args
